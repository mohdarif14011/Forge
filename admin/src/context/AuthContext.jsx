import { createContext, useContext, useEffect, useState } from 'react';
import { onAuthStateChanged, signInWithEmailAndPassword, signOut } from 'firebase/auth';
import { auth } from '../lib/firebase';

const AuthContext = createContext({});

export const AuthProvider = ({ children }) => {
  const [currentUser, setCurrentUser] = useState(null);
  const [loading, setLoading] = useState(true);

  // Simulated login fallback for testing without real Firebase Config
  const [isSimulatedAuth, setIsSimulatedAuth] = useState(false);

  useEffect(() => {
    // Attempt to use real Firebase Auth
    try {
      const unsubscribe = onAuthStateChanged(auth, (user) => {
        if (!isSimulatedAuth) {
          setCurrentUser(user);
        }
        setLoading(false);
      });
      return unsubscribe;
    } catch (error) {
      console.warn("Firebase Auth not configured properly. Using simulated auth for demo.");
      setLoading(false);
    }
  }, [isSimulatedAuth]);

  const login = async (email, password) => {
    try {
      if (auth.app.options.apiKey === "YOUR_API_KEY") {
        throw new Error("Dummy Config");
      }
      
      const allowedEmails = (import.meta.env.VITE_ADMIN_EMAILS || '').split(',').map(e => e.trim().toLowerCase());
      if (allowedEmails.length > 0 && !allowedEmails.includes(email.trim().toLowerCase())) {
        throw new Error("Unauthorized: Email is not in the admin whitelist.");
      }

      return await signInWithEmailAndPassword(auth, email, password);
    } catch (error) {
      throw new Error(error.message || "Invalid credentials or Firebase not configured.");
    }
  };

  const logout = async () => {
    if (isSimulatedAuth) {
      setCurrentUser(null);
      setIsSimulatedAuth(false);
      return;
    }
    return await signOut(auth);
  };

  return (
    <AuthContext.Provider value={{ currentUser, login, logout, loading }}>
      {!loading && children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  return useContext(AuthContext);
};
