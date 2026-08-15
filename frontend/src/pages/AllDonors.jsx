import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { getDonors } from '../services/api';

export default function AllDonors() {
  const [donors, setDonors] = useState([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const navigate = useNavigate();

  useEffect(() => {
    fetchDonors();
  }, []);

  const fetchDonors = async () => {
    setLoading(true);
    try {
      const res = await getDonors();
      setDonors(res.data);
    } catch (err) {
      setError(err.response?.data?.message || 'Failed to fetch donors.');
    } finally {
      setLoading(false);
    }
  };

  const filteredDonors = donors.filter(donor => 
    donor.fullName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    donor.mobile?.includes(searchTerm)
  );

  return (
    <div>
      <div className="page-header">
        <h2>Registered Donors Directory</h2>
        <p>A complete list of all registered donors. Use the search bar to filter by name or phone number.</p>
      </div>

      <div className="card">
        <div className="form-group" style={{ marginBottom: '24px' }}>
          <label className="form-label">Search Donors</label>
          <input
            className="form-input"
            type="text"
            placeholder="Start typing name or phone number..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>

        {loading ? (
          <div style={{ textAlign: 'center', padding: '40px' }}>
            <p style={{ color: 'var(--text-muted)' }}>Loading donor database...</p>
          </div>
        ) : error ? (
          <div className="error-box">{error}</div>
        ) : filteredDonors.length === 0 ? (
          <div style={{ textAlign: 'center', padding: '40px' }}>
            <p style={{ color: 'var(--text-muted)' }}>No donors found matching your search.</p>
          </div>
        ) : (
          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
              <thead>
                <tr style={{ borderBottom: '2px solid var(--border)' }}>
                  <th style={{ padding: '12px', color: 'var(--text-muted)', fontSize: '13px', textTransform: 'uppercase' }}>Full Name</th>
                  <th style={{ padding: '12px', color: 'var(--text-muted)', fontSize: '13px', textTransform: 'uppercase' }}>Phone Number</th>
                  <th style={{ padding: '12px', color: 'var(--text-muted)', fontSize: '13px', textTransform: 'uppercase' }}>Email</th>
                  <th style={{ padding: '12px', color: 'var(--text-muted)', fontSize: '13px', textTransform: 'uppercase', textAlign: 'right' }}>Action</th>
                </tr>
              </thead>
              <tbody>
                {filteredDonors.map((donor) => (
                  <tr key={donor._id} style={{ borderBottom: '1px solid var(--border)' }}>
                    <td style={{ padding: '12px', fontWeight: 600 }}>{donor.fullName}</td>
                    <td style={{ padding: '12px' }}>{donor.mobile}</td>
                    <td style={{ padding: '12px' }}>{donor.email || '-'}</td>
                    <td style={{ padding: '12px', textAlign: 'right' }}>
                      <button 
                        className="btn-secondary" 
                        style={{ padding: '6px 14px', fontSize: '13px' }}
                        onClick={() => navigate(`/donor-lookup/${donor.mobile}`)}
                      >
                        View Profile →
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}
