import { useState, useEffect } from 'react';
import { Users as UsersIcon, UserCheck, Activity, Search, Eye, ChevronLeft } from 'lucide-react';
import { getUsers, getUserTransactions, updateUserSubscription } from '../services/api';

const Users = () => {
  const [view, setView] = useState('list'); // list | detail
  const [selectedUser, setSelectedUser] = useState(null);
  
  const [users, setUsers] = useState([]);
  const [userTxns, setUserTxns] = useState([]);
  const [loading, setLoading] = useState(true);
  const [loadingTxns, setLoadingTxns] = useState(false);
  const [editingSubscription, setEditingSubscription] = useState(false);
  const [editAppSubscription, setEditAppSubscription] = useState(false);
  const [editAiLimit, setEditAiLimit] = useState(10);
  const [editPlanName, setEditPlanName] = useState('');
  const [editExpiryDate, setEditExpiryDate] = useState('');

  useEffect(() => {
    const fetchData = async () => {
      setLoading(true);
      try {
        const usersData = await getUsers();
        setUsers(usersData);
      } catch (err) {
        console.error(err);
      }
      setLoading(false);
    };
    fetchData();
  }, []);

  const handleUserClick = async (user) => {
    setSelectedUser(user);
    setView('detail');
    setEditingSubscription(false);
    setLoadingTxns(true);
    try {
      const txns = await getUserTransactions(user.id || user.uid);
      setUserTxns(txns);
    } catch (err) {
      console.error(err);
      setUserTxns([]);
    } finally {
      setLoadingTxns(false);
    }
  };

  const handleUpdateSubscription = async () => {
    if (!selectedUser) return;
    
    try {
      const userId = selectedUser.id || selectedUser.uid;
      const updateData = {
        hasAppSubscription: editAppSubscription,
        aiQuestionsLimit: Number(editAiLimit) + (selectedUser.aiQuestionsUsed || 0),
        activePlanName: editPlanName,
        appSubscriptionExpiry: editExpiryDate ? new Date(editExpiryDate).toISOString() : null
      };
      
      await updateUserSubscription(userId, updateData);
      
      const updatedUser = { ...selectedUser, ...updateData };
      setSelectedUser(updatedUser);
      setUsers(users.map(u => (u.id === userId || u.uid === userId) ? updatedUser : u));
      setEditingSubscription(false);
    } catch(err) {
      console.error(err);
    }
  };

  const totalUsers = users.length;
  const activeUsers = users.filter(u => u.status === 'Active' || u.status === 'Online').length;
  const onlineUsers = users.filter(u => u.status === 'Online').length;

  return (
    <div className="animate-fade-in">
      {view === 'list' && (
        <>
          <div className="page-header">
            <h1 className="page-title">Users Management</h1>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '1.5rem', marginBottom: '2rem' }}>
            <div className="card" style={{ display: 'flex', alignItems: 'center', gap: '1.5rem' }}>
              <div style={{ padding: '1rem', backgroundColor: 'var(--color-primary-light)', borderRadius: 'var(--radius-md)', color: 'var(--color-primary)' }}>
                <UsersIcon size={32} />
              </div>
              <div>
                <div style={{ color: 'var(--color-text-muted)', fontSize: '0.875rem' }}>Total Users</div>
                <div style={{ fontSize: '1.875rem', fontWeight: 700 }}>{totalUsers}</div>
              </div>
            </div>
            <div className="card" style={{ display: 'flex', alignItems: 'center', gap: '1.5rem' }}>
              <div style={{ padding: '1rem', backgroundColor: 'var(--color-success-light)', borderRadius: 'var(--radius-md)', color: 'var(--color-success)' }}>
                <UserCheck size={32} />
              </div>
              <div>
                <div style={{ color: 'var(--color-text-muted)', fontSize: '0.875rem' }}>Active Users</div>
                <div style={{ fontSize: '1.875rem', fontWeight: 700 }}>{activeUsers}</div>
              </div>
            </div>
            <div className="card" style={{ display: 'flex', alignItems: 'center', gap: '1.5rem' }}>
              <div style={{ padding: '1rem', backgroundColor: 'var(--color-warning-light)', borderRadius: 'var(--radius-md)', color: 'var(--color-warning)' }}>
                <Activity size={32} />
              </div>
              <div>
                <div style={{ color: 'var(--color-text-muted)', fontSize: '0.875rem' }}>Online Users</div>
                <div style={{ fontSize: '1.875rem', fontWeight: 700 }}>{onlineUsers}</div>
              </div>
            </div>
          </div>

          <div className="card">
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '1.5rem' }}>
              <div style={{ position: 'relative', width: '300px' }}>
                <Search size={16} style={{ position: 'absolute', left: '0.75rem', top: '50%', transform: 'translateY(-50%)', color: 'var(--color-text-muted)' }} />
                <input type="text" className="form-control" placeholder="Search by name, email..." style={{ paddingLeft: '2.25rem' }} />
              </div>
              <div style={{ display: 'flex', gap: '1rem' }}>
                <select className="form-control" style={{ width: '150px' }}>
                  <option value="">All Exams</option>
                  <option value="jee">JEE</option>
                  <option value="neet">NEET</option>
                </select>
                <select className="form-control" style={{ width: '150px' }}>
                  <option value="">All Years</option>
                  <option value="2024">2024</option>
                  <option value="2025">2025</option>
                </select>
              </div>
            </div>

            <div className="table-wrapper" style={{ border: 'none', boxShadow: 'none' }}>
              <table className="data-table">
                <thead>
                  <tr>
                    <th>Name</th>
                    <th>Email</th>
                    <th>Exam & Year</th>
                    <th>Subscription</th>
                    <th>Status</th>
                    <th style={{ textAlign: 'right' }}>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {loading ? (
                    <tr><td colSpan="6" style={{ textAlign: 'center', padding: '2rem' }}>Loading users from Firebase...</td></tr>
                  ) : users.length === 0 ? (
                    <tr><td colSpan="6" style={{ textAlign: 'center', padding: '2rem' }}>No users found.</td></tr>
                  ) : users.map(user => (
                    <tr key={user.id}>
                      <td style={{ fontWeight: 500 }}>{user.name || 'Unnamed User'}</td>
                      <td>{user.email}</td>
                      <td>{user.examNames || user.exam || 'N/A'} {user.year ? `(${user.year})` : ''}</td>
                      <td>
                        <div style={{ fontSize: '0.8rem', marginBottom: '4px' }}>
                          App: <span style={{ color: user.hasAppSubscription ? 'var(--color-success)' : 'var(--color-text-muted)', fontWeight: 'bold' }}>{user.hasAppSubscription ? 'Active' : 'Inactive'}</span>
                        </div>
                        <div style={{ fontSize: '0.8rem' }}>
                          AI Remaining: <span style={{ fontWeight: 'bold' }}>{(user.aiQuestionsLimit ?? 10) - (user.aiQuestionsUsed ?? 0)}</span>
                        </div>
                      </td>
                      <td>
                        <span className={`badge ${user.status === 'Online' ? 'badge-success' : user.status === 'Active' ? 'badge-primary' : 'badge-danger'}`}>
                          {user.status || 'Offline'}
                        </span>
                      </td>
                      <td style={{ textAlign: 'right' }}>
                        <button className="btn-outline" onClick={() => handleUserClick(user)} style={{ padding: '0.4rem', color: 'var(--color-primary)' }}>
                          <Eye size={16} /> View Details
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </>
      )}

      {view === 'detail' && selectedUser && (
        <>
          <button className="btn-outline" onClick={() => setView('list')} style={{ marginBottom: '1.5rem', border: 'none', padding: 0 }}>
            <ChevronLeft size={20} /> Back to Users
          </button>
          
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 2fr', gap: '2rem' }}>
            {/* User Profile Summary */}
            <div className="card">
              <div style={{ textAlign: 'center', marginBottom: '2rem' }}>
                <div style={{ width: '80px', height: '80px', backgroundColor: 'var(--color-primary-light)', borderRadius: '50%', margin: '0 auto 1rem auto', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--color-primary)', fontSize: '2rem', fontWeight: 600 }}>
                  {(selectedUser.name || '?').charAt(0).toUpperCase()}
                </div>
                <h2 style={{ margin: 0 }}>{selectedUser.name || 'Unnamed User'}</h2>
                <div style={{ color: 'var(--color-text-muted)', fontSize: '0.875rem' }}>{selectedUser.email}</div>
                <span className={`badge ${selectedUser.status === 'Online' ? 'badge-success' : 'badge-primary'}`} style={{ marginTop: '0.5rem' }}>
                  {selectedUser.status || 'Offline'}
                </span>
              </div>
              
              <div style={{ borderTop: '1px solid var(--color-border-light)', paddingTop: '1.5rem' }}>
                <div style={{ marginBottom: '1.5rem' }}>
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '0.5rem' }}>
                    <strong>Subscription Settings</strong>
                    <button className="btn-outline" style={{ padding: '0.2rem 0.5rem', fontSize: '0.8rem' }} onClick={() => {
                      setEditingSubscription(true);
                      setEditAppSubscription(selectedUser.hasAppSubscription ?? false);
                      setEditAiLimit((selectedUser.aiQuestionsLimit ?? 10) - (selectedUser.aiQuestionsUsed ?? 0));
                      setEditPlanName(selectedUser.activePlanName ?? '');
                      const expiry = selectedUser.appSubscriptionExpiry;
                      setEditExpiryDate(expiry ? new Date(expiry).toISOString().split('T')[0] : '');
                    }}>Change</button>
                  </div>
                  
                  {!editingSubscription ? (
                    <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0.5rem' }}>
                      <div className="badge badge-primary" style={{ backgroundColor: selectedUser.hasAppSubscription ? 'var(--color-success)' : 'var(--color-text-muted)' }}>
                        App: {selectedUser.hasAppSubscription ? 'Active' : 'Inactive'}
                      </div>
                      <div className="badge badge-primary" style={{ backgroundColor: 'var(--color-primary)', color: '#fff' }}>
                        AI Remaining: {(selectedUser.aiQuestionsLimit ?? 10) - (selectedUser.aiQuestionsUsed ?? 0)}
                      </div>
                      {selectedUser.activePlanName && (
                        <div className="badge badge-primary" style={{ backgroundColor: 'var(--color-secondary)' }}>
                          Plan: {selectedUser.activePlanName}
                        </div>
                      )}
                      {selectedUser.appSubscriptionExpiry && (
                        <div className="badge badge-primary" style={{ backgroundColor: 'var(--color-warning)' }}>
                          Expires: {new Date(selectedUser.appSubscriptionExpiry).toLocaleDateString()}
                        </div>
                      )}
                    </div>
                  ) : (
                    <div style={{ backgroundColor: 'var(--color-background)', padding: '1.5rem', borderRadius: 'var(--radius-md)', display: 'flex', flexDirection: 'column', gap: '1.25rem', border: '1px solid var(--color-border-light)' }}>
                      <h4 style={{ margin: 0, color: 'var(--color-secondary)', fontSize: '1.1rem', borderBottom: '1px solid var(--color-border-light)', paddingBottom: '0.5rem' }}>Edit Subscription</h4>
                      
                      <div className="form-group" style={{ margin: 0 }}>
                        <label style={{ display: 'block', marginBottom: '0.5rem', fontWeight: 500, color: 'var(--color-text)' }}>Whole App Access Plan</label>
                        <select 
                          className="form-control" 
                          value={editPlanName} 
                          onChange={(e) => {
                            const val = e.target.value;
                            setEditPlanName(val);
                            if (val && val !== 'Free') {
                              setEditAppSubscription(true);
                            } else {
                              setEditAppSubscription(false);
                            }
                          }}
                        >
                          <option value="">Free (No Plan)</option>
                          <option value="Whole App Gold Access (6 Months)">Whole App Gold Access (6 Months)</option>
                          <option value="Whole App Gold Access (1 Year)">Whole App Gold Access (1 Year)</option>
                        </select>
                      </div>
                      
                      <div className="form-group" style={{ margin: 0 }}>
                        <label style={{ display: 'block', marginBottom: '0.5rem', fontWeight: 500, color: 'var(--color-text)' }}>App Access Expiry Date</label>
                        <input 
                          type="date" 
                          className="form-control" 
                          value={editExpiryDate} 
                          onChange={(e) => setEditExpiryDate(e.target.value)} 
                        />
                      </div>

                      <div className="form-group" style={{ margin: 0 }}>
                        <label style={{ display: 'block', marginBottom: '0.5rem', fontWeight: 500, color: 'var(--color-text)' }}>Ask AI (Questions Remaining)</label>
                        <input 
                          type="number" 
                          className="form-control" 
                          value={editAiLimit} 
                          onChange={(e) => setEditAiLimit(e.target.value)} 
                          min="0"
                        />
                      </div>

                      <div style={{ display: 'flex', gap: '0.75rem', marginTop: '0.5rem', justifyContent: 'flex-end' }}>
                        <button className="btn-outline" onClick={() => setEditingSubscription(false)}>Cancel</button>
                        <button className="btn-primary" onClick={handleUpdateSubscription}>Save Changes</button>
                      </div>
                    </div>
                  )}
                </div>
                <div style={{ marginBottom: '1rem' }}><strong>Mobile:</strong> {selectedUser.mobile || selectedUser.phone || 'N/A'}</div>
                <div style={{ marginBottom: '1rem' }}><strong>Target Exam:</strong> {selectedUser.examNames || selectedUser.exam || 'N/A'}</div>
                <div style={{ marginBottom: '1rem' }}><strong>Appearance Year:</strong> {selectedUser.year || 'N/A'}</div>
                <div style={{ marginBottom: '1rem' }}><strong>Class:</strong> {selectedUser.class || 'N/A'}</div>
                <div style={{ marginBottom: '1rem' }}><strong>City:</strong> {selectedUser.city || 'N/A'}</div>
                <div style={{ marginBottom: '1rem' }}><strong>State:</strong> {selectedUser.state || 'N/A'}</div>
              </div>
            </div>

            {/* User Activity & Performance */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
              <div className="card">
                <h3 style={{ marginBottom: '1rem' }}>Test Performance</h3>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '1.5rem' }}>
                  <div>
                    <div style={{ color: 'var(--color-text-muted)', fontSize: '0.875rem' }}>Tests Appeared</div>
                    <div style={{ fontSize: '1.5rem', fontWeight: 600 }}>{selectedUser.testsAppeared || 0}</div>
                  </div>
                  <div>
                    <div style={{ color: 'var(--color-text-muted)', fontSize: '0.875rem' }}>Average Accuracy</div>
                    <div style={{ fontSize: '1.5rem', fontWeight: 600, color: 'var(--color-success)' }}>{selectedUser.averageAccuracy || '0%'}</div>
                  </div>
                  <div>
                    <div style={{ color: 'var(--color-text-muted)', fontSize: '0.875rem' }}>Overall Percentile</div>
                    <div style={{ fontSize: '1.5rem', fontWeight: 600, color: 'var(--color-primary)' }}>{selectedUser.overallPercentile || 'N/A'}</div>
                  </div>
                </div>
                {/* Mock Chart Area */}
                <div style={{ height: '150px', backgroundColor: 'var(--color-background)', borderRadius: 'var(--radius-md)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--color-text-muted)' }}>
                  Performance Chart Placeholder
                </div>
              </div>

              <div className="card">
                <h3 style={{ marginBottom: '1rem' }}>Transactions</h3>
                <table className="data-table">
                  <thead><tr><th>Date</th><th>Item</th><th>Amount</th><th>Status</th></tr></thead>
                  <tbody>
                    {loadingTxns ? (
                      <tr><td colSpan="4" style={{ textAlign: 'center', padding: '1rem' }}>Loading...</td></tr>
                    ) : userTxns.length === 0 ? (
                      <tr><td colSpan="4" style={{ textAlign: 'center', padding: '1rem' }}>No transactions found.</td></tr>
                    ) : userTxns.map(txn => (
                      <tr key={txn.id}>
                        <td>{new Date(txn.date).toLocaleDateString()}</td>
                        <td>{txn.item}</td>
                        <td>₹{txn.amount}</td>
                        <td>
                          <span className={`badge ${
                            (txn.status === 'Completed' || txn.status === 'Success') ? 'badge-success' 
                            : txn.status === 'Pending' ? 'badge-warning' 
                            : 'badge-danger'
                          }`}>
                            {txn.status}
                          </span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </>
      )}
    </div>
  );
};

export default Users;
