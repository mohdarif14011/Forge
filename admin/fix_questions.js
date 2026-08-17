import { initializeApp } from 'firebase/app';
import { getFirestore, collection, getDocs, doc, updateDoc } from 'firebase/firestore';

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

async function inspectQuestions() {
  const snapshot = await getDocs(collection(db, 'questions'));
  const questions = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
  console.log(JSON.stringify(questions, null, 2));
  process.exit(0);
}

inspectQuestions();
