const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.matchPlayers = functions.firestore
  .document('gamesQueue/{gameQueueId}')
  .onCreate(async (snap, context) => {
    const newGameData = snap.data();
    const gameTime = newGameData.gameTime;

    const queueRef = admin.firestore().collection('gamesQueue');
    const snapshot = await queueRef
      .where('gameTime', '==', gameTime)
      .where('status', '==', 'waiting')
      .orderBy('timestamp')
      .get();

    if (snapshot.size >= 2) {
      const players = snapshot.docs.slice(0, 2);

      const player1 = players[0].data();
      const player2 = players[1].data();

      const player1Ref = players[0].ref;
      const player2Ref = players[1].ref;

      const allLetters = generateLetterPool();
      shuffleArray(allLetters);

      const letters1 = allLetters.splice(0, 7);
      const letters2 = allLetters.splice(0, 7);
      const remainingPool = allLetters; // ⬅️ kalan 86 harfi sakla

      const emptyBoard = Array(15 * 15).fill(""); // düz dizi

      const gameData = {
        player1Id: player1.userID,
        player2Id: player2.userID,
        player1Username: player1.username,
        player2Username: player2.username,
        board: emptyBoard,
        remainingPool: remainingPool,
        letters: {
          [player1.userID]: letters1,
          [player2.userID]: letters2
        },
        scores: {
          [player1.userID]: 0,
          [player2.userID]: 0
        },
        turn: Math.random() < 0.5 ? player1.userID : player2.userID,
        gameTime: gameTime,
        createdAt: admin.firestore.FieldValue.serverTimestamp(), // 🆕 ekledik
        gameStatus: "active"
      };

      // Oyun oluştur ve ID al
      const gameRef = await admin.firestore().collection("games").add(gameData);

      // gamesQueue -> matched ve gameId ile güncelle
      await player1Ref.update({ status: 'matched', gameId: gameRef.id });
      await player2Ref.update({ status: 'matched', gameId: gameRef.id });

      console.log(`✅ Oyun oluşturuldu: ${gameRef.id}`);
    }
  });

// HARF HAVUZU
function generateLetterPool() {
  const lettersWithCounts = [
    ["A", 12], ["B", 2], ["C", 2], ["Ç", 2], ["D", 2], ["E", 8],
    ["F", 1], ["G", 1], ["Ğ", 1], ["H", 1], ["I", 4], ["İ", 7],
    ["J", 1], ["K", 7], ["L", 7], ["M", 4], ["N", 5], ["O", 3],
    ["Ö", 1], ["P", 1], ["R", 6], ["S", 3], ["Ş", 2], ["T", 5],
    ["U", 3], ["Ü", 2], ["V", 1], ["Y", 2], ["Z", 2], ["*", 2]
  ];
  let pool = [];
  for (let [letter, count] of lettersWithCounts) {
    pool.push(...Array(count).fill(letter));
  }
  return pool;
}

// KARMA
function shuffleArray(array) {
  for (let i = array.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [array[i], array[j]] = [array[j], array[i]];
  }
}