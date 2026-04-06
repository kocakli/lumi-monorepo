import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { defineSecret } from "firebase-functions/params";
import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { GoogleGenAI, HarmCategory, HarmBlockThreshold } from "@google/genai";

// ─── Init ────────────────────────────────────────────────────────────────────
initializeApp();
const db = getFirestore();
const geminiApiKey = defineSecret("GEMINI_API_KEY");

const RATE_LIMIT_PER_HOUR = 10;
const MAX_STRIKES = 3;
const MAX_BATCH_SIZE = 20;
const DEFAULT_MODEL = "gemini-2.0-flash-lite";

// ═══════════════════════════════════════════════════════════════════════════════
// PRE-FILTERS — pure TypeScript, zero AI cost
// ═══════════════════════════════════════════════════════════════════════════════

// ─── Text Normalization ─────────────────────────────────────────────────────

function normalizeText(text: string): string {
  let t = text.toLowerCase();
  // Turkish dotless ı → i (not handled by NFD)
  t = t.replace(/\u0131/g, "i");
  // NFD decompose + strip combining marks (ö→o, ü→u, ş→s, ç→c, ğ→g, é→e, …)
  t = t.normalize("NFD").replace(/[\u0300-\u036f]/g, "");
  // Fullwidth digits ０-９ → 0-9
  t = t.replace(/[\uFF10-\uFF19]/g, (c) =>
    String.fromCharCode(c.charCodeAt(0) - 0xff10 + 48)
  );
  // Arabic-Indic digits ٠-٩ → 0-9
  t = t.replace(/[\u0660-\u0669]/g, (c) =>
    String.fromCharCode(c.charCodeAt(0) - 0x0660 + 48)
  );
  // Eastern Arabic-Indic digits ۰-۹ → 0-9
  t = t.replace(/[\u06F0-\u06F9]/g, (c) =>
    String.fromCharCode(c.charCodeAt(0) - 0x06f0 + 48)
  );
  // Leet-speak substitutions
  t = t
    .replace(/@/g, "a")
    .replace(/\$/g, "s")
    .replace(/3/g, "e")
    .replace(/1/g, "i")
    .replace(/0/g, "o")
    .replace(/5/g, "s")
    .replace(/7/g, "t")
    .replace(/!/g, "i")
    .replace(/4/g, "a");
  // Collapse 3+ repeated chars → 2 (fuuuck → fuuck)
  t = t.replace(/(.)\1{2,}/g, "$1$1");
  return t;
}

// ─── Profanity Filter ───────────────────────────────────────────────────────

const PROFANITY_LIST: readonly string[] = [
  // English
  "fuck", "fucker", "fucking", "fucked", "fucks", "fuk", "fck", "phuck",
  "shit", "shits", "shitty", "bullshit",
  "bitch", "bitches",
  "asshole", "arsehole",
  "dickhead",
  "cunt", "cunts",
  "nigger", "nigga", "niggers",
  "faggot", "fag",
  "whore", "slut",
  "retard", "retarded",
  "bastard",
  "cocksucker",
  "motherfucker", "motherf",
  "stfu", "gtfo", "kys",
  "piss", "pissed",
  "wanker", "twat",
  // Turkish
  "amk", "aq",
  "sik", "sikmek", "sikeyim", "sikerim", "siktir", "siktirgit",
  "orospu", "orospucocugu", "orospucocu",
  "yarak", "yarrak", "yarraq",
  "got", "gotunu", "gotveren",
  "pic", "piclik",
  "kahpe",
  "ibne", "ibnelik",
  "pezevenk",
  "gavat",
  "dalyarak", "dalyarrak",
  "hassiktir",
  "amina", "aminakoyim", "aminakoyayim",
  "tassak",
  "dangalak",
  "gerizekali",
  "haysiyetsiz",
  "oc", "mk",
];

// Critical words that get obfuscation-pattern matching (f.u.c.k, f u c k, etc.)
const CRITICAL_PROFANITY: readonly string[] = [
  "fuck", "shit", "cunt", "nigger", "bitch", "dick", "cock", "pussy",
  "whore", "slut", "sik", "orospu", "yarak", "amina", "kahpe", "ibne",
];

// Precompiled word-boundary patterns
const PROFANITY_WORD_PATTERNS = PROFANITY_LIST.map(
  (w) => new RegExp(`\\b${w}\\b`)
);

// Precompiled obfuscation patterns: f[^a-z]*u[^a-z]*c[^a-z]*k
const OBFUSCATION_PATTERNS = CRITICAL_PROFANITY.map((w) => {
  const pattern = w.split("").join("[^a-z]*");
  return new RegExp(pattern);
});

function checkProfanity(text: string): { blocked: boolean; reason: string } {
  const normalized = normalizeText(text);
  // Also strip dots/dashes/underscores for f.u.c.k style obfuscation
  const deobfuscated = normalized.replace(/[.\-_]/g, "");

  // Word-boundary check on both normalized and deobfuscated text
  for (const pattern of PROFANITY_WORD_PATTERNS) {
    if (pattern.test(normalized) || pattern.test(deobfuscated)) {
      return { blocked: true, reason: "profanity" };
    }
  }

  // Obfuscation pattern check (catches f u c k, f*u*c*k, f.u.c.k, etc.)
  for (const pattern of OBFUSCATION_PATTERNS) {
    if (pattern.test(normalized)) {
      return { blocked: true, reason: "profanity" };
    }
  }

  return { blocked: false, reason: "" };
}

