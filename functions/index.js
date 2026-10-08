// 매일 아침 7시(KST) "오늘의 말씀" 푸시를 daily_verse 토픽으로 발송한다.
// 배포: firebase deploy --only functions  (Blaze 요금제 필요)
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

const KST_OFFSET_MS = 9 * 60 * 60 * 1000;
const DAY_MS = 24 * 60 * 60 * 1000;

exports.sendDailyVerse = onSchedule(
  { schedule: "0 7 * * *", timeZone: "Asia/Seoul", region: "asia-northeast3" },
  async () => {
    const snap = await getFirestore().collection("verses").orderBy("order").get();
    if (snap.empty) return;

    // 앱의 SqliteBibleRepository.getTodayVerse 와 같은 규칙(한국 날짜 기준)으로 고른다.
    // verses 컬렉션의 order 는 tool/data/verses.json 순서(= bible.db 의 daily_verses)와 같아야 한다.
    const dayIndex = Math.floor((Date.now() + KST_OFFSET_MS) / DAY_MS);
    const doc = snap.docs[dayIndex % snap.size];
    const v = doc.data();

    await getMessaging().send({
      topic: "daily_verse",
      notification: {
        title: `오늘의 말씀 · ${v.book} ${v.chapter}:${v.verse}`,
        body: v.text,
      },
      data: { verseId: doc.id },
    });
  }
);
