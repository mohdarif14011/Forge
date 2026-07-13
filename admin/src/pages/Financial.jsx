import { useState, useEffect } from 'react';
import { DollarSign, TrendingUp, CreditCard, ArrowUpRight, ArrowDownRight } from 'lucide-react';
import { getTransactions } from '../services/api';

const Financial = () => {
  const [transactions, setTransactions] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchTransactions = async () => {
      setLoading(true);
      try {
        const data = await getTransactions();
        // Sort by date descending
        const sortedData = data.sort((a, b) => new Date(b.date) - new Date(a.date));
        setTransactions(sortedData);
      } catch (error) {
        console.error("Error fetching transactions", error);
      } finally {
        setLoading(false);
      }
    };
    fetchTransactions();
  }, []);

  // Compute Metrics
  const totalRevenue = transactions
    .filter(t => t.status === 'Completed' || t.status === 'Success')
    .reduce((sum, t) => sum + (Number(t.amount) || 0), 0);

  const activeSubscriptions = transactions
    .filter(t => (t.status === 'Completed' || t.status === 'Success') && t.item?.toLowerCase().includes('subscription'))
    .length;

  const totalRefunds = transactions
    .filter(t => t.status === 'Refunded')
    .reduce((sum, t) => sum + (Number(t.amount) || 0), 0);

  const avgRevenue = totalRevenue > 0 && activeSubscriptions > 0 
    ? (totalRevenue / activeSubscriptions).toFixed(0) 
    : 0;

  // Revenue by product mapping
  const revenueByProduct = transactions
    .filter(t => t.status === 'Completed' || t.status === 'Success')
    .reduce((acc, t) => {
      acc[t.item] = (acc[t.item] || 0) + (Number(t.amount) || 0);
      return acc;
    }, {});
  
  const topProducts = Object.entries(revenueByProduct)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 3);
  return (
    <div className="animate-fade-in">
      <div className="page-header">
        <h1 className="page-title">Financial Overview</h1>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '1.5rem', marginBottom: '2rem' }}>
        <div className="card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '1rem' }}>
            <div>
              <div style={{ color: 'var(--color-text-muted)', fontSize: '0.875rem' }}>Total Revenue</div>
              <div style={{ fontSize: '1.875rem', fontWeight: 700 }}>₹{totalRevenue.toLocaleString()}</div>
            </div>
            <div style={{ padding: '0.75rem', backgroundColor: 'var(--color-primary-light)', borderRadius: 'var(--radius-md)', color: 'var(--color-primary)' }}>
              <DollarSign size={24} />
            </div>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.25rem', fontSize: '0.875rem', color: 'var(--color-success)' }}>
            <ArrowUpRight size={16} /> Dynamic
          </div>
        </div>

        <div className="card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '1rem' }}>
            <div>
              <div style={{ color: 'var(--color-text-muted)', fontSize: '0.875rem' }}>Active Subscriptions</div>
              <div style={{ fontSize: '1.875rem', fontWeight: 700 }}>{activeSubscriptions}</div>
            </div>
            <div style={{ padding: '0.75rem', backgroundColor: 'var(--color-success-light)', borderRadius: 'var(--radius-md)', color: 'var(--color-success)' }}>
              <TrendingUp size={24} />
            </div>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.25rem', fontSize: '0.875rem', color: 'var(--color-success)' }}>
            <ArrowUpRight size={16} /> Dynamic
          </div>
        </div>

        <div className="card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '1rem' }}>
            <div>
              <div style={{ color: 'var(--color-text-muted)', fontSize: '0.875rem' }}>Refunds</div>
              <div style={{ fontSize: '1.875rem', fontWeight: 700 }}>₹{totalRefunds.toLocaleString()}</div>
            </div>
            <div style={{ padding: '0.75rem', backgroundColor: 'var(--color-danger-light)', borderRadius: 'var(--radius-md)', color: 'var(--color-danger)' }}>
              <ArrowDownRight size={24} />
            </div>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.25rem', fontSize: '0.875rem', color: 'var(--color-danger)' }}>
            <ArrowUpRight size={16} /> Dynamic
          </div>
        </div>

        <div className="card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '1rem' }}>
            <div>
              <div style={{ color: 'var(--color-text-muted)', fontSize: '0.875rem' }}>Avg. Revenue / Sub</div>
              <div style={{ fontSize: '1.875rem', fontWeight: 700 }}>₹{avgRevenue}</div>
            </div>
            <div style={{ padding: '0.75rem', backgroundColor: 'var(--color-warning-light)', borderRadius: 'var(--radius-md)', color: 'var(--color-warning)' }}>
              <CreditCard size={24} />
            </div>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.25rem', fontSize: '0.875rem', color: 'var(--color-text-muted)' }}>
            Dynamic
          </div>
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '1.5rem' }}>
        <div className="card">
          <h3 style={{ marginBottom: '1.5rem' }}>Recent Transactions</h3>
          <div className="table-wrapper" style={{ border: 'none', boxShadow: 'none' }}>
            <table className="data-table">
              <thead>
                <tr>
                  <th>Transaction ID</th>
                  <th>User</th>
                  <th>Amount</th>
                  <th>Date</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                {loading ? (
                  <tr><td colSpan="5" style={{ textAlign: 'center', padding: '2rem' }}>Loading transactions...</td></tr>
                ) : transactions.length === 0 ? (
                  <tr><td colSpan="5" style={{ textAlign: 'center', padding: '2rem' }}>No transactions found.</td></tr>
                ) : transactions.map(txn => (
                  <tr key={txn.id}>
                    <td>#{txn.id.substring(0, 8).toUpperCase()}</td>
                    <td style={{ fontWeight: 500 }}>{txn.userName || txn.userId}</td>
                    <td>₹{txn.amount}</td>
                    <td>{new Date(txn.date).toLocaleDateString()}</td>
                    <td>
                      <span className={`badge ${
                        (txn.status === 'Completed' || txn.status === 'Success') ? 'badge-success' 
                        : txn.status === 'Pending' ? 'badge-warning' 
                        : 'badge-danger'
                      }`}>
                        {txn.status || 'Pending'}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        <div className="card">
          <h3 style={{ marginBottom: '1.5rem' }}>Revenue by Product</h3>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
            {topProducts.length === 0 ? (
              <div style={{ color: 'var(--color-text-muted)' }}>No product revenue data yet.</div>
            ) : topProducts.map(([productName, rev], idx) => {
              const percentage = ((rev / totalRevenue) * 100).toFixed(1);
              const colors = ['var(--color-primary)', 'var(--color-success)', 'var(--color-warning)'];
              return (
                <div key={productName}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '0.25rem', fontSize: '0.875rem' }}>
                    <span>{productName}</span>
                    <span style={{ fontWeight: 600 }}>{percentage}% (₹{rev.toLocaleString()})</span>
                  </div>
                  <div style={{ width: '100%', height: '8px', backgroundColor: 'var(--color-border-light)', borderRadius: '4px', overflow: 'hidden' }}>
                    <div style={{ width: `${percentage}%`, height: '100%', backgroundColor: colors[idx % colors.length] }}></div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </div>
  );
};

export default Financial;