// ─── Phone Number Filter ────────────────────────────────────────────────────

function checkPhoneNumber(text: string): { blocked: boolean; reason: string } {
  // Normalize unicode digits to ASCII only (don't apply leet-speak — keep digits)
  let t = text;
  t = t.replace(/[\uFF10-\uFF19]/g, (c) =>
    String.fromCharCode(c.charCodeAt(0) - 0xff10 + 48)
  );
  t = t.replace(/[\u0660-\u0669]/g, (c) =>
    String.fromCharCode(c.charCodeAt(0) - 0x0660 + 48)
  );
  t = t.replace(/[\u06F0-\u06F9]/g, (c) =>
    String.fromCharCode(c.charCodeAt(0) - 0x06f0 + 48)
  );

  // Clustered digit detection: 7+ digits with any non-letter non-digit separators
  // Catches: 05467891234, 0.5.4.6.7.8.9, 0-546-789-12-34, +90 546 789 1234,
  //          5+4+6+7+8+9+1, (546) 789 1234, 5*4*6*7*8*9*1
  if (/(\d[^a-zA-Z\d]*){7,}/.test(t)) {
    return { blocked: true, reason: "phone_number" };
  }

  return { blocked: false, reason: "" };
}

// ─── Social Media / Contact Info Filter ─────────────────────────────────────

const PLATFORM_NAMES = /\b(instagram|insta|tiktok|twitter|snapchat|telegram|whatsapp|discord|onlyfans|facebook|linkedin|youtube|signal|wechat|viber|skype)\b/;
const PLATFORM_ABBREVIATIONS = /\b(ig|sc|tt|tw|fb|dc)\s*[:=]/;
const CONTACT_PHRASES = /\b(add me|dm me|follow me|hit me up|hmu|my ig|my insta|my snap|mesaj at|takip et|numaram|beni ekle|bana yaz|takiplesme|takiples)\b/;
const URL_PATTERN = /https?:\/\/|www\./i;
const DOMAIN_PATTERN = /\b\w+\.(com|net|org|io|me|co|app|xyz|dev|link|bio|ly)\b/i;
const EMAIL_PATTERN = /\b[\w.+-]+@[\w-]+\.[\w.]+\b/;
const HANDLE_PATTERN = /@[a-z0-9_.]{3,30}\b/;

function checkContactInfo(text: string): { blocked: boolean; reason: string } {
  const lower = text.toLowerCase();
  const normalized = normalizeText(text);

  // URL check (on original lowercase — before leet-speak would mangle URLs)
  if (URL_PATTERN.test(lower) || DOMAIN_PATTERN.test(lower)) {
    return { blocked: true, reason: "contact_info" };
  }

  // Email check
  if (EMAIL_PATTERN.test(lower)) {
    return { blocked: true, reason: "contact_info" };
  }

  // Platform names (on normalized text — catches 1nstagram → instagram via leet-speak)
  if (PLATFORM_NAMES.test(normalized)) {
    return { blocked: true, reason: "contact_info" };
  }

  // Platform abbreviations with separator (ig:, sc=, etc.)
  if (PLATFORM_ABBREVIATIONS.test(lower)) {
    return { blocked: true, reason: "contact_info" };
  }

  // Handle pattern (@username with 3+ chars)
  if (HANDLE_PATTERN.test(lower)) {
    return { blocked: true, reason: "contact_info" };
  }

  // Contact-sharing phrases (on normalized text)
  if (CONTACT_PHRASES.test(normalized)) {
    return { blocked: true, reason: "contact_info" };
  }

  return { blocked: false, reason: "" };
}

// ─── Spam / Advertisement Filter ────────────────────────────────────────────

const PROMO_KEYWORDS = /\b(buy now|discount|free money|crypto|earn money|click here|limited offer|act now|subscribe|bitcoin|forex|nft|casino|lottery|prize|winner|congratulations|claim your|make money|passive income|kazanc|firsati kacirma|hemen al|bedava|ucretsiz para|kripto)\b/;

function checkSpam(text: string): { blocked: boolean; reason: string } {
  const normalized = normalizeText(text);

  // Promotional keywords
  if (PROMO_KEYWORDS.test(normalized)) {
    return { blocked: true, reason: "spam" };
  }

  // Percentage off patterns (50% off, %30 indirim)
  if (/\d+\s*%\s*(off|indirim)/i.test(text)) {
    return { blocked: true, reason: "spam" };
  }

  // Excessive caps (>50% uppercase in messages >10 chars)
  if (text.length > 10) {
    const letters = text.replace(/[^a-zA-Z]/g, "");
    const upper = text.replace(/[^A-Z]/g, "");
    if (letters.length > 0 && upper.length / letters.length > 0.5) {
      return { blocked: true, reason: "spam" };
    }
  }

  // Excessive character repetition (same char 5+ times in a row)
  if (/(.)\1{4,}/.test(text)) {
    return { blocked: true, reason: "spam" };
  }

  return { blocked: false, reason: "" };
}

