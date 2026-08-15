import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { getDonorProfile, downloadReceiptUrl, updateDonorProfile, deleteDonorProfile } from '../services/api';
import { processFileUpload } from '../utils/fileUpload';

export default function DonorLookup() {
  const { phone } = useParams();
  const navigate = useNavigate();
  const [mobile, setMobile] = useState(phone || '');
  const [donor, setDonor] = useState(null);
  const [loading, setLoading] = useState(false);
  const [updateLoading, setUpdateLoading] = useState(false);
  const [deleteLoading, setDeleteLoading] = useState(false);
  const [error, setError] = useState('');
  
  // Edit states
  const [isEditing, setIsEditing] = useState(false);
  const [editForm, setEditForm] = useState({});

  const fetchProfile = async (num) => {
    if (!num.trim()) return;
    setLoading(true);
    setError('');
    setDonor(null);
    try {
      const res = await getDonorProfile(num.trim());
      setDonor(res.data);
    } catch (err) {
      setError(err.response?.data?.message || 'Donor not found or an error occurred.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (phone) {
      fetchProfile(phone);
    }
  }, [phone]);

  const handleSearch = (e) => {
    e.preventDefault();
    if (isEditing) setIsEditing(false);
    fetchProfile(mobile);
  };

  const handleEditClick = () => {
    setEditForm({
      fullName: donor.fullName,
      email: donor.email || '',
      mobile: donor.mobile,
      address: donor.address || '',
      nearestRailwayStation: donor.nearestRailwayStation || '',
      pan: donor.pan || '',
      aadhaar: donor.aadhaar || '',
      panFile: null,
      aadhaarFile: null
    });
    setIsEditing(true);
  };

  const handleDeleteClick = async () => {
    if (!window.confirm(`⚠️ WARNING: Are you sure you want to PERMANENTLY delete ${donor.fullName} and all their records? This action cannot be undone.`)) {
      return;
    }

    setDeleteLoading(true);
    setError('');
    try {
      await deleteDonorProfile(donor.mobile);
      alert('Donor deleted successfully.');
      setDonor(null);
      setMobile('');
      navigate('/donor-lookup', { replace: true });
    } catch (err) {
      setError(err.response?.data?.message || 'Failed to delete donor. They may have associated records that prevent deletion.');
    } finally {
      setDeleteLoading(false);
    }
  };

  const handleEditChange = (e) => {
    const { name, value } = e.target;
    setEditForm(prev => ({ ...prev, [name]: value }));
  };

  const handleFileChange = (e) => {
    const { name, files } = e.target;
    setEditForm(prev => ({ ...prev, [name]: files[0] }));
  };

  const handleSave = async (e) => {
    e.preventDefault();
    setUpdateLoading(true);
    setError('');
    try {
      const formData = new FormData();
      for (const key of Object.keys(editForm)) {
        if (key === 'panFile' || key === 'aadhaarFile') {
          if (editForm[key] !== null) {
            const processedFile = await processFileUpload(editForm[key]);
            if (processedFile) formData.append(key, processedFile);
          }
        } else if (editForm[key] !== null) {
          formData.append(key, editForm[key]);
        }
      }

      await updateDonorProfile(donor.mobile, formData);
      setIsEditing(false);
      // If mobile changed, update the URL and state
      if (editForm.mobile !== donor.mobile) {
        navigate(`/donor-lookup/${editForm.mobile}`, { replace: true });
      } else {
        fetchProfile(donor.mobile);
      }
    } catch (err) {
      setError(err.response?.data?.message || 'Failed to update donor profile.');
    } finally {
      setUpdateLoading(false);
    }
  };

  const handleCancel = () => {
    setIsEditing(false);
    setError('');
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
        <form onSubmit={handleSearch} style={{ display: 'flex', flexWrap: 'wrap', gap: '12px', alignItems: 'flex-end', marginBottom: '16px' }}>
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
        {error && <div className="error-box" style={{ marginBottom: '16px' }}>{error}</div>}
      </div>

      {donor && (
        <div className="fade-in" style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
          
          {/* Detailed Profile Grid */}
          <div className="card">
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
              <h3 style={{ margin: 0 }}>📝 Personal Information</h3>
              {!isEditing && (
                <div style={{ display: 'flex', gap: '8px' }}>
                  <button className="btn-secondary" onClick={handleEditClick} style={{ padding: '6px 16px', fontSize: '13px' }}>
                    Edit Profile
                  </button>
                  <button className="btn-logout" onClick={handleDeleteClick} disabled={deleteLoading} style={{ padding: '6px 16px', fontSize: '13px', border: '1px solid #ef4444' }}>
                    {deleteLoading ? 'Deleting...' : 'Delete Donor'}
                  </button>
                </div>
              )}
            </div>

            {isEditing ? (
              <form onSubmit={handleSave}>
                <div className="form-row">
                  <div className="form-group">
                    <label className="form-label">Full Name</label>
                    <input className="form-input" name="fullName" value={editForm.fullName} onChange={handleEditChange} required />
                  </div>
                  <div className="form-group">
                    <label className="form-label">Phone Number</label>
                    <input className="form-input" name="mobile" value={editForm.mobile} onChange={handleEditChange} maxLength="10" required />
                  </div>
                </div>
                <div className="form-row">
                  <div className="form-group">
                    <label className="form-label">Email Address</label>
                    <input className="form-input" type="email" name="email" value={editForm.email} onChange={handleEditChange} />
                  </div>
                  <div className="form-group">
                    <label className="form-label">Nearest Railway Station</label>
                    <input className="form-input" name="nearestRailwayStation" value={editForm.nearestRailwayStation} onChange={handleEditChange} required />
                  </div>
                </div>
                <div className="form-row">
                  <div className="form-group">
                    <label className="form-label">PAN Number</label>
                    <input className="form-input" name="pan" value={editForm.pan} onChange={handleEditChange} maxLength="10" required />
                  </div>
                  <div className="form-group">
                    <label className="form-label">Aadhaar Number</label>
                    <input className="form-input" name="aadhaar" value={editForm.aadhaar} onChange={handleEditChange} maxLength="12" required />
                  </div>
                </div>
                <div className="form-group">
                  <label className="form-label">Residential Address</label>
                  <input className="form-input" name="address" value={editForm.address} onChange={handleEditChange} required />
                </div>

                <div style={{ marginTop: '24px', paddingTop: '16px', borderTop: '1px solid var(--border)' }}>
                  <h4 style={{ marginBottom: '16px' }}>Update Documents (Keep empty to preserve current files)</h4>
                  <div className="form-row">
                    <div className="form-group">
                      <label className="form-label">New PAN Card Image</label>
                      <input className="form-input" type="file" name="panFile" accept="image/*,application/pdf" onChange={handleFileChange} />
                    </div>
                    <div className="form-group">
                      <label className="form-label">New Aadhaar Card Image</label>
                      <input className="form-input" type="file" name="aadhaarFile" accept="image/*,application/pdf" onChange={handleFileChange} />
                    </div>
                  </div>
                </div>

                <div style={{ display: 'flex', gap: '12px', marginTop: '16px' }}>
                  <button className="btn-success" type="submit" disabled={updateLoading} style={{ flex: 1 }}>
                    {updateLoading ? 'Saving Changes...' : 'Save Changes'}
                  </button>
                  <button className="btn-logout" type="button" onClick={handleCancel} disabled={updateLoading} style={{ padding: '10px 24px' }}>
                    Cancel
                  </button>
                </div>
              </form>
            ) : (
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '16px', marginTop: '16px' }}>
                <div><strong>Full Name:</strong><br/>{donor.fullName || '-'}</div>
                <div><strong>Phone Number:</strong><br/>{donor.mobile || '-'}</div>
                <div><strong>Email Address:</strong><br/>{donor.email || '-'}</div>
                <div><strong>PAN Number:</strong><br/>{donor.pan || '-'}</div>
                <div><strong>Aadhaar Number:</strong><br/>{donor.aadhaar || '-'}</div>
                <div><strong>Address:</strong><br/>{donor.address || '-'}</div>
                <div><strong>Nearest Railway Station:</strong><br/>{donor.nearestRailwayStation || '-'}</div>
              </div>
            )}
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
                    {[...donor.donations].reverse().map((d, i) => (
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
