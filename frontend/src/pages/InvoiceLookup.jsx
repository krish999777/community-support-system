import { useState } from 'react';
import { getReceiptByNumber, downloadReceiptUrl } from '../services/api';

export default function InvoiceLookup() {
  const [receiptNo, setReceiptNo] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [invoiceData, setInvoiceData] = useState(null);

  const handleSearch = async (e) => {
    e.preventDefault();
    if (!receiptNo.trim()) return;

    setLoading(true);
    setError('');
    setInvoiceData(null);

    // Format receipt number to always start with RCPT- if they just typed the numbers
    let query = receiptNo.trim().toUpperCase();
    if (!query.startsWith('RCPT-')) {
        // If it's pure numbers, prepend RCPT-
        if (/^\d+$/.test(query)) {
            query = `RCPT-${query}`;
        }
    }

    try {
      const res = await getReceiptByNumber(query);
      setInvoiceData(res.data);
    } catch (err) {
      setError(
        err.response?.data?.message || err.response?.data?.error || 'Invoice not found. Please check the receipt number and try again.'
      );
    } finally {
      setLoading(false);
    }
  };

  const handleReset = () => {
    setReceiptNo('');
    setInvoiceData(null);
    setError('');
  };

  return (
    <div>
      <div className="page-header">
        <h2>Invoice Lookup</h2>
        <p>Enter a receipt number to retrieve the donation details and download the official PDF invoice.</p>
      </div>

      <div className="card" style={{ maxWidth: '600px', margin: '0 auto', marginBottom: '24px' }}>
        <form onSubmit={handleSearch} style={{ display: 'flex', gap: '12px' }}>
          <input
            className="form-input"
            value={receiptNo}
            onChange={(e) => setReceiptNo(e.target.value)}
            placeholder="e.g. RCPT-1234567890"
            style={{ marginBottom: 0 }}
          />
          <button 
            className="btn-primary" 
            type="submit" 
            disabled={loading || !receiptNo.trim()}
            style={{ width: 'auto', whiteSpace: 'nowrap' }}
          >
            {loading ? 'Searching…' : '🔍 Search'}
          </button>
        </form>
        {error && <div className="error-box" style={{ marginTop: '16px' }}>{error}</div>}
      </div>

      {invoiceData && (
        <div className="card fade-in" style={{ maxWidth: '600px', margin: '0 auto' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', borderBottom: '1px solid var(--border-color)', paddingBottom: '16px', marginBottom: '16px' }}>
                <div>
                    <h3 style={{ margin: '0 0 8px 0', fontSize: '1.25rem' }}>Receipt Details</h3>
                    <div style={{ color: 'var(--text-light)', fontSize: '0.875rem' }}>
                        No. <strong>{invoiceData.receipt.receiptNo}</strong>
                    </div>
                </div>
                <div style={{ textAlign: 'right' }}>
                    <div style={{ fontSize: '1.5rem', fontWeight: 'bold', color: 'var(--primary-color)' }}>
                        ₹{invoiceData.receipt.amount?.toLocaleString('en-IN')}
                    </div>
                    <div style={{ color: 'var(--success-color)', fontSize: '0.875rem', fontWeight: '500' }}>
                        Paid via {invoiceData.receipt.mode}
                    </div>
                </div>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px', marginBottom: '24px' }}>
                <div>
                    <div style={{ fontSize: '0.75rem', textTransform: 'uppercase', color: 'var(--text-light)', fontWeight: '600', marginBottom: '4px' }}>Donor Name</div>
                    <div style={{ fontWeight: '500' }}>{invoiceData.donorName}</div>
                </div>
                <div>
                    <div style={{ fontSize: '0.75rem', textTransform: 'uppercase', color: 'var(--text-light)', fontWeight: '600', marginBottom: '4px' }}>Email Address</div>
                    <div style={{ fontWeight: '500' }}>{invoiceData.email || 'N/A'}</div>
                </div>
                <div>
                    <div style={{ fontSize: '0.75rem', textTransform: 'uppercase', color: 'var(--text-light)', fontWeight: '600', marginBottom: '4px' }}>Date</div>
                    <div style={{ fontWeight: '500' }}>{new Date(invoiceData.receipt.date).toLocaleDateString('en-IN')}</div>
                </div>
                <div>
                    <div style={{ fontSize: '0.75rem', textTransform: 'uppercase', color: 'var(--text-light)', fontWeight: '600', marginBottom: '4px' }}>Purpose</div>
                    <div style={{ fontWeight: '500' }}>{invoiceData.receipt.purpose || 'General'}</div>
                </div>
            </div>

            <div style={{ display: 'flex', gap: '12px' }}>
                <a
                    className="btn-success"
                    href={downloadReceiptUrl(invoiceData.receipt.receiptNo)}
                    download
                    target="_blank"
                    rel="noreferrer"
                    style={{ flex: 1, textAlign: 'center' }}
                >
                    ⬇ Download PDF Invoice
                </a>
                <button className="btn-secondary" onClick={handleReset}>
                    Clear
                </button>
            </div>
        </div>
      )}
    </div>
  );
}