// ─── Pre-Filter Orchestrator ────────────────────────────────────────────────

function runPreFilters(text: string): { blocked: boolean; reason: string } {
  const checks = [checkProfanity, checkPhoneNumber, checkContactInfo, checkSpam];
  for (const check of checks) {
    const result = check(text);
    if (result.blocked) return result;
  }
  return { blocked: false, reason: "" };
}

// ═══════════════════════════════════════════════════════════════════════════════
// GEMINI AI MODERATION
// ═══════════════════════════════════════════════════════════════════════════════

// Model name from Firestore config — changeable without redeploy
// Set in Firebase Console → Firestore → config/moderation → { model: "gemini-2.0-flash-lite" }
async function getModerationModel(): Promise<string> {
  try {
    const doc = await db.collection("config").doc("moderation").get();
    return (doc.data()?.model as string) || DEFAULT_MODEL;
  } catch {
    return DEFAULT_MODEL;
  }
}

const VALID_MOODS = ["Playful", "Peaceful", "Motivating", "Romantic"] as const;
type Mood = (typeof VALID_MOODS)[number];

const MODERATION_PROMPT =
  "You moderate messages for Lumi, a positivity app. Messages may be in ANY language. " +
  "Detect the language and evaluate accordingly.\n\n" +
  "APPROVE: kind, uplifting, supportive, positive messages in any language.\n" +
  "REJECT: negative, hateful, sexual, violent, manipulative, spam, self-harm, " +
  "bullying, threats, or toxic content in any language.\n\n" +
  "For each APPROVED message, also detect the mood. Moods: Playful, Peaceful, Motivating, Romantic.\n" +
  "- Playful: fun, cheerful, lighthearted, humorous\n" +
  "- Peaceful: calm, serene, comforting, gentle, reassuring\n" +
  "- Motivating: inspiring, empowering, encouraging, uplifting\n" +
  "- Romantic: loving, affectionate, tender, heartfelt\n\n" +
  "Reply ONLY in format: 1:A:Peaceful,2:R,3:A:Motivating (A=approve with mood, R=reject). No other text.";

interface ModerationResult {
  verdict: "APPROVE" | "REJECT";
  mood: Mood;
}

function parseGeminiResponse(
  responseText: string,
  messageCount: number
): Map<number, ModerationResult> {
  const results = new Map<number, ModerationResult>();
  const cleaned = responseText.trim().replace(/\s/g, "");
  const entries = cleaned.split(",");

  for (const entry of entries) {
    const parts = entry.split(":");
    const numStr = parts[0];
    const verdictStr = parts[1]?.toUpperCase();
    if (!numStr || !verdictStr) continue;

    const num = parseInt(numStr, 10);
    if (isNaN(num) || num < 1 || num > messageCount) continue;

    if (verdictStr === "A") {
      // Parse mood from third segment (e.g. "1:A:Peaceful")
      const rawMood = parts[2] ?? "";
      const mood = VALID_MOODS.find(
        (m) => m.toLowerCase() === rawMood.toLowerCase()
      ) ?? "Peaceful"; // default to Peaceful if unrecognized
      results.set(num, { verdict: "APPROVE", mood });
    } else if (verdictStr === "R") {
      results.set(num, { verdict: "REJECT", mood: "Peaceful" });
    }
  }

  return results;
}

interface MessageForAI {
  id: string;
  text: string;
}

async function moderateWithGemini(
  apiKey: string,
  modelName: string,
  messages: MessageForAI[]
): Promise<Map<string, ModerationResult>> {
  const results = new Map<string, ModerationResult>();

  // Build numbered list
  const numberedList = messages
    .map((m, i) => `${i + 1}: ${m.text}`)
    .join("\n");

  const ai = new GoogleGenAI({ apiKey });
  const response = await ai.models.generateContent({
    model: modelName,
    contents: numberedList,
    config: {
      systemInstruction: MODERATION_PROMPT,
      temperature: 0,
      maxOutputTokens: 300,
      safetySettings: [
        { category: HarmCategory.HARM_CATEGORY_HARASSMENT, threshold: HarmBlockThreshold.OFF },
        { category: HarmCategory.HARM_CATEGORY_HATE_SPEECH, threshold: HarmBlockThreshold.OFF },
        { category: HarmCategory.HARM_CATEGORY_SEXUALLY_EXPLICIT, threshold: HarmBlockThreshold.OFF },
        { category: HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT, threshold: HarmBlockThreshold.OFF },
      ],
    },
  });

  const text = response.text ?? "";
  const verdicts = parseGeminiResponse(text, messages.length);

  // Map verdicts back to message IDs; default to REJECT for missing verdicts
  for (let i = 0; i < messages.length; i++) {
    const msg = messages[i]!;
    const result = verdicts.get(i + 1);
    results.set(msg.id, result ?? { verdict: "REJECT", mood: "Peaceful" });
  }

  return results;
}

// ═══════════════════════════════════════════════════════════════════════════════
// 1. BATCH MODERATION (every 15 minutes)
// ═══════════════════════════════════════════════════════════════════════════════

