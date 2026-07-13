import React, { useState, useEffect } from 'react';
import { collection, query, orderBy, onSnapshot, addDoc, serverTimestamp, deleteDoc, doc } from 'firebase/firestore';
import { db } from '../lib/firebase';
import { Bell, Send, Trash2, Clock } from 'lucide-react';

const formatTimestamp = (timestamp) => {
  if (!timestamp) return 'Just now';
  if (typeof timestamp.toDate === 'function') {
    try {
      return timestamp.toDate().toLocaleString();
    } catch (e) {
      return 'Just now';
    }
  }
  if (timestamp.seconds) {
    return new Date(timestamp.seconds * 1000).toLocaleString();
  }
  const date = new Date(timestamp);
  return isNaN(date.getTime()) ? 'Just now' : date.toLocaleString();
};

const Notifications = () => {
  const [notifications, setNotifications] = useState([]);
  const [loading, setLoading] = useState(true);
  
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [isSending, setIsSending] = useState(false);

  useEffect(() => {
    const q = query(collection(db, 'notifications'), orderBy('createdAt', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const notifsData = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      setNotifications(notifsData);
      setLoading(false);
    }, (error) => {
      console.error("Error fetching notifications:", error);
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const handleSendNotification = async (e) => {
    e.preventDefault();
    if (!title.trim() || !body.trim()) return;

    setIsSending(true);
    try {
      await addDoc(collection(db, 'notifications'), {
        title: title.trim(),
        body: body.trim(),
        createdAt: serverTimestamp(),
        // For global notifications, we leave targetUserId empty. 
        // If we want to target specific users in the future, we can add it here.
        targetUserId: 'all' 
      });
      
      setTitle('');
      setBody('');
      alert('Notification sent successfully! App users will see this shortly.');
    } catch (error) {
      console.error("Error sending notification:", error);
      alert('Failed to send notification');
    } finally {
      setIsSending(false);
    }
  };

  const handleDelete = async (id) => {
    if (window.confirm('Are you sure you want to delete this notification? It will be removed from users\' histories.')) {
      try {
        await deleteDoc(doc(db, 'notifications', id));
      } catch (error) {
        console.error("Error deleting notification:", error);
        alert('Failed to delete notification');
      }
    }
  };

  if (loading) {
    return (
      <div style={{ padding: '3rem', textAlign: 'center', color: 'var(--color-primary)', fontWeight: '600' }}>
        Loading notifications...
      </div>
    );
  }

  return (
    <div className="animate-fade-in" style={{ padding: '2rem' }}>
      <div className="page-header">
        <div>
          <h1 className="page-title">Notifications</h1>
          <p style={{ color: 'var(--color-text-muted)', marginTop: '0.5rem' }}>Send and manage push alerts for all app users</p>
        </div>
      </div>

      <div className="admin-grid-layout">
        {/* Compose Form */}
        <div className="compose-sticky">
          <div className="card">
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '1.5rem' }}>
              <div style={{ padding: '0.5rem', backgroundColor: 'var(--color-primary-light)', borderRadius: 'var(--radius-md)', color: 'var(--color-primary)', display: 'flex' }}>
                <Send size={20} />
              </div>
              <h2 style={{ fontSize: '1.25rem', fontWeight: '600' }}>Send New Alert</h2>
            </div>
            
            <form onSubmit={handleSendNotification}>
              <div className="form-group">
                <label className="form-label">Notification Title</label>
                <input
                  type="text"
                  required
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  placeholder="e.g. New Exam Added!"
                  className="form-control"
                />
              </div>
              
              <div className="form-group" style={{ marginBottom: '2rem' }}>
                <label className="form-label">Message Body</label>
                <textarea
                  required
                  rows="4"
                  value={body}
                  onChange={(e) => setBody(e.target.value)}
                  placeholder="e.g. Check out the new math test series available now."
                  className="form-control"
                  style={{ resize: 'vertical' }}
                ></textarea>
              </div>
              
              <button
                type="submit"
                disabled={isSending}
                className="btn-primary"
                style={{ width: '100%', padding: '0.75rem 1rem' }}
              >
                {isSending ? 'Sending...' : (
                  <>
                    <Bell size={18} /> Send Notification
                  </>
                )}
              </button>
              <p style={{ fontSize: '0.75rem', color: 'var(--color-text-muted)', marginTop: '0.75rem', textAlign: 'center' }}>
                This will be sent to all active users immediately.
              </p>
            </form>
          </div>
        </div>

        {/* Notification History */}
        <div>
          <h2 style={{ fontSize: '1.25rem', fontWeight: '600', marginBottom: '1.5rem', color: 'var(--color-secondary)' }}>
            Sent Notifications History
          </h2>
          
          <div className="notification-list">
            {notifications.length === 0 ? (
              <div className="empty-state">
                <div className="empty-state-icon-wrapper">
                  <Bell size={28} />
                </div>
                <h3>No Notifications Sent</h3>
                <p>Your notification history will appear here.</p>
              </div>
            ) : (
              notifications.map((notif) => (
                <div key={notif.id} className="notification-card">
                  <div className="notification-header">
                    <div className="notification-title-area">
                      <h3 style={{ fontSize: '1.1rem', fontWeight: '600', color: 'var(--color-secondary)' }}>{notif.title}</h3>
                      <p style={{ color: 'var(--color-text-main)', fontSize: '0.925rem', margin: '0.25rem 0 0.75rem 0', lineHeight: '1.4' }}>{notif.body}</p>
                      <div className="notification-meta">
                        <div className="meta-item">
                          <Clock size={14} />
                          <span>{formatTimestamp(notif.createdAt)}</span>
                        </div>
                        <span className="badge badge-primary" style={{ fontSize: '0.7rem' }}>
                          Target: {notif.targetUserId}
                        </span>
                      </div>
                    </div>
                    
                    <button
                      onClick={() => handleDelete(notif.id)}
                      className="btn-icon danger"
                      title="Delete Notification"
                    >
                      <Trash2 size={16} />
                    </button>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default Notifications;
