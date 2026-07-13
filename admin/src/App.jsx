import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext';
import Layout from './components/Layout';
import Login from './pages/Login';
import UploadQuestions from './pages/UploadQuestions';
import Exams from './pages/Exams';
import PYQs from './pages/PYQs';
import ExtraQuestions from './pages/ExtraQuestions';
import TestSeries from './pages/TestSeries';
import Notes from './pages/Notes';
import Books from './pages/Books';
import Subscription from './pages/Subscription';
import Users from './pages/Users';
import Reports from './pages/Reports';
import Financial from './pages/Financial';
import HelpSupport from './pages/HelpSupport';
import Notifications from './pages/Notifications';

// Protected Route Wrapper
const ProtectedRoute = ({ children }) => {
  const { currentUser, loading } = useAuth();
  
  if (loading) {
    return (
      <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <div style={{ color: 'var(--color-primary)', fontSize: '1.5rem' }}>Loading...</div>
      </div>
    );
  }
  
  if (!currentUser) {
    return <Navigate to="/login" replace />;
  }
  
  // Also verify email against whitelist
  const allowedEmails = (import.meta.env.VITE_ADMIN_EMAILS || '').split(',').map(e => e.trim().toLowerCase());
  if (allowedEmails.length > 0 && currentUser.email && !allowedEmails.includes(currentUser.email.toLowerCase())) {
    return <Navigate to="/login" replace />;
  }
  
  return children;
};

function App() {
  return (
    <AuthProvider>
      <Router>
        <Routes>
          <Route path="/login" element={<Login />} />
          
          <Route path="/" element={<ProtectedRoute><Layout /></ProtectedRoute>}>
            <Route index element={<Navigate to="/users" replace />} />
            <Route path="exams" element={<Exams />} />
            <Route path="upload-questions" element={<UploadQuestions />} />
            <Route path="pyqs/*" element={<PYQs />} />
            <Route path="extra-questions/*" element={<ExtraQuestions />} />
            <Route path="test-series/*" element={<TestSeries />} />
            <Route path="notes/*" element={<Notes />} />
            <Route path="books/*" element={<Books />} />
            <Route path="subscription" element={<Subscription />} />
            <Route path="users/*" element={<Users />} />
            <Route path="reports" element={<Reports />} />
            <Route path="financial" element={<Financial />} />
            <Route path="support" element={<HelpSupport />} />
            <Route path="notifications" element={<Notifications />} />
          </Route>
        </Routes>
      </Router>
    </AuthProvider>
  );
}

export default App;