export const moderateMessageBatch = onSchedule(
  {
    schedule: "every 15 minutes",
    region: "europe-west1",
    secrets: [geminiApiKey],
    timeoutSeconds: 120,
    memory: "256MiB",
  },
  async () => {
    // ── Step 1: Fetch pending messages ──────────────────────────────────
    const pendingSnap = await db
      .collection("messages")
      .where("status", "==", "pending")
      .orderBy("createdAt", "asc")
      .limit(100)
      .get();

    if (pendingSnap.empty) {
      console.log("No pending messages to moderate");
      return;
    }

    interface PendingMsg {
      id: string;
      text: string;
      senderId: string;
      ref: FirebaseFirestore.DocumentReference;
    }

    const messages: PendingMsg[] = pendingSnap.docs.map((doc) => ({
      id: doc.id,
      text: doc.data().text as string,
      senderId: doc.data().senderId as string,
      ref: doc.ref,
    }));

    console.log(`Processing ${messages.length} pending messages`);

    // ── Step 2: Batch-fetch user docs ──────────────────────────────────
    const uniqueSenderIds = [...new Set(messages.map((m) => m.senderId))];
    const userRefs = uniqueSenderIds.map((uid) =>
      db.collection("users").doc(uid)
    );
    const userSnaps = await db.getAll(...userRefs);
    const userDocs = new Map<string, FirebaseFirestore.DocumentData>();
    for (const snap of userSnaps) {
      if (snap.exists) {
        userDocs.set(snap.id, snap.data()!);
      }
    }

    // ── Step 3: Rate limit counts (non-pending messages in last hour) ──
    const rateLimitBase = new Map<string, number>();
    for (const senderId of uniqueSenderIds) {
      const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);
      const countSnap = await db
        .collection("messages")
        .where("senderId", "==", senderId)
        .where("createdAt", ">=", oneHourAgo)
        .count()
        .get();
      const totalInHour = countSnap.data().count;
      // Subtract pending messages from this batch to get already-processed count
      const pendingFromUser = messages.filter(
        (m) => m.senderId === senderId
      ).length;
      rateLimitBase.set(senderId, Math.max(0, totalInHour - pendingFromUser));
    }

    // ── Step 4: Pipeline — shadowban → rate limit → pre-filters ────────
    const toShadowban: PendingMsg[] = [];
    const toRateLimit: PendingMsg[] = [];
    const toAutoReject: Array<PendingMsg & { reason: string }> = [];
    const forAI: PendingMsg[] = [];

    // Running rate limit count per user (process chronologically)
    const runningCount = new Map<string, number>(rateLimitBase);

    for (const msg of messages) {
      // Shadowban check
      const userData = userDocs.get(msg.senderId);
      if (userData?.isBanned === true) {
        toShadowban.push(msg);
        continue;
      }

      // Rate limit check (per-message, chronological order)
      const currentCount = runningCount.get(msg.senderId) ?? 0;
      if (currentCount >= RATE_LIMIT_PER_HOUR) {
        toRateLimit.push(msg);
        continue;
      }
      runningCount.set(msg.senderId, currentCount + 1);

      // Pre-filters
      const filterResult = runPreFilters(msg.text);
      if (filterResult.blocked) {
        toAutoReject.push({ ...msg, reason: filterResult.reason });
        continue;
      }

      // Passed all pre-filters → send to AI
      forAI.push(msg);
    }

    // ── Step 5: AI moderation in batches ───────────────────────────────
    const toApprove: Array<PendingMsg & { aiMood?: string }> = [];
    const toAIReject: PendingMsg[] = [];
    const toPendingReview: PendingMsg[] = [];

    if (forAI.length > 0) {
      const modelName = await getModerationModel();
      const apiKey = geminiApiKey.value();

      for (let i = 0; i < forAI.length; i += MAX_BATCH_SIZE) {
        const chunk = forAI.slice(i, i + MAX_BATCH_SIZE);
        try {
          const verdicts = await moderateWithGemini(apiKey, modelName, chunk);
          for (const msg of chunk) {
            const result = verdicts.get(msg.id);
            if (result?.verdict === "APPROVE") {
              toApprove.push({ ...msg, aiMood: result.mood });
            } else {
              toAIReject.push(msg);
            }
          }
        } catch (error) {
          console.error("Gemini API error:", error);
          // On API failure → pending_review for manual review
          toPendingReview.push(...chunk);
        }
      }
    }

    // ── Step 6: Batch write all status updates ────────────────────────
    const writeBatch = db.batch();

    for (const msg of toShadowban) {
      writeBatch.update(msg.ref, { status: "shadowbanned" });
    }

    for (const msg of toRateLimit) {
      writeBatch.update(msg.ref, { status: "rate_limited" });
    }

    for (const msg of toAutoReject) {
      writeBatch.update(msg.ref, {
        status: "rejected",
        rejectionReason: msg.reason,
      });
    }

    for (const msg of toApprove) {
      const updates: Record<string, unknown> = {
        status: "approved",
        approvedAt: FieldValue.serverTimestamp(),
      };
      // AI-detected mood overwrites "Random" — keeps user-selected specific moods
      if ("aiMood" in msg && msg.aiMood) {
        updates.mood = msg.aiMood;
      }
      writeBatch.update(msg.ref, updates);
    }

    for (const msg of toAIReject) {
      writeBatch.update(msg.ref, {
        status: "rejected",
        rejectionReason: "ai_moderation",
      });
    }

    for (const msg of toPendingReview) {
      writeBatch.update(msg.ref, { status: "pending_review" });
    }

    await writeBatch.commit();

    // ── Step 7: Update strikes for all rejected messages ──────────────
    const allRejected = [
      ...toAutoReject.map((m) => m.senderId),
      ...toAIReject.map((m) => m.senderId),
    ];

    const strikesByUser = new Map<string, number>();
    for (const senderId of allRejected) {
      strikesByUser.set(senderId, (strikesByUser.get(senderId) ?? 0) + 1);
    }

    for (const [senderId, newStrikes] of strikesByUser) {
      const userData = userDocs.get(senderId);
      const currentStrikes = (userData?.strikes as number | undefined) ?? 0;
      const totalStrikes = currentStrikes + newStrikes;

      const userRef = db.collection("users").doc(senderId);
      const updates: Record<string, unknown> = {
        strikes: FieldValue.increment(newStrikes),
      };

      if (totalStrikes >= MAX_STRIKES) {
        updates.isBanned = true;
        console.log(
          `User auto-banned: ${senderId} (${totalStrikes} strikes)`
        );
      }

      await userRef.set(updates, { merge: true });
    }

    // ── Step 8: Log summary ───────────────────────────────────────────
    console.log(
      `Moderation complete: ${toApprove.length} approved, ` +
        `${toAutoReject.length + toAIReject.length} rejected ` +
        `(${toAutoReject.length} pre-filter, ${toAIReject.length} AI), ` +
        `${toShadowban.length} shadowbanned, ${toRateLimit.length} rate-limited, ` +
        `${toPendingReview.length} pending review`
    );
  }
);

