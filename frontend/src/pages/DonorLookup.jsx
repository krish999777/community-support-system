import { useState } from 'react';
import { getDonorProfile, downloadReceiptUrl } from '../services/api';

export default function DonorLookup() {
  const [mobile, setMobile] = useState('');
  const [donor, setDonor] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleSearch = async (e) => {
    e.preventDefault();
    if (!mobile.trim()) return;
    
    setLoading(true);
    setError('');
    setDonor(null);

    try {
      const res = await getDonorProfile(mobile.trim());
      setDonor(res.data);
    } catch (err) {
      setError(err.response?.data?.message || 'Donor not found or an error occurred.');
    } finally {
      setLoading(false);
    }
  };

  const renderDocument = (fileObj, title) => {
    if (!fileObj || !fileObj.base64) return <p style={{ color: '#666' }}>No {title} uploaded.</p>;

    if (fileObj.contentType === 'application/pdf') {
      return (
        <iframe
          src={fileObj.base64}
          title={title}
          style={{ width: '100%', height: '300px', border: '1px solid #ddd', borderRadius: '4px' }}
        />
      );
    }
    
    // Assume image
    return (
      <img
        src={fileObj.base64}
        alt={title}
        style={{ maxWidth: '100%', maxHeight: '300px', borderRadius: '4px', border: '1px solid #ddd' }}
      />
    );
  };

  return (
    <div>
      <div className="page-header">
        <h2>Global Donor Profile Lookup</h2>
        <p>Search a donor by phone number to view their full profile, attached documents, and complete donation history.</p>
      </div>

      <div className="card">
        <form onSubmit={handleSearch} style={{ display: 'flex', gap: '12px', alignItems: 'flex-end', marginBottom: '16px' }}>
          <div className="form-group" style={{ flex: 1, minWidth: '250px', margin: 0 }}>
            <label className="form-label">Donor Phone Number</label>
            <input
              className="form-input"
              value={mobile}
              onChange={(e) => setMobile(e.target.value)}
              placeholder="e.g. 9998887776"
              required
            />
          </div>
          <button className="btn-primary" type="submit" disabled={loading} style={{ margin: 0, width: 'auto', whiteSpace: 'nowrap' }}>
            {loading ? 'Searching…' : 'Search Profile'}
          </button>
        </form>
        {error && <div className="error-box">{error}</div>}
      </div>

      {donor && (
        <div className="fade-in" style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
          
          {/* Detailed Profile Grid */}
          <div className="card">
            <h3>📝 Personal Information</h3>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '16px', marginTop: '16px' }}>
              <div><strong>Full Name:</strong><br/>{donor.fullName || '-'}</div>
              <div><strong>Phone Number:</strong><br/>{donor.mobile || '-'}</div>
              <div><strong>Email Address:</strong><br/>{donor.email || '-'}</div>
              <div><strong>PAN Number:</strong><br/>{donor.pan || '-'}</div>
              <div><strong>Aadhaar Number:</strong><br/>{donor.aadhaar || '-'}</div>
              <div><strong>Address:</strong><br/>{donor.address || '-'}</div>
            </div>
          </div>

          {/* Documents display */}
          <div className="card">
            <h3>📄 Attached Documents</h3>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: '24px', marginTop: '16px' }}>
              <div>
                <strong style={{ display: 'block', marginBottom: '8px' }}>PAN Card Proxy</strong>
                {renderDocument(donor.panFile, 'PAN Card')}
              </div>
              <div>
                <strong style={{ display: 'block', marginBottom: '8px' }}>Aadhaar Card Proxy</strong>
                {renderDocument(donor.aadhaarFile, 'Aadhaar Card')}
              </div>
            </div>
          </div>

          {/* Donations Table */}
          <div className="card">
            <h3>💰 Donation Ledger</h3>
            {donor.donations && donor.donations.length > 0 ? (
              <div style={{ overflowX: 'auto', marginTop: '16px' }}>
                <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
                  <thead>
                    <tr style={{ borderBottom: '2px solid #eee' }}>
                      <th style={{ padding: '12px' }}>Date</th>
                      <th style={{ padding: '12px' }}>Receipt No</th>
                      <th style={{ padding: '12px' }}>Amount</th>
                      <th style={{ padding: '12px' }}>Mode</th>
                      <th style={{ padding: '12px' }}>Purpose</th>
                      <th style={{ padding: '12px' }}>Invoice</th>
                    </tr>
                  </thead>
                  <tbody>
                    {donor.donations.reverse().map((d, i) => (
                      <tr key={i} style={{ borderBottom: '1px solid #eee' }}>
                        <td style={{ padding: '12px' }}>{new Date(d.date).toLocaleDateString('en-IN')}</td>
                        <td style={{ padding: '12px' }}><strong>{d.receiptNo}</strong></td>
                        <td style={{ padding: '12px' }}>₹{d.amount}</td>
                        <td style={{ padding: '12px' }}>{d.mode}</td>
                        <td style={{ padding: '12px' }}>{d.purpose || '-'}</td>
                        <td style={{ padding: '12px' }}>
                          <a href={downloadReceiptUrl(d.receiptNo)} target="_blank" rel="noreferrer" style={{ color: '#4CAF50', textDecoration: 'none', fontWeight: 600 }}>
                            Download
                          </a>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            ) : (
              <p style={{ color: '#666', marginTop: '16px' }}>No donations found for this donor.</p>
            )}
          </div>

        </div>
      )}
    </div>
  );
}
