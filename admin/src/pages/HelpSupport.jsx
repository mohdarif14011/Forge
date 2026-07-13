import React, { useState, useEffect } from 'react';
import { collection, query, orderBy, onSnapshot, doc, updateDoc, deleteDoc } from 'firebase/firestore';
import { db } from '../lib/firebase';
import { MessageSquare, CheckCircle, Trash2, Mail, Clock } from 'lucide-react';

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

const HelpSupport = () => {
  const [tickets, setTickets] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const q = query(collection(db, 'support_tickets'), orderBy('createdAt', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const ticketsData = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      setTickets(ticketsData);
      setLoading(false);
    }, (error) => {
      console.error("Error fetching support tickets:", error);
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const handleResolve = async (id, currentStatus) => {
    try {
      const newStatus = currentStatus === 'Resolved' ? 'Open' : 'Resolved';
      await updateDoc(doc(db, 'support_tickets', id), {
        status: newStatus
      });
    } catch (error) {
      console.error("Error updating ticket:", error);
      alert('Failed to update ticket status');
    }
  };

  const handleDelete = async (id) => {
    if (window.confirm('Are you sure you want to delete this support ticket?')) {
      try {
        await deleteDoc(doc(db, 'support_tickets', id));
      } catch (error) {
        console.error("Error deleting ticket:", error);
        alert('Failed to delete ticket');
      }
    }
  };

  if (loading) {
    return (
      <div style={{ padding: '3rem', textAlign: 'center', color: 'var(--color-primary)', fontWeight: '600' }}>
        Loading support tickets...
      </div>
    );
  }

  return (
    <div className="animate-fade-in" style={{ padding: '2rem' }}>
      <div className="page-header">
        <div>
          <h1 className="page-title">Help & Support</h1>
          <p style={{ color: 'var(--color-text-muted)', marginTop: '0.5rem' }}>Manage and respond to user support requests</p>
        </div>
        <div className="stat-box">
          <div className="stat-icon">
            <MessageSquare size={20} />
          </div>
          <div>
            <div className="stat-label">Total Tickets</div>
            <div className="stat-val">{tickets.length}</div>
          </div>
        </div>
      </div>

      <div className="ticket-list">
        {tickets.length === 0 ? (
          <div className="empty-state">
            <div className="empty-state-icon-wrapper">
              <CheckCircle size={28} />
            </div>
            <h3>Inbox Zero!</h3>
            <p>There are no pending support tickets.</p>
          </div>
        ) : (
          tickets.map((ticket) => (
            <div 
              key={ticket.id} 
              className={`ticket-card ${ticket.status === 'Resolved' ? 'resolved' : ''}`}
            >
              <div className="ticket-header">
                <div className="ticket-title-area">
                  <div className="ticket-title-row">
                    <span className={`badge ${ticket.status === 'Resolved' ? 'badge-success' : 'badge-warning'}`}>
                      {ticket.status || 'Open'}
                    </span>
                    <h3 style={{ fontSize: '1.25rem', fontWeight: '600', color: 'var(--color-secondary)' }}>{ticket.subject}</h3>
                  </div>
                  <div className="ticket-meta">
                    <div className="meta-item">
                      <Mail size={14} />
                      <span>{ticket.userEmail}</span>
                    </div>
                    <div className="meta-item">
                      <Clock size={14} />
                      <span>{formatTimestamp(ticket.createdAt)}</span>
                    </div>
                  </div>
                </div>
                
                <div className="action-buttons">
                  <button
                    onClick={() => window.open(`mailto:${ticket.userEmail}?subject=Re: ${ticket.subject}`, '_blank')}
                    className="btn-icon info"
                    title="Reply via Email"
                  >
                    <Mail size={18} />
                  </button>
                  <button
                    onClick={() => handleResolve(ticket.id, ticket.status)}
                    className={`btn-icon ${ticket.status === 'Resolved' ? 'warning' : 'success'}`}
                    title={ticket.status === 'Resolved' ? 'Reopen Ticket' : 'Mark as Resolved'}
                    style={{
                      color: ticket.status === 'Resolved' ? 'var(--color-warning)' : 'var(--color-success)',
                      borderColor: ticket.status === 'Resolved' ? 'var(--color-warning)' : 'var(--color-success)',
                      backgroundColor: ticket.status === 'Resolved' ? 'var(--color-warning-light)' : 'var(--color-success-light)'
                    }}
                  >
                    <CheckCircle size={18} />
                  </button>
                  <button
                    onClick={() => handleDelete(ticket.id)}
                    className="btn-icon danger"
                    title="Delete Ticket"
                  >
                    <Trash2 size={18} />
                  </button>
                </div>
              </div>
              
              <div className="ticket-message">
                {ticket.message}
              </div>
              
              <div className="ticket-footer">
                <span>Submitted by: <strong style={{ color: 'var(--color-text-main)' }}>{ticket.userName}</strong></span>
                <span>User ID: <code>{ticket.userId}</code></span>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
};

export default HelpSupport;