// ═══════════════════════════════════════════════════════════════════════════════
// 2. Get Random Message
// ═══════════════════════════════════════════════════════════════════════════════

export const getRandomMessage = onCall(
  { region: "europe-west1" },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "You must be signed in.");
    }

    const uid = request.auth.uid;
    const mood = request.data?.mood as string | undefined;

    let query = db
      .collection("messages")
      .where("status", "==", "approved") as FirebaseFirestore.Query;

    if (mood && mood !== "Random") {
      query = query.where("mood", "==", mood);
    }

    const snapshot = await query.orderBy("approvedAt", "desc").limit(50).get();

    const candidates = snapshot.docs.filter(
      (doc) => doc.data().senderId !== uid
    );

    if (candidates.length === 0) {
      return {
        success: false,
        message: "No messages in the pool right now. Try again later!",
      };
    }

    const randomDoc =
      candidates[Math.floor(Math.random() * candidates.length)]!;
    const msgData = randomDoc.data();

    return {
      success: true,
      message: {
        id: randomDoc.id,
        text: msgData.text,
        mood: msgData.mood,
      },
    };
  }
);

// ═══════════════════════════════════════════════════════════════════════════════
// 3. Save to Vault
// ═══════════════════════════════════════════════════════════════════════════════

export const saveToVault = onCall(
  { region: "europe-west1" },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "You must be signed in.");
    }

    const uid = request.auth.uid;
    const { messageId, text, mood } = request.data as {
      messageId: string;
      text: string;
      mood: string;
    };

    if (!messageId || !text) {
      throw new HttpsError("invalid-argument", "Message details are missing.");
    }

    await db
      .collection("users")
      .doc(uid)
      .collection("vault")
      .doc(messageId)
      .set({
        text,
        mood: mood ?? "Random",
        savedAt: FieldValue.serverTimestamp(),
      });

    // Notify the original sender that their message was saved
    const messageDoc = await db.collection("messages").doc(messageId).get();
    if (messageDoc.exists) {
      const senderId = messageDoc.data()?.senderId as string | undefined;
      if (senderId && senderId !== uid) {
        await db.collection("notifications").add({
          userId: senderId,
          type: "message_saved",
          messageId,
          createdAt: FieldValue.serverTimestamp(),
          read: false,
        });
      }
    }

    return { success: true };
  }
);

// ═══════════════════════════════════════════════════════════════════════════════
// 4. Connection Code Match
// ═══════════════════════════════════════════════════════════════════════════════

export const checkConnectionCode = onCall(
  { region: "europe-west1" },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "You must be signed in.");
    }

    const friendCode = request.data?.friendCode as string | undefined;
    const myUid = request.auth.uid;

    if (!friendCode) {
      throw new HttpsError("invalid-argument", "Friend code is missing.");
    }

    const usersSnapshot = await db
      .collection("users")
      .where("connectionCode", "==", friendCode)
      .limit(1)
      .get();

    if (usersSnapshot.empty) {
      return { success: false, message: "No user found with this code." };
    }

    const friendDoc = usersSnapshot.docs[0]!;
    const friendUid = friendDoc.id;

    if (friendUid === myUid) {
      return { success: false, message: "You cannot enter your own code." };
    }

    const connectionId = [myUid, friendUid].sort().join("_");

    const existingConnection = await db
      .collection("connections")
      .doc(connectionId)
      .get();

    if (existingConnection.exists) {
      return {
        success: false,
        message: "You are already connected with this person.",
      };
    }

    await db.collection("connections").doc(connectionId).set({
      users: [myUid, friendUid],
      establishedAt: FieldValue.serverTimestamp(),
    });

    return { success: true, message: "Connection established successfully!" };
  }
);

// ═══════════════════════════════════════════════════════════════════════════════
// 5. Report Message
// ═══════════════════════════════════════════════════════════════════════════════

export const reportMessage = onCall(
  { region: "europe-west1" },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "You must be signed in.");
    }

    const { messageId, reason } = request.data as {
      messageId: string;
      reason?: string;
    };

    if (!messageId) {
      throw new HttpsError("invalid-argument", "Message ID is missing.");
    }

    // Fetch message to store sender info and text snapshot
    const messageDoc = await db.collection("messages").doc(messageId).get();
    if (!messageDoc.exists) {
      throw new HttpsError("not-found", "Message not found.");
    }
    const messageData = messageDoc.data()!;

    await db.collection("reports").add({
      messageId,
      reporterId: request.auth.uid,
      reportedUserId: messageData.senderId as string,
      reportedText: messageData.text as string,
      reason: reason ?? "",
      createdAt: FieldValue.serverTimestamp(),
      status: "pending",
      aiVerdict: null,
    });

    // Quarantine the message immediately — hide from feed until AI review
    await db.collection("messages").doc(messageId).update({
      status: "quarantined",
      quarantinedAt: FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      message: "Your report has been received. Thank you.",
    };
  }
);

// ═══════════════════════════════════════════════════════════════════════════════
// 6. Generate Connection Code
// ═══════════════════════════════════════════════════════════════════════════════

export const generateConnectionCode = onCall(
  { region: "europe-west1" },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "You must be signed in.");
    }

    const uid = request.auth.uid;
    const userRef = db.collection("users").doc(uid);
    const userDoc = await userRef.get();

    if (userDoc.exists && userDoc.data()?.connectionCode) {
      return { code: userDoc.data()?.connectionCode as string };
    }

    const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
    let code: string;
    let isUnique = false;

    do {
      const random = Array.from({ length: 4 }, () =>
        chars[Math.floor(Math.random() * chars.length)]
      ).join("");
      code = `LUMI-${random}`;

      const existing = await db
        .collection("users")
        .where("connectionCode", "==", code)
        .limit(1)
        .get();
      isUnique = existing.empty;
    } while (!isUnique);

    await userRef.set(
      {
        connectionCode: code,
        createdAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    return { code };
  }
);

// ═══════════════════════════════════════════════════════════════════════════════
// 7. Submit Support Ticket
// ═══════════════════════════════════════════════════════════════════════════════

export const submitSupportTicket = onCall(
  { region: "europe-west1" },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "You must be signed in.");
    }

    const { issueText } = request.data as { issueText: string };

    if (!issueText || issueText.trim().length === 0) {
      throw new HttpsError("invalid-argument", "Please describe your issue.");
    }

    await db.collection("support_tickets").add({
      userId: request.auth.uid,
      issueText: issueText.trim(),
      createdAt: FieldValue.serverTimestamp(),
      status: "open",
    });

    return {
      success: true,
      message: "Your message has been received. We'll get back to you soon.",
    };
  }
);

// ═══════════════════════════════════════════════════════════════════════════════
// 8. Rate Message (Swipe)
// ═══════════════════════════════════════════════════════════════════════════════

export const rateMessage = onCall(
  { region: "europe-west1" },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "You must be signed in.");
    }

    const uid = request.auth.uid;
    const { messageId, rating } = request.data as {
      messageId: string;
      rating: "positive" | "negative";
    };

    if (!messageId || !rating) {
      throw new HttpsError(
        "invalid-argument",
        "Message ID and rating are required."
      );
    }

    if (rating !== "positive" && rating !== "negative") {
      throw new HttpsError(
        "invalid-argument",
        "Rating must be 'positive' or 'negative'."
      );
    }

    const messageRef = db.collection("messages").doc(messageId);
    const messageDoc = await messageRef.get();

    if (!messageDoc.exists) {
      throw new HttpsError("not-found", "Message not found.");
    }

    if (messageDoc.data()?.senderId === uid) {
      return { success: false, message: "You cannot rate your own message." };
    }

    const existingRating = await db
      .collection("ratings")
      .where("messageId", "==", messageId)
      .where("userId", "==", uid)
      .limit(1)
      .get();

    if (!existingRating.empty) {
      return {
        success: false,
        message: "You have already rated this message.",
      };
    }

    await db.collection("ratings").add({
      messageId,
      userId: uid,
      rating,
      createdAt: FieldValue.serverTimestamp(),
    });

    const scoreChange = rating === "positive" ? 1 : -1;
    await messageRef.update({
      score: FieldValue.increment(scoreChange),
      [`${rating}Count`]: FieldValue.increment(1),
    });

    return { success: true };
  }
);

// ═══════════════════════════════════════════════════════════════════════════════
// 9. Get Message Feed (swipe stack)
// ═══════════════════════════════════════════════════════════════════════════════

