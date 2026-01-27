const admin = require('firebase-admin');

// Initialize the Firebase Admin SDK
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function updateDocuments() {
  const collectionRef = db.collection('model_answers');
  const snapshot = await collectionRef.get();

  if (snapshot.empty) {
    console.log('No documents found.');
    return;
  }

  const batch = db.batch();
  snapshot.forEach(doc => {
    batch.update(doc.ref, { isApproved: false });
  });

  await batch.commit();
  console.log(`Successfully updated ${snapshot.size} documents.`);
}

updateDocuments().catch(console.error);
