import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { OpenAI } from "openai";

// Firebase Admin Initialize (Mock / Offline-Ready)
admin.initializeApp();
const db = admin.firestore();

// OpenAI Configuration (Normalde process.env veya functions.config() den gelir)
// const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

/**
 * 1. AI Pozitiflik Filtresi & Moderasyon (Trigger on Create)
 * Kullanıcı "messages" koleksiyonuna yeni bir mesaj yazdığında tetiklenir.
 */
export const onMessageCreated = functions.firestore
  .document("messages/{messageId}")
  .onCreate(async (snap, context) => {
    const newMessage = snap.data();
    const messageId = context.params.messageId;
    const text = newMessage.text;
    const senderId = newMessage.senderId;

    try {
      // 1. Kullanıcının banlı (Shadowban) olup olmadığını kontrol et
      const userRef = db.collection("users").doc(senderId);
      const userDoc = await userRef.get();
      
      if (userDoc.exists && userDoc.data()?.isBanned) {
        // Kullanıcı banlıysa, mesajı "shadowbanned" olarak işaretle (kimse göremez) ama silme ki ruhu duymasın
        await snap.ref.update({ status: "shadowbanned" });
        return null;
      }

      // 2. OpenAI Moderasyon Kontrolü (Mocked for now)
      /* 
      const response = await openai.chat.completions.create({
        model: "gpt-4o-mini",
        messages: [
          { role: "system", content: "Sen Lumi adlı uygulamanın moderatörüsün. Sadece pozitif, nazik ve iyi niyetli mesajlara onay ver. Argo, nefret veya negatif enerji içeriyorsa 'REJECT' dön, iyi hissettiriyorsa 'APPROVE' dön. Cevabın sadece APPROVE veya REJECT olmalı." },
          { role: "user", content: text }
        ],
        temperature: 0.0
      });
      const aiDecision = response.choices[0].message.content?.trim();
      */
      
      // Şimdilik AI API olmadığı için her şeyi APPROVE varsayıyoruz
      const aiDecision = "APPROVE"; 

      if (aiDecision === "APPROVE") {
        // Mesaj temiz, havuza dahil et
        await snap.ref.update({ 
          status: "approved",
          approvedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        console.log(`Mesaj Onaylandı: ${messageId}`);
      } else {
        // Mesaj negatif/argo, reddet
        await snap.ref.update({ status: "rejected" });
        
        // Kullanıcının strike (uyarı) sayısını artır
        await userRef.set({
          strikes: admin.firestore.FieldValue.increment(1)
        }, { merge: true });
        
        console.log(`Mesaj Reddedildi: ${messageId}`);
      }
    } catch (error) {
      console.error("Moderasyon hatası:", error);
      // Hata durumunda güvenli tarafta kalıp beklemeye al (Manuel onay gerekebilir)
      await snap.ref.update({ status: "pending_review" });
    }
    return null;
  });

/**
 * 2. Özel Bağ (Allowlist / Code Match) Kontrolü
 * İki kullanıcının kodları eşleşiyor mu diye kontrol eder
 */
export const checkConnectionCode = functions.https.onCall(async (data, context) => {
    // Kullanıcının giriş yapıp yapmadığını kontrol et
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Giriş yapmanız gerekiyor.');
    }

    const friendCode = data.friendCode;
    const myUid = context.auth.uid;

    if (!friendCode) {
        throw new functions.https.HttpsError('invalid-argument', 'Arkadaş kodu eksik.');
    }

    // Gelen koda sahip kullanıcıyı bul
    const usersSnapshot = await db.collection("users").where("connectionCode", "==", friendCode).get();
    
    if (usersSnapshot.empty) {
        return { success: false, message: "Bu koda sahip bir kullanıcı bulunamadı." };
    }

    const friendDoc = usersSnapshot.docs[0];
    const friendUid = friendDoc.id;

    // Bağlantıyı "connections" koleksiyonuna ekle
    const connectionId = [myUid, friendUid].sort().join("_"); // Benzersiz ID oluştur
    
    await db.collection("connections").doc(connectionId).set({
        users: [myUid, friendUid],
        establishedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    return { success: true, message: "Bağlantı başarıyla kuruldu!" };
});