export const getMessageFeed = onCall(
  { region: "europe-west1" },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "You must be signed in.");
    }

    const uid = request.auth.uid;
    const mood = request.data?.mood as string | undefined;
    const batchSize = 10;

    const ratedSnap = await db
      .collection("ratings")
      .where("userId", "==", uid)
      .select("messageId")
      .get();

    const ratedIds = new Set(
      ratedSnap.docs.map((doc) => doc.data().messageId as string)
    );

    let query = db
      .collection("messages")
      .where("status", "==", "approved") as FirebaseFirestore.Query;

    if (mood && mood !== "Random") {
      query = query.where("mood", "==", mood);
    }

    const snapshot = await query.limit(batchSize * 3).get();

    const feed = snapshot.docs
      .filter(
        (doc) => doc.data().senderId !== uid && !ratedIds.has(doc.id)
      )
      .slice(0, batchSize)
      .map((doc) => ({
        id: doc.id,
        text: doc.data().text as string,
        mood: doc.data().mood as string,
      }));

    return { success: true, messages: feed };
  }
);

// ═══════════════════════════════════════════════════════════════════════════════
// 10. Process Reports (every 15 min — AI re-scan + auto-shadowban)
// ═══════════════════════════════════════════════════════════════════════════════

const REPORT_MODERATION_PROMPT =
  "A user reported this message in a positivity app. Evaluate strictly. " +
  "REJECT if it contains ANY negativity, hidden insults, passive aggression, " +
  "manipulation, inappropriate content, or anything unsuitable for a positivity app. " +
  "APPROVE only if genuinely kind and positive. Reply ONLY: A or R";

const AUTO_SHADOWBAN_THRESHOLD = 5; // unique reporters needed for auto-ban

async function moderateReportedMessage(
  apiKey: string,
  modelName: string,
  text: string
): Promise<"APPROVE" | "REJECT"> {
  try {
    const ai = new GoogleGenAI({ apiKey });
    const response = await ai.models.generateContent({
      model: modelName,
      contents: text,
      config: {
        systemInstruction: REPORT_MODERATION_PROMPT,
        temperature: 0,
        maxOutputTokens: 10,
        safetySettings: [
          { category: HarmCategory.HARM_CATEGORY_HARASSMENT, threshold: HarmBlockThreshold.OFF },
          { category: HarmCategory.HARM_CATEGORY_HATE_SPEECH, threshold: HarmBlockThreshold.OFF },
          { category: HarmCategory.HARM_CATEGORY_SEXUALLY_EXPLICIT, threshold: HarmBlockThreshold.OFF },
          { category: HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT, threshold: HarmBlockThreshold.OFF },
        ],
      },
    });
    const verdict = (response.text ?? "").trim().toUpperCase();
    return verdict === "A" ? "APPROVE" : "REJECT";
  } catch (error) {
    console.error("Report moderation error:", error);
    return "REJECT"; // fail-safe: reject on error
  }
}

export const processReports = onSchedule(
  {
    schedule: "every 3 hours",
    region: "europe-west1",
    secrets: [geminiApiKey],
    timeoutSeconds: 120,
    memory: "256MiB",
  },
  async () => {
    // Step 1: Fetch pending reports
    const pendingSnap = await db
      .collection("reports")
      .where("status", "==", "pending")
      .orderBy("createdAt", "asc")
      .limit(50)
      .get();

    if (pendingSnap.empty) {
      console.log("No pending reports to process");
      return;
    }

    console.log(`Processing ${pendingSnap.size} pending reports`);

    const apiKey = geminiApiKey.value();
    const modelName = await getModerationModel();
    const reportedUserIds = new Set<string>();

    // Step 2: AI re-scan each reported message
    for (const reportDoc of pendingSnap.docs) {
      const report = reportDoc.data();
      const reportedText = report.reportedText as string;
      const reportedUserId = report.reportedUserId as string;
      const messageId = report.messageId as string;

      reportedUserIds.add(reportedUserId);

      const verdict = await moderateReportedMessage(apiKey, modelName, reportedText);

      // Update report with AI verdict
      await reportDoc.ref.update({
        status: "reviewed",
        aiVerdict: verdict,
        reviewedAt: FieldValue.serverTimestamp(),
      });

      const messageRef = db.collection("messages").doc(messageId);

      if (verdict === "REJECT") {
        // AI confirms report → permanently reject + strike
        await messageRef.update({
          status: "rejected",
          rejectionReason: "reported_and_ai_rejected",
        });

        // Add strike to sender
        const userRef = db.collection("users").doc(reportedUserId);
        const userDoc = await userRef.get();
        const currentStrikes = (userDoc.data()?.strikes as number | undefined) ?? 0;
        const newTotal = currentStrikes + 1;

        const userUpdates: Record<string, unknown> = {
          strikes: FieldValue.increment(1),
        };
        if (newTotal >= MAX_STRIKES) {
          userUpdates.isBanned = true;
          console.log(`User banned via report+AI: ${reportedUserId} (${newTotal} strikes)`);
        }
        await userRef.set(userUpdates, { merge: true });
      } else {
        // AI clears the message → release from quarantine back to approved
        const msgDoc = await messageRef.get();
        if (msgDoc.exists && msgDoc.data()?.status === "quarantined") {
          await messageRef.update({
            status: "approved",
            quarantinedAt: FieldValue.delete(),
          });
          console.log(`Message cleared by AI, released: ${messageId}`);
        }
      }
    }

    // Step 3: Auto-shadowban check (5+ unique reporters for any user)
    for (const userId of reportedUserIds) {
      const allReports = await db
        .collection("reports")
        .where("reportedUserId", "==", userId)
        .get();

      const uniqueReporters = new Set(
        allReports.docs.map((d) => d.data().reporterId as string)
      );

      if (uniqueReporters.size >= AUTO_SHADOWBAN_THRESHOLD) {
        const userRef = db.collection("users").doc(userId);
        const userDoc = await userRef.get();
        if (!userDoc.exists || userDoc.data()?.isBanned !== true) {
          await userRef.set({ isBanned: true }, { merge: true });
          console.log(
            `User auto-shadowbanned: ${userId} (${uniqueReporters.size} unique reporters)`
          );
        }
      }
    }

    console.log(`Report processing complete: ${pendingSnap.size} reports reviewed`);
  }
);

