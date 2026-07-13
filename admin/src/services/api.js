import { collection, getDocs, getDoc, setDoc, addDoc, updateDoc, deleteDoc, doc, query, where } from 'firebase/firestore';
import { db } from '../lib/firebase';



export const uploadImage = async (file) => {
  const formData = new FormData();
  formData.append('file', file);
  
  const response = await fetch('http://localhost:8000/api/upload-image', {
    method: 'POST',
    body: formData,
  });
  
  if (!response.ok) {
    throw new Error('Failed to upload image');
  }
  
  const data = await response.json();
  return data.url;
};

// =======================
// EXAM CONFIGS (Dynamic structure for Exams, Subjects, Chapters, Shifts, Years)
// =======================
export const getExams = async () => {
  const q = query(collection(db, 'exams'));
  const snapshot = await getDocs(q);
  return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
};

export const addExam = async (examData) => {
  const docRef = await addDoc(collection(db, 'exams'), examData);
  return { id: docRef.id, ...examData };
};

export const updateExam = async (id, examData) => {
  const docRef = doc(db, 'exams', id);
  await updateDoc(docRef, examData);
  return { id, ...examData };
};

export const deleteExam = async (id) => {
  await deleteDoc(doc(db, 'exams', id));
  return true;
};

// =======================
// QUESTIONS
// =======================
export const getQuestions = async (type) => {
  const q = query(collection(db, 'questions'), where('type', '==', type));
  const snapshot = await getDocs(q);
  return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
};

export const addQuestion = async (questionData) => {
  const docRef = await addDoc(collection(db, 'questions'), questionData);
  return { id: docRef.id, ...questionData };
};

export const updateQuestion = async (id, questionData) => {
  const docRef = doc(db, 'questions', id);
  await updateDoc(docRef, questionData);
  return { id, ...questionData };
};

export const deleteQuestion = async (id) => {
  await deleteDoc(doc(db, 'questions', id));
  return true;
};

// =======================
// TEST SERIES
// =======================
export const getTestSeries = async () => {
  const q = query(collection(db, 'testSeries'));
  const snapshot = await getDocs(q);
  return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
};

// =======================
// NOTES
// =======================
export const getNotes = async () => {
  const q = query(collection(db, 'notes'));
  const snapshot = await getDocs(q);
  return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
};

export const addNote = async (noteData) => {
  const docRef = await addDoc(collection(db, 'notes'), noteData);
  return { id: docRef.id, ...noteData };
};

export const deleteNote = async (noteId) => {
  await deleteDoc(doc(db, 'notes', noteId));
  return true;
};

// =======================
// BOOKS
// =======================
export const getBooks = async () => {
  const q = query(collection(db, 'books'));
  const snapshot = await getDocs(q);
  return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
};

export const addBook = async (bookData) => {
  const docRef = await addDoc(collection(db, 'books'), bookData);
  return { id: docRef.id, ...bookData };
};

export const deleteBook = async (bookId) => {
  await deleteDoc(doc(db, 'books', bookId));
  return true;
};

// =======================
// USERS
// =======================
export const getUsers = async () => {
  const q = query(collection(db, 'users'));
  const snapshot = await getDocs(q);
  return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
};

// =======================
// TRANSACTIONS
// =======================
export const getTransactions = async () => {
  const q = query(collection(db, 'transactions'));
  const snapshot = await getDocs(q);
  return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
};

export const getUserTransactions = async (userId) => {
  const q = query(collection(db, 'transactions'), where('userId', '==', userId));
  const snapshot = await getDocs(q);
  return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
};

// =======================
// REPORTS
// =======================
export const getReports = async () => {
  const q = query(collection(db, 'reports'));
  const snapshot = await getDocs(q);
  return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
};

// =======================
// PRICING (Fixed Plans)
// =======================
export const getPricing = async () => {
  const docRef = doc(db, 'settings', 'pricing');
  const snapshot = await getDoc(docRef);
  if (snapshot.exists()) {
    return snapshot.data();
  }
  return {
    app_6_months: 80,
    app_1_year: 99,
    ai_starter: 29,
    ai_standard: 49,
    ai_pro: 99
  };
};

export const updatePricing = async (pricingData) => {
  const docRef = doc(db, 'settings', 'pricing');
  await setDoc(docRef, pricingData, { merge: true });
  return pricingData;
};

// =======================
// COUPONS
// =======================
export const getCoupons = async () => {
  const q = query(collection(db, 'coupons'));
  const snapshot = await getDocs(q);
  return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
};

export const addCoupon = async (couponData) => {
  const docRef = await addDoc(collection(db, 'coupons'), couponData);
  return { id: docRef.id, ...couponData };
};

export const updateCoupon = async (id, couponData) => {
  const docRef = doc(db, 'coupons', id);
  await updateDoc(docRef, couponData);
  return { id, ...couponData };
};

export const deleteCoupon = async (id) => {
  await deleteDoc(doc(db, 'coupons', id));
  return true;
};

// =======================
// USER SUBSCRIPTION UPDATE
// =======================
export const updateUserSubscription = async (userId, updateData) => {
  const docRef = doc(db, 'users', userId);
  await updateDoc(docRef, updateData);
  return { id: userId, ...updateData };
};
