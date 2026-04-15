import { useState, useEffect } from 'react';
import { getPins, createPin, deletePin } from '../services/api';

export default function PinManagement() {
  const [pins, setPins] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [newPin, setNewPin] = useState({ pin: '', label: '', role: 'admin' });
  const [success, setSuccess] = useState('');

  const fetchPins = async () => {
    try {
      const res = await getPins();
      setPins(res.data);
    } catch (err) {
      setError('Failed to load PINs.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchPins();
  }, []);

  const handleCreate = async (e) => {
    e.preventDefault();
    if (newPin.pin.length !== 4) return setError('PIN must be 4 digits');
    
    setError('');
    setSuccess('');
    try {
      await createPin(newPin);
      setSuccess(`PIN created for "${newPin.label}" successfully.`);
      setNewPin({ pin: '', label: '', role: 'admin' });
      fetchPins();
    } catch (err) {
      setError(err.response?.data?.message || 'Failed to create PIN.');
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Are you sure you want to revoke this access PIN?')) return;
    try {
      await deletePin(id);
      fetchPins();
    } catch (err) {
      setError('Failed to delete PIN.');
    }
  };

  return (
    <div className="fade-in">
      <div className="page-header">
        <h2>Access PIN Management</h2>
        <p>Control who can log in and manage the collection database.</p>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 2fr', gap: '30px', alignItems: 'start' }}>
        {/* Create Form */}
        <div className="card">
          <h3 style={{ marginBottom: '20px' }}>Create New Access</h3>
          <form onSubmit={handleCreate}>
            <div className="form-group">
              <label className="form-label">PIN Label (Name/Office)</label>
              <input
                className="form-input"
                type="text"
                placeholder="e.g. Main Office Admin"
                value={newPin.label}
                onChange={(e) => setNewPin({ ...newPin, label: e.target.value })}
                required
              />
            </div>
            <div className="form-group">
              <label className="form-label">4-Digit Security PIN</label>
              <input
                className="form-input"
                type="password"
                maxLength="4"
                placeholder="****"
                value={newPin.pin}
                onChange={(e) => setNewPin({ ...newPin, pin: e.target.value.replace(/\D/g, '') })}
                required
              />
            </div>
            <div className="form-group">
              <label className="form-label">System Role</label>
              <select
                className="form-input"
                value={newPin.role}
                onChange={(e) => setNewPin({ ...newPin, role: e.target.value })}
              >
                <option value="admin">Admin (Full Access)</option>
                <option value="operator">Operator (Donated Entry Only)</option>
              </select>
            </div>
            {error && <div className="error-box" style={{ marginBottom: '20px' }}>{error}</div>}
            {success && <div className="success-box" style={{ marginBottom: '20px' }}>{success}</div>}
            <button className="btn-primary" type="submit" style={{ width: '100%' }}>
              Register PIN
            </button>
          </form>
        </div>

        {/* PIN List */}
        <div className="card">
          <h3 style={{ marginBottom: '20px' }}>Active Access Codes</h3>
          {loading ? (
            <p>Loading active access codes...</p>
          ) : (
            <div style={{ overflowX: 'auto' }}>
              <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                <thead>
                  <tr style={{ borderBottom: '2px solid var(--border)', textAlign: 'left' }}>
                    <th style={{ padding: '12px' }}>Label</th>
                    <th style={{ padding: '12px' }}>Role</th>
                    <th style={{ padding: '12px' }}>Created</th>
                    <th style={{ padding: '12px' }}>Action</th>
                  </tr>
                </thead>
                <tbody>
                  {pins.length === 0 ? (
                    <tr><td colSpan="4" style={{ padding: '20px', textAlign: 'center', color: 'var(--text-muted)' }}>No custom PINs created yet.</td></tr>
                  ) : (
                    pins.map((p) => (
                      <tr key={p._id} style={{ borderBottom: '1px solid var(--border)' }}>
                        <td style={{ padding: '12px', fontWeight: 600 }}>{p.label}</td>
                        <td style={{ padding: '12px' }}>
                          <span style={{ 
                            background: p.role === 'admin' ? '#eef2ff' : '#fef3c7',
                            color: p.role === 'admin' ? '#4f46e5' : '#d97706',
                            padding: '4px 8px',
                            borderRadius: '4px',
                            fontSize: '12px',
                            textTransform: 'uppercase',
                            fontWeight: 700
                          }}>
                            {p.role}
                          </span>
                        </td>
                        <td style={{ padding: '12px', fontSize: '13px', color: 'var(--text-muted)' }}>
                          {new Date(p.createdAt).toLocaleDateString()}
                        </td>
                        <td style={{ padding: '12px' }}>
                          <button 
                            onClick={() => handleDelete(p._id)}
                            style={{ background: 'none', border: 'none', color: '#ef4444', cursor: 'pointer', fontWeight: 600 }}
                          >
                            Revoke
                          </button>
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
