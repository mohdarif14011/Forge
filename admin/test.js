import { initializeApp } from 'firebase/app';
import { getFirestore, collection, getDocs } from 'firebase/firestore';

const firebaseConfig = {
  apiKey: "AIzaSyDFXbiU4aIFPzIYgY-litE7BFNZmYsKLGo",
  authDomain: "forge-115e1.firebaseapp.com",
  projectId: "forge-115e1",
  storageBucket: "forge-115e1.firebasestorage.app",
  messagingSenderId: "961262375445",
  appId: "1:961262375445:web:e7b70c2b158bb02db2341c"
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

async function checkNotes() {
  const snapshot = await getDocs(collection(db, 'notes'));
  snapshot.docs.forEach(doc => {
    console.log(doc.id, '=>', doc.data().pdfUrl);
  });
  process.exit(0);
}

checkNotes();
