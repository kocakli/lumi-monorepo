// Send a test push to verify the custom notification sound (lumi-notification.caf)
// reaches the device with the right APNs payload (category lumi.message).
import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';

initializeApp({
  credential: applicationDefault(),
  projectId: 'lumi-tease',
});

const db = getFirestore();
const messaging = getMessaging();

// Find users with FCM tokens. Sort by createdAt descending; the most
// recently created user is the latest install (likely the dev's
// physical iPhone running build 17).
const snap = await db.collection('users')
  .orderBy('createdAt', 'desc')
  .limit(10)
  .get();

const candidates = snap.docs
  .filter(d => typeof d.data().fcmToken === 'string' && d.data().fcmToken.length > 20)
  .map(d => ({
    uid: d.id,
    token: d.data().fcmToken,
    createdAt: d.data().createdAt?.toDate?.() ?? null,
    lang: d.data().language ?? '?',
  }));

if (candidates.length === 0) {
  console.log('No users with fcmToken found.');
  process.exit(1);
}

console.log('Recent users with FCM tokens:');
candidates.forEach((c, i) => {
  const dateStr = c.createdAt ? c.createdAt.toISOString() : '?';
  console.log(`  ${i}: uid=${c.uid.slice(0, 8)}…  lang=${c.lang}  created=${dateStr}  token=${c.token.slice(0, 16)}…`);
});

// Default to the most recent one
const target = candidates[0];
console.log(`\nSending to most recent: uid=${target.uid.slice(0, 8)}… (${target.token.slice(0, 16)}…)`);

const message = {
  token: target.token,
  notification: {
    title: 'Lumi',
    body: 'Even the smallest star shines in the darkest night.',
  },
  data: {
    type: 'test',
    sentAt: new Date().toISOString(),
  },
  apns: {
    payload: {
      aps: {
        sound: 'lumi-notification.caf',
        category: 'lumi.message',
        'mutable-content': 1,
      },
    },
  },
};

try {
  const messageId = await messaging.send(message);
  console.log(`\n✓ Sent: ${messageId}`);
  console.log('\nIf the device has build 17 installed:');
  console.log('  - Custom sound should play (lumi-notification.caf, ~2s)');
  console.log('  - Watch should mirror the notification with custom render (lumi.message category)');
  console.log('\nIf the device has build 16 or earlier installed:');
  console.log('  - Sound file is missing → APNs falls back to silent (ringtone if device has app sounds on)');
  console.log('  - Watch still mirrors but with system default render (no custom NotificationView)');
} catch (err) {
  console.error(`\n✗ Send failed: ${err.code || err.message}`);
  if (err.code === 'messaging/registration-token-not-registered') {
    console.error('Token was unregistered. The user may have uninstalled the app or signed out.');
  }
  process.exit(1);
}