// ═══════════════════════════════════════════════════════════════════════════════
// 11. Scheduled Notifications (every hour)
// ═══════════════════════════════════════════════════════════════════════════════

function getLocalHour(date: Date, timezone: string): number {
  try {
    const formatter = new Intl.DateTimeFormat("en-US", {
      hour: "numeric",
      hour12: false,
      timeZone: timezone,
    });
    return parseInt(formatter.format(date), 10);
  } catch {
    return date.getUTCHours();
  }
}

export const sendScheduledNotifications = onSchedule(
  {
    schedule: "every 1 hours",
    region: "europe-west1",
    timeoutSeconds: 120,
    memory: "256MiB",
  },
  async () => {
    const now = new Date();
    const messaging = getMessaging();

    const usersSnap = await db
      .collection("users")
      .where("notificationPrefs.enabled", "==", true)
      .get();

    if (usersSnap.empty) {
      console.log("No users with notifications enabled");
      return;
    }

    let sentCount = 0;

    for (const userDoc of usersSnap.docs) {
      const userData = userDoc.data();
      const prefs = userData.notificationPrefs as Record<string, unknown> | undefined;
      const fcmToken = userData.fcmToken as string | undefined;
      if (!prefs || !fcmToken) continue;

      const frequency = (prefs.frequency as number) ?? 0;
      if (frequency === 0) continue;

      const periodHours = (prefs.periodHours as number[]) ?? [8];
      const userTZ = (prefs.timezone as string) || "UTC";
      const userLocalHour = getLocalHour(now, userTZ);

      // Only send at one of user's preferred hours
      if (!periodHours.includes(userLocalHour)) continue;

      // Frequency cap: check how many sent today
      const sentToday = (prefs.sentToday as number) ?? 0;
      const lastSentDate = (prefs.lastSentDate as string) ?? "";
      const todayStr = new Intl.DateTimeFormat("en-CA", { timeZone: userTZ })
        .format(now); // YYYY-MM-DD

      const actualSentToday = lastSentDate === todayStr ? sentToday : 0;
      if (actualSentToday >= frequency) continue;

      // Pick random mood from user preferences
      const moods = (prefs.moods as string[]) ?? ["Peaceful"];
      const randomMood = moods[Math.floor(Math.random() * moods.length)] ?? "Peaceful";

      // Get random approved message with matching mood
      const messageSnap = await db
        .collection("messages")
        .where("status", "==", "approved")
        .where("mood", "==", randomMood)
        .limit(20)
        .get();

      if (messageSnap.empty) continue;

      const randomDoc =
        messageSnap.docs[Math.floor(Math.random() * messageSnap.size)]!;
      const msgText = randomDoc.data().text as string;

      try {
        await messaging.send({
          token: fcmToken,
          notification: {
            title: "Lumi",
            body: msgText,
          },
          data: {
            mood: randomMood,
            messageId: randomDoc.id,
          },
          apns: {
            payload: {
              aps: { sound: "default" },
            },
          },
        });

        await userDoc.ref.update({
          "notificationPrefs.sentToday": actualSentToday + 1,
          "notificationPrefs.lastSentDate": todayStr,
        });

        sentCount++;
      } catch (error) {
        console.error(`FCM send failed for user ${userDoc.id}:`, error);
      }
    }

    console.log(`Notifications sent: ${sentCount}`);
  }
);

// ═══════════════════════════════════════════════════════════════════════════════
// 12. Cleanup old pending_review messages (daily)
// ═══════════════════════════════════════════════════════════════════════════════

export const cleanupPendingMessages = onSchedule(
  { schedule: "every 24 hours", region: "europe-west1" },
  async () => {
    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);

    const staleMessages = await db
      .collection("messages")
      .where("status", "==", "pending_review")
      .where("createdAt", "<=", sevenDaysAgo)
      .limit(500)
      .get();

    const batch = db.batch();
    for (const doc of staleMessages.docs) {
      batch.update(doc.ref, { status: "expired" });
    }
    await batch.commit();

    console.log(`Cleaned up ${staleMessages.size} stale pending messages`);
  }
);
