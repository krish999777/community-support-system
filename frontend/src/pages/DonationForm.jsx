import { useState, useEffect } from 'react';
import { searchDonor, addDonation, downloadReceiptUrl } from '../services/api';

const EMPTY_FORM = {
  fullName: '',
  phone: '',
  email: '',
  address: '',
  nearestRailwayStation: '',
  pan: '',
  aadhaar: '',
  amount: '',
  date: new Date().toISOString().split('T')[0],
  purpose: '',
  mode: 'Cash',
  transactionId: '',
  chequeNumber: '',
  accountNumber: '',
  ifsc: '',
};

export default function DonationForm() {
  const [form, setForm]         = useState(EMPTY_FORM);
  const [lookup, setLookup]     = useState({ status: 'idle', message: '' }); // idle | loading | found | notfound
  const [submitting, setSubmitting] = useState(false);
  const [error, setError]       = useState('');
  const [receipt, setReceipt]   = useState(null);

  /* ── Field change ── */
  const handleChange = (e) => {
    const { name, value } = e.target;
    setForm(f => ({ ...f, [name]: value }));
    
    if (name === 'phone') {
      setLookup({ status: 'idle', message: '' });
      if (value.length < 10) {
        setForm(f => ({ 
          ...f, 
          email: '', 
          address: '', 
          nearestRailwayStation: '', 
          pan: '', 
          aadhaar: '' 
        }));
      }
    }
  };

  /* ── Auto-lookup when phone hits 10 digits ── */
  useEffect(() => {
    if (form.phone.length === 10) {
      handleLookup(form.phone);
    }
  }, [form.phone]);

  /* ── Donor lookup logic ── */
  const handleLookup = async (phone) => {
    setLookup({ status: 'loading', message: 'Checking donor records...' });
    try {
      const res = await searchDonor(phone);
      const donor = res.data;
      if (donor && donor.mobile) {
        setForm(f => ({
          ...f,
          fullName: donor.fullName || f.fullName,
          email: donor.email || '',
          address: donor.address || '',
          nearestRailwayStation: donor.nearestRailwayStation || '',
          pan: donor.pan || '',
          aadhaar: donor.aadhaar || '',
        }));
        setLookup({ status: 'found', message: `✓ Donor found: ${donor.fullName}` });
      } else {
        setLookup({ status: 'notfound', message: '📝 New Donor detected. Please complete registration below.' });
      }
    } catch {
      setLookup({ status: 'notfound', message: '📝 New Donor detected. Please complete registration below.' });
    }
  };

  /* ── Submit ── */
  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    
    // 1. Basic Validations
    if (!/^\d{10}$/.test(form.phone.trim())) {
      setError('Phone Number must be exactly 10 digits.');
      return;
    }

    // 2. Strict Validations for New Donor
    if (lookup.status === 'notfound') {
      if (!form.address.trim()) {
        setError('Address is required for new registration.');
        return;
      }
      if (!form.nearestRailwayStation.trim()) {
        setError('Nearest Railway Station is required.');
        return;
      }
      if (!/^[a-zA-Z0-9]{10}$/.test(form.pan.trim())) {
        setError('PAN Number must be exactly 10 alphanumeric characters.');
        return;
      }
      if (!/^\d{12}$/.test(form.aadhaar.trim())) {
        setError('Aadhaar Number must be exactly 12 digits.');
        return;
      }
    }

    setSubmitting(true);
    try {
      const res = await addDonation({
        ...form,
        amount: Number(form.amount)
      });
      setReceipt({ receiptNo: res.data.receiptNo });
    } catch (err) {
      setError(err.response?.data?.message || err.response?.data?.error || 'Failed to process donation. Please try again.');
    } finally {
      setSubmitting(false);
    }
  };

  const handleReset = () => {
    setForm(EMPTY_FORM);
    setReceipt(null);
    setLookup({ status: 'idle', message: '' });
    setError('');
  };

  return (
    <div className="fade-in">
      <div className="page-header">
        <h2>New Donation Entry</h2>
        <p>Record a contribution and generate a secure receipt.</p>
      </div>

      {receipt ? (
        <div className="card">
          <div className="success-box">
            <h3>🎉 Receipt Generated!</h3>
            <p>Receipt No: <strong>{receipt.receiptNo}</strong></p>
            <div style={{ display: 'flex', gap: '12px', marginTop: '16px' }}>
              <a className="btn-success" href={downloadReceiptUrl(receipt.receiptNo)} download target="_blank" rel="noreferrer">
                ⬇ Download PDF
              </a>
              <button className="btn-secondary" onClick={handleReset}>+ Another Donation</button>
            </div>
          </div>
        </div>
      ) : (
        <div className="card">
          <form onSubmit={handleSubmit}>
            
            {/* Primary Info Row */}
            <div className="form-row">
              <div className="form-group">
                <label className="form-label">Full Name *</label>
                <input
                  className="form-input"
                  name="fullName"
                  value={form.fullName}
                  onChange={handleChange}
                  placeholder="Auto-filled if registered"
                  required
                />
              </div>
              <div className="form-group">
                <label className="form-label">Phone Number *</label>
                <input
                  className="form-input"
                  name="phone"
                  value={form.phone}
                  onChange={handleChange}
                  placeholder="10-digit mobile"
                  maxLength="10"
                  required
                />
              </div>
            </div>

            {/* Lookup Badge */}
            {lookup.status !== 'idle' && (
              <div className={`lookup-badge ${lookup.status === 'found' ? 'lookup-found' : (lookup.status === 'loading' ? '' : 'lookup-new')}`} style={{ marginBottom: '20px' }}>
                {lookup.message}
              </div>
            )}

            {/* Registration Fields - Required if new donor */}
            {lookup.status === 'notfound' && (
              <div className="fade-in" style={{ background: 'rgba(79, 70, 229, 0.03)', padding: '20px', borderRadius: '12px', marginBottom: '24px', border: '1px dashed var(--primary-light)' }}>
                <h4 style={{ fontSize: '14px', marginBottom: '16px', color: 'var(--primary-dark)' }}>Mandatory Registration (New Donor)</h4>
                
                <div className="form-group">
                  <label className="form-label">Email Address</label>
                  <input className="form-input" type="email" name="email" value={form.email} onChange={handleChange} placeholder="Email for receipt" />
                </div>

                <div className="form-group">
                  <label className="form-label">Residential Address *</label>
                  <input 
                    className="form-input" 
                    name="address" 
                    value={form.address} 
                    onChange={handleChange} 
                    placeholder="Full address" 
                    required={lookup.status === 'notfound'}
                  />
                </div>

                <div className="form-row-3">
                  <div className="form-group">
                    <label className="form-label">Nearest Station *</label>
                    <input 
                      className="form-input" 
                      name="nearestRailwayStation" 
                      value={form.nearestRailwayStation} 
                      onChange={handleChange} 
                      placeholder="Station" 
                      required={lookup.status === 'notfound'}
                    />
                  </div>
                  <div className="form-group">
                    <label className="form-label">PAN Number *</label>
                    <input 
                      className="form-input" 
                      name="pan" 
                      value={form.pan} 
                      onChange={handleChange} 
                      placeholder="10 chars" 
                      maxLength="10" 
                      required={lookup.status === 'notfound'}
                    />
                  </div>
                  <div className="form-group">
                    <label className="form-label">Aadhaar Number *</label>
                    <input 
                      className="form-input" 
                      name="aadhaar" 
                      value={form.aadhaar} 
                      onChange={handleChange} 
                      placeholder="12 digits" 
                      maxLength="12" 
                      required={lookup.status === 'notfound'}
                    />
                  </div>
                </div>
              </div>
            )}

            {/* Donation Details - ALWAYS visible */}
            <div className="form-row">
              <div className="form-group">
                <label className="form-label">Donation Amount (₹) *</label>
                <input
                  className="form-input"
                  type="number"
                  name="amount"
                  value={form.amount}
                  onChange={handleChange}
                  placeholder="0"
                  min="1"
                  required
                />
              </div>
              <div className="form-group">
                <label className="form-label">Date *</label>
                <input
                  className="form-input"
                  type="date"
                  name="date"
                  value={form.date}
                  onChange={handleChange}
                  required
                />
              </div>
            </div>

            <div className="form-group">
              <label className="form-label">Purpose *</label>
              <input
                className="form-input"
                name="purpose"
                value={form.purpose}
                onChange={handleChange}
                placeholder="e.g. Building Fund, General"
                required
              />
            </div>

            <div className="form-group">
              <label className="form-label">Payment Mode *</label>
              <select className="form-input" name="mode" value={form.mode} onChange={handleChange} required>
                <option value="Cash">Cash</option>
                <option value="UPI">UPI</option>
                <option value="NEFT">NEFT</option>
                <option value="Cheque">Cheque</option>
              </select>
            </div>

            {/* Conditional Fields */}
            {(form.mode === 'UPI' || form.mode === 'NEFT') && (
              <div className="form-group fade-in">
                <label className="form-label">Transaction ID *</label>
                <input className="form-input" name="transactionId" value={form.transactionId} onChange={handleChange} placeholder="Ref ID" required />
              </div>
            )}

            {form.mode === 'Cheque' && (
              <div className="form-row-3 fade-in">
                <div className="form-group">
                  <label className="form-label">Cheque No *</label>
                  <input className="form-input" name="chequeNumber" value={form.chequeNumber} onChange={handleChange} placeholder="123456" required />
                </div>
                <div className="form-group">
                  <label className="form-label">Bank Acc No *</label>
                  <input className="form-input" name="accountNumber" value={form.accountNumber} onChange={handleChange} placeholder="Account No" required />
                </div>
                <div className="form-group">
                  <label className="form-label">IFSC Code *</label>
                  <input className="form-input" name="ifsc" value={form.ifsc} onChange={handleChange} placeholder="IFSC" required />
                </div>
              </div>
            )}

            {error && <div className="error-box" style={{ marginTop: '20px' }}>{error}</div>}

            <button className="btn-primary" type="submit" disabled={submitting} style={{ marginTop: '24px' }}>
              {submitting ? 'Processing...' : '🧾 Generate Invoice & Receipt'}
            </button>

          </form>
        </div>
      )}
    </div>
  );
}
