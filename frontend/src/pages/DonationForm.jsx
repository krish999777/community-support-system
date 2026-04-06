import { useState, useCallback } from 'react';
import { searchDonor, addDonation, downloadReceiptUrl } from '../services/api';

const EMPTY_FORM = {
  fullName: '',
  phone: '',
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
  const [lookup, setLookup]     = useState({ status: 'idle', message: '' }); // idle | found | notfound
  const [submitting, setSubmitting] = useState(false);
  const [error, setError]       = useState('');
  const [receipt, setReceipt]   = useState(null); // { receiptNo }

  /* ── Field change ── */
  const handleChange = (e) => {
    const { name, value } = e.target;
    setForm(f => ({ ...f, [name]: value }));
    if (name === 'phone') setLookup({ status: 'idle', message: '' });
  };

  /* ── Donor lookup on blur of email ── */
  const handleLookup = useCallback(async (query) => {
    if (!query || query.trim().length < 5) return;
    try {
      const res = await searchDonor(query.trim());
      const donor = res.data;
      if (donor && donor.mobile) {
        setForm(f => ({
          ...f,
          fullName: donor.fullName || f.fullName,
        }));
        setLookup({ status: 'found', message: `✓ Donor found: ${donor.fullName}` });
      } else {
        setLookup({ status: 'notfound', message: '⚠️ Donor not found! Please register this donor first.' });
      }
    } catch {
      setLookup({ status: 'notfound', message: '⚠️ Donor not found! Please register this donor first.' });
    }
  }, []);

  /* ── Submit ── */
  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setSubmitting(true);
    try {
      const res = await addDonation({
        fullName: form.fullName,
        phone:    form.phone,
        amount:   Number(form.amount),
        mode:     form.mode,
        purpose:  form.purpose,
        date:     form.date,
        transactionId: form.transactionId,
        chequeNumber: form.chequeNumber,
        accountNumber: form.accountNumber,
        ifsc: form.ifsc,
      });
      setReceipt({ receiptNo: res.data.receiptNo });
    } catch (err) {
      setError(err.response?.data?.message || err.response?.data?.error || 'Failed to generate invoice. Please try again.');
    } finally {
      setSubmitting(false);
    }
  };

  /* ── New donation ── */
  const handleReset = () => {
    setForm(EMPTY_FORM);
    setReceipt(null);
    setLookup({ status: 'idle', message: '' });
    setError('');
  };

  return (
    <div>
      <div className="page-header">
        <h2>New Donation Entry</h2>
        <p>Enter the donor's Phone Number to fetch their details. Donors must be registered first.</p>
      </div>

      {/* ── Success state ── */}
      {receipt ? (
        <div className="card">
          <div className="success-box">
            <h3>🎉 Invoice Generated Successfully!</h3>
            <p>
              Receipt No: <strong>{receipt.receiptNo}</strong><br />
              A copy has been sent to the donor's email address.
            </p>
            <div style={{ display: 'flex', gap: '12px', flexWrap: 'wrap' }}>
              <a
                className="btn-success"
                href={downloadReceiptUrl(receipt.receiptNo)}
                download
                target="_blank"
                rel="noreferrer"
              >
                ⬇ Download Invoice PDF
              </a>
              <button className="btn-secondary" onClick={handleReset}>
                + New Donation
              </button>
            </div>
          </div>
        </div>
      ) : (
        <div className="card">
          <form onSubmit={handleSubmit}>

            {/* ── Row 1: Name & Phone ── */}
            <div className="form-row">
              <div className="form-group">
                <label className="form-label">Full Name *</label>
                <input
                  className="form-input"
                  name="fullName"
                  value={form.fullName}
                  onChange={handleChange}
                  placeholder="Auto-filled if donor exists"
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
                  onBlur={e => e.target.value && handleLookup(e.target.value)}
                  placeholder="10-digit mobile number"
                  required
                />
              </div>
            </div>

            {/* Lookup badge */}
            {lookup.status !== 'idle' && (
              <div className={`lookup-badge ${lookup.status === 'found' ? 'lookup-found' : 'lookup-new'}`}>
                {lookup.message}
              </div>
            )}

            {/* ── Row 2: Amount & Date ── */}
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

            {/* ── Row 3: Purpose ── */}
            <div className="form-row">
              <div className="form-group">
                <label className="form-label">Purpose</label>
                <input
                  className="form-input"
                  name="purpose"
                  value={form.purpose}
                  onChange={handleChange}
                  placeholder="e.g. Education Fund, General"
                />
              </div>
              <div className="form-group">
                {/* Empty block for equal spacing */}
              </div>
            </div>

            {/* ── Payment Mode ── */}
            <div className="form-group" style={{ marginBottom: (form.mode === 'UPI' || form.mode === 'NEFT' || form.mode === 'Cheque') ? '16px' : '24px' }}>
              <label className="form-label">Payment Mode *</label>
              <select
                className="form-input"
                name="mode"
                value={form.mode}
                onChange={handleChange}
                required
              >
                <option value="Cash">Cash</option>
                <option value="UPI">UPI</option>
                <option value="NEFT">NEFT</option>
                <option value="Cheque">Cheque</option>
              </select>
            </div>

            {/* ── Conditional Payment Fields ── */}
            {(form.mode === 'UPI' || form.mode === 'NEFT') && (
              <div className="form-group fade-in">
                <label className="form-label">Transaction ID *</label>
                <input
                  className="form-input"
                  name="transactionId"
                  value={form.transactionId}
                  onChange={handleChange}
                  placeholder="Enter UPI / NEFT Transaction ID"
                  required
                />
              </div>
            )}

            {form.mode === 'Cheque' && (
              <div className="form-row fade-in">
                <div className="form-group">
                  <label className="form-label">Cheque Number *</label>
                  <input
                    className="form-input"
                    name="chequeNumber"
                    value={form.chequeNumber}
                    onChange={handleChange}
                    placeholder="e.g. 123456"
                    required
                  />
                </div>
                <div className="form-group">
                  <label className="form-label">Account Number *</label>
                  <input
                    className="form-input"
                    name="accountNumber"
                    value={form.accountNumber}
                    onChange={handleChange}
                    placeholder="Bank Account Number"
                    required
                  />
                </div>
                <div className="form-group">
                  <label className="form-label">IFSC Code *</label>
                  <input
                    className="form-input"
                    name="ifsc"
                    value={form.ifsc}
                    onChange={handleChange}
                    placeholder="e.g. HDFC0001234"
                    required
                  />
                </div>
              </div>
            )}

            {error && <div className="error-box">{error}</div>}

            <button className="btn-primary" type="submit" disabled={submitting || lookup.status !== 'found' || !form.phone}>
              {submitting ? 'Generating Invoice…' : '🧾 Generate Invoice & Send Receipt'}
            </button>
          </form>
        </div>
      )}
    </div>
  );
}
