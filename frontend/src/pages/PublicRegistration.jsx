import { useState } from 'react';
import { addPublicDonor } from '../services/api';
import { Link } from 'react-router-dom';

const EMPTY_FORM = {
  fullName: '',
  email: '',
  phone: '',
  address: '',
  nearestRailwayStation: '',
  pan: '',
  aadhaar: '',
  panFile: null,
  aadhaarFile: null,
};

export default function PublicRegistration() {
  const [form, setForm] = useState(EMPTY_FORM);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState(false);

  const handleChange = (e) => {
    const { name, value, type, files } = e.target;
    if (type === 'file') {
      setForm(f => ({ ...f, [name]: files[0] }));
    } else {
      setForm(f => ({ ...f, [name]: value }));
    }
    setError('');
    setSuccess(false);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!/^\d{10}$/.test(form.phone.trim())) {
      setError('Phone Number must be exactly 10 digits.');
      return;
    }
    if (!form.address || form.address.trim() === '') {
      setError('Address is required.');
      return;
    }
    if (!form.nearestRailwayStation || form.nearestRailwayStation.trim() === '') {
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
    if (!form.panFile) {
      setError('PAN Card Image upload is required.');
      return;
    }
    if (!form.aadhaarFile) {
      setError('Aadhaar Card Image upload is required.');
      return;
    }
    
    setError('');
    setLoading(true);
    setSuccess(false);
    
    try {
      const formData = new FormData();
      formData.append('fullName', form.fullName);
      if (form.email) formData.append('email', form.email);
      formData.append('mobile', form.phone);
      if (form.address) formData.append('address', form.address);
      if (form.nearestRailwayStation) formData.append('nearestRailwayStation', form.nearestRailwayStation);
      if (form.pan) formData.append('pan', form.pan);
      if (form.aadhaar) formData.append('aadhaar', form.aadhaar);
      if (form.panFile) formData.append('panFile', form.panFile);
      if (form.aadhaarFile) formData.append('aadhaarFile', form.aadhaarFile);

      await addPublicDonor(formData);
      setSuccess(true);
      setForm(EMPTY_FORM);
    } catch (err) {
      setError(
        err.response?.data?.message || err.response?.data?.error || 'Failed to register donor. Please try again.'
      );
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ minHeight: '100vh', padding: '40px 20px', backgroundColor: '#f5f7fa', display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
      <div style={{ maxWidth: '800px', width: '100%' }}>
        <div className="page-header" style={{ textAlign: 'center', marginBottom: '32px' }}>
          <h1 style={{ fontSize: '28px', color: '#2c3e50', marginBottom: '8px' }}>Babariyawad Social Community</h1>
          <h2 style={{ fontSize: '22px', color: '#34495e', fontWeight: 500 }}>Public Donor Registration</h2>
          <p style={{ color: '#666', marginTop: '12px' }}>Welcome! Please complete the form below to securely register yourself as a verified donor.</p>
        </div>

        <div className="card" style={{ boxShadow: '0 8px 30px rgba(0,0,0,0.08)', borderRadius: '12px' }}>
          {success ? (
            <div className="success-box" style={{ marginTop: 0, marginBottom: '24px', textAlign: 'center' }}>
              <h3>🎉 Identity Verified & Registered!</h3>
              <p>Thank you for registering. Your details have been securely submitted to the core database.</p>
              <br/>
              <p>Whenever you make a donation, an admin will now be able to easily log it under your secure profile using your registered phone number!</p>
              <div style={{ display: 'flex', justifyContent: 'center', marginTop: '24px' }}>
                <button className="btn-secondary" onClick={() => setSuccess(false)}>
                  Submit Another Registration
                </button>
              </div>
            </div>
          ) : (
            <form onSubmit={handleSubmit}>
              <div className="form-row">
                <div className="form-group">
                  <label className="form-label">Full Name *</label>
                  <input
                    className="form-input"
                    name="fullName"
                    value={form.fullName}
                    onChange={handleChange}
                    placeholder="e.g. John Doe"
                    required
                  />
                </div>
                <div className="form-group">
                  <label className="form-label">Email Address</label>
                  <input
                    className="form-input"
                    type="email"
                    name="email"
                    value={form.email}
                    onChange={handleChange}
                    placeholder="donor@example.com (optional)"
                  />
                </div>
              </div>

              <div className="form-row">
                <div className="form-group">
                  <label className="form-label">Phone Number *</label>
                  <input
                    className="form-input"
                    name="phone"
                    value={form.phone}
                    onChange={handleChange}
                    placeholder="10-digit mobile number"
                    maxLength="10"
                    required
                  />
                </div>
                <div className="form-group">
                  <label className="form-label">Residential / Billing Address *</label>
                  <input
                    className="form-input"
                    name="address"
                    value={form.address}
                    onChange={handleChange}
                    placeholder="Full address"
                    required
                  />
                </div>
              </div>

              <div className="form-row">
                <div className="form-group">
                  <label className="form-label">PAN Number *</label>
                  <input
                    className="form-input"
                    name="pan"
                    value={form.pan}
                    onChange={handleChange}
                    placeholder="10-character PAN"
                    maxLength="10"
                    required
                  />
                </div>
                <div className="form-group">
                  <label className="form-label">Aadhaar Number *</label>
                  <input
                    className="form-input"
                    name="aadhaar"
                    value={form.aadhaar}
                    onChange={handleChange}
                    placeholder="12-digit Aadhaar"
                    maxLength="12"
                    required
                  />
                </div>
              </div>
              
              <div className="form-row">
                <div className="form-group">
                  <label className="form-label">Nearest Railway Station *</label>
                  <input
                    className="form-input"
                    name="nearestRailwayStation"
                    value={form.nearestRailwayStation}
                    onChange={handleChange}
                    placeholder="e.g. Borivali"
                    required
                  />
                </div>
                <div className="form-group">
                </div>
              </div>

              <div className="form-row">
                <div className="form-group">
                  <label className="form-label">Upload PAN Card Image *</label>
                  <input
                    className="form-input"
                    type="file"
                    name="panFile"
                    accept="image/*,application/pdf"
                    onChange={handleChange}
                    style={{ padding: '8px' }}
                    required
                  />
                </div>
                <div className="form-group">
                  <label className="form-label">Upload Aadhaar Card Image *</label>
                  <input
                    className="form-input"
                    type="file"
                    name="aadhaarFile"
                    accept="image/*,application/pdf"
                    onChange={handleChange}
                    style={{ padding: '8px' }}
                    required
                  />
                </div>
              </div>

              {error && <div className="error-box">{error}</div>}

              <button className="btn-primary" type="submit" disabled={loading} style={{ width: '100%', marginTop: '16px', padding: '14px', fontSize: '16px' }}>
                {loading ? 'Securely Submitting Registration…' : 'Submit Secure Registration'}
              </button>
            </form>
          )}
        </div>

        <div style={{ textAlign: 'center', marginTop: '24px' }}>
          <p style={{ color: '#666', fontSize: '14px' }}>
            Are you an administrator?{' '}
            <Link to="/login" style={{ color: '#4facfe', textDecoration: 'none', fontWeight: 500 }}>
              Login here
            </Link>
          </p>
        </div>
      </div>
    </div>
  );
}
