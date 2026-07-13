import { useState, useEffect } from 'react';
import { CreditCard, Tag, Plus, Edit2, Trash2, CheckCircle, XCircle } from 'lucide-react';
import { 
  getPricing, updatePricing,
  getCoupons, addCoupon, updateCoupon, deleteCoupon 
} from '../services/api';

const Subscription = () => {
  const [activeTab, setActiveTab] = useState('pricing'); // 'pricing' | 'coupons'
  
  // State for Pricing
  const [pricing, setPricing] = useState({
    app_6_months: 80,
    app_1_year: 99,
    ai_starter: 29,
    ai_standard: 49,
    ai_pro: 99
  });
  const [loadingPricing, setLoadingPricing] = useState(false);
  const [savingPricing, setSavingPricing] = useState(false);

  // State for Coupons
  const [coupons, setCoupons] = useState([]);
  const [loadingCoupons, setLoadingCoupons] = useState(false);
  const [showCouponModal, setShowCouponModal] = useState(false);
  const [editingCoupon, setEditingCoupon] = useState(null);
  const [couponForm, setCouponForm] = useState({ code: '', discountPercentage: '', expiryDate: '', usageLimit: '', status: 'Active' });

  useEffect(() => {
    fetchPricing();
    fetchCoupons();
  }, []);

  const fetchPricing = async () => {
    setLoadingPricing(true);
    try {
      const data = await getPricing();
      setPricing(data);
    } catch (err) {
      console.error(err);
    }
    setLoadingPricing(false);
  };

  const fetchCoupons = async () => {
    setLoadingCoupons(true);
    try {
      const data = await getCoupons();
      setCoupons(data);
    } catch (err) {
      console.error(err);
    }
    setLoadingCoupons(false);
  };

  // Pricing Handlers
  const handleSavePricing = async () => {
    setSavingPricing(true);
    try {
      const payload = {
        app_6_months: Number(pricing.app_6_months),
        app_1_year: Number(pricing.app_1_year),
        ai_starter: Number(pricing.ai_starter),
        ai_standard: Number(pricing.ai_standard),
        ai_pro: Number(pricing.ai_pro),
      };
      await updatePricing(payload);
      alert('Pricing updated successfully!');
    } catch (error) {
      console.error("Error saving pricing", error);
      alert('Failed to update pricing.');
    }
    setSavingPricing(false);
  };

  const handlePricingChange = (key, value) => {
    setPricing(prev => ({ ...prev, [key]: value }));
  };


  // Coupon Handlers
  const handleSaveCoupon = async (e) => {
    e.preventDefault();
    try {
      const payload = {
        ...couponForm,
        discountPercentage: Number(couponForm.discountPercentage),
        usageLimit: Number(couponForm.usageLimit) || 0
      };
      if (editingCoupon) {
        await updateCoupon(editingCoupon.id, payload);
      } else {
        await addCoupon(payload);
      }
      setShowCouponModal(false);
      setEditingCoupon(null);
      setCouponForm({ code: '', discountPercentage: '', expiryDate: '', usageLimit: '', status: 'Active' });
      fetchCoupons();
    } catch (error) {
      console.error("Error saving coupon", error);
    }
  };

  const handleDeleteCoupon = async (id) => {
    if(window.confirm('Are you sure you want to delete this coupon?')) {
      await deleteCoupon(id);
      fetchCoupons();
    }
  };

  const openEditCoupon = (coupon) => {
    setEditingCoupon(coupon);
    setCouponForm({
      code: coupon.code,
      discountPercentage: coupon.discountPercentage,
      expiryDate: coupon.expiryDate,
      usageLimit: coupon.usageLimit,
      status: coupon.status
    });
    setShowCouponModal(true);
  };

  return (
    <div className="animate-fade-in">
      <div className="page-header" style={{ marginBottom: '2rem' }}>
        <h1 className="page-title">Subscription & Coupons Management</h1>
      </div>

      {/* Tabs */}
      <div style={{ display: 'flex', gap: '1rem', marginBottom: '2rem', borderBottom: '1px solid var(--color-border)' }}>
        <button 
          onClick={() => setActiveTab('pricing')}
          style={{ 
            padding: '1rem 2rem', 
            background: 'none', 
            border: 'none',
            borderBottom: activeTab === 'pricing' ? '3px solid var(--color-primary)' : '3px solid transparent',
            color: activeTab === 'pricing' ? 'var(--color-primary)' : 'var(--color-text-muted)',
            fontWeight: activeTab === 'pricing' ? '600' : '500',
            cursor: 'pointer',
            display: 'flex',
            alignItems: 'center',
            gap: '0.5rem',
            fontSize: '1rem'
          }}
        >
          <CreditCard size={20} /> Subscription Pricing
        </button>
        <button 
          onClick={() => setActiveTab('coupons')}
          style={{ 
            padding: '1rem 2rem', 
            background: 'none', 
            border: 'none',
            borderBottom: activeTab === 'coupons' ? '3px solid var(--color-primary)' : '3px solid transparent',
            color: activeTab === 'coupons' ? 'var(--color-primary)' : 'var(--color-text-muted)',
            fontWeight: activeTab === 'coupons' ? '600' : '500',
            cursor: 'pointer',
            display: 'flex',
            alignItems: 'center',
            gap: '0.5rem',
            fontSize: '1rem'
          }}
        >
          <Tag size={20} /> Coupon Codes
        </button>
      </div>

      {/* Pricing Tab */}
      {activeTab === 'pricing' && (
        <div style={{ maxWidth: '800px' }}>
          {loadingPricing ? (
            <div style={{ padding: '2rem', textAlign: 'center' }}>Loading pricing data...</div>
          ) : (
            <div className="card">
              <h3 style={{ marginBottom: '1.5rem', color: 'var(--color-secondary)' }}>Whole App Gold Access</h3>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1.5rem', marginBottom: '2.5rem' }}>
                <div className="form-group">
                  <label>6 Months Access Price (₹)</label>
                  <input type="number" className="form-control" value={pricing.app_6_months} onChange={e => handlePricingChange('app_6_months', e.target.value)} />
                </div>
                <div className="form-group">
                  <label>1 Year Access Price (₹)</label>
                  <input type="number" className="form-control" value={pricing.app_1_year} onChange={e => handlePricingChange('app_1_year', e.target.value)} />
                </div>
              </div>

              <h3 style={{ marginBottom: '1.5rem', color: 'var(--color-secondary)' }}>Ask AI Doubts Solver Packs</h3>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '1.5rem', marginBottom: '2rem' }}>
                <div className="form-group">
                  <label>Starter Pack Price (₹)</label>
                  <div style={{ fontSize: '0.75rem', color: 'var(--color-text-muted)', marginBottom: '4px' }}>50 Doubts</div>
                  <input type="number" className="form-control" value={pricing.ai_starter} onChange={e => handlePricingChange('ai_starter', e.target.value)} />
                </div>
                <div className="form-group">
                  <label>Standard Pack Price (₹)</label>
                  <div style={{ fontSize: '0.75rem', color: 'var(--color-text-muted)', marginBottom: '4px' }}>150 Doubts</div>
                  <input type="number" className="form-control" value={pricing.ai_standard} onChange={e => handlePricingChange('ai_standard', e.target.value)} />
                </div>
                <div className="form-group">
                  <label>Pro Pack Price (₹)</label>
                  <div style={{ fontSize: '0.75rem', color: 'var(--color-text-muted)', marginBottom: '4px' }}>500 Doubts</div>
                  <input type="number" className="form-control" value={pricing.ai_pro} onChange={e => handlePricingChange('ai_pro', e.target.value)} />
                </div>
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', borderTop: '1px solid var(--color-border-light)', paddingTop: '1.5rem' }}>
                <button className="btn-primary" onClick={handleSavePricing} disabled={savingPricing}>
                  {savingPricing ? 'Saving...' : 'Save All Pricing'}
                </button>
              </div>
            </div>
          )}
        </div>
      )}

      {/* Coupons Tab */}
      {activeTab === 'coupons' && (
        <div>
          <div style={{ display: 'flex', justifyContent: 'flex-end', marginBottom: '1.5rem' }}>
            <button className="btn-primary" onClick={() => {
              setEditingCoupon(null);
              setCouponForm({ code: '', discountPercentage: '', expiryDate: '', usageLimit: '', status: 'Active' });
              setShowCouponModal(true);
            }}>
              <Plus size={20} /> Add Coupon
            </button>
          </div>

          <div className="card">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Coupon Code</th>
                  <th>Discount (%)</th>
                  <th>Expiry Date</th>
                  <th>Usage Limit</th>
                  <th>Used Count</th>
                  <th>Status</th>
                  <th style={{ textAlign: 'right' }}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {loadingCoupons ? (
                  <tr><td colSpan="7" style={{ textAlign: 'center', padding: '1rem' }}>Loading...</td></tr>
                ) : coupons.length === 0 ? (
                  <tr><td colSpan="7" style={{ textAlign: 'center', padding: '1rem' }}>No coupons found.</td></tr>
                ) : (
                  coupons.map(coupon => (
                    <tr key={coupon.id}>
                      <td style={{ fontWeight: '600' }}>{coupon.code}</td>
                      <td>{coupon.discountPercentage}%</td>
                      <td>{new Date(coupon.expiryDate).toLocaleDateString()}</td>
                      <td>{coupon.usageLimit > 0 ? coupon.usageLimit : 'Unlimited'}</td>
                      <td style={{ fontWeight: '500', color: 'var(--color-primary)' }}>{coupon.usedCount || 0} times</td>
                      <td>
                        <span className={`badge ${coupon.status === 'Active' ? 'badge-success' : 'badge-danger'}`}>
                          {coupon.status}
                        </span>
                      </td>
                      <td style={{ textAlign: 'right' }}>
                        <button className="btn-outline" onClick={() => openEditCoupon(coupon)} style={{ marginRight: '0.5rem', padding: '0.4rem' }}>
                          <Edit2 size={16} />
                        </button>
                        <button className="btn-outline" onClick={() => handleDeleteCoupon(coupon.id)} style={{ padding: '0.4rem', color: 'var(--color-danger)', borderColor: 'var(--color-danger)' }}>
                          <Trash2 size={16} />
                        </button>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Coupon Modal */}
      {showCouponModal && (
        <div className="modal-overlay">
          <div className="modal-content" style={{ width: '500px' }}>
            <div className="modal-header">
              <h3>{editingCoupon ? 'Edit Coupon' : 'Add Coupon'}</h3>
              <button className="modal-close" onClick={() => setShowCouponModal(false)}><XCircle size={24} /></button>
            </div>
            <div className="modal-body">
              <form onSubmit={handleSaveCoupon}>
                <div className="form-group">
                  <label>Coupon Code</label>
                  <input type="text" className="form-control" value={couponForm.code} onChange={(e) => setCouponForm({...couponForm, code: e.target.value.toUpperCase()})} placeholder="e.g. SUMMER50" required />
                </div>
                <div className="form-group">
                  <label>Discount Percentage (%)</label>
                  <input type="number" className="form-control" value={couponForm.discountPercentage} onChange={(e) => setCouponForm({...couponForm, discountPercentage: e.target.value})} max="100" min="1" required />
                </div>
                <div className="form-group">
                  <label>Expiry Date</label>
                  <input type="date" className="form-control" value={couponForm.expiryDate} onChange={(e) => setCouponForm({...couponForm, expiryDate: e.target.value})} required />
                </div>
                <div className="form-group">
                  <label>Usage Limit (0 for unlimited)</label>
                  <input type="number" className="form-control" value={couponForm.usageLimit} onChange={(e) => setCouponForm({...couponForm, usageLimit: e.target.value})} min="0" />
                </div>
                <div className="form-group">
                  <label>Status</label>
                  <select className="form-control" value={couponForm.status} onChange={(e) => setCouponForm({...couponForm, status: e.target.value})}>
                    <option value="Active">Active</option>
                    <option value="Inactive">Inactive</option>
                  </select>
                </div>
                <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '1rem', marginTop: '1.5rem' }}>
                  <button type="button" className="btn-outline" onClick={() => setShowCouponModal(false)}>Cancel</button>
                  <button type="submit" className="btn-primary">Save Coupon</button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}

    </div>
  );
};

export default Subscription;
