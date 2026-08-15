import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { addDonor } from '../services/api';
import { processFileUpload } from '../utils/fileUpload';

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

export default function DonorRegistration() {
  const [form, setForm] = useState(EMPTY_FORM);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState(false);
  
  const navigate = useNavigate();

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
      const processedPanFile = await processFileUpload(form.panFile);
      const processedAadhaarFile = await processFileUpload(form.aadhaarFile);

      const formData = new FormData();
      formData.append('fullName', form.fullName);
      if (form.email) formData.append('email', form.email);
      formData.append('mobile', form.phone);
      if (form.address) formData.append('address', form.address);
      if (form.nearestRailwayStation) formData.append('nearestRailwayStation', form.nearestRailwayStation);
      if (form.pan) formData.append('pan', form.pan);
      if (form.aadhaar) formData.append('aadhaar', form.aadhaar);
      if (processedPanFile) formData.append('panFile', processedPanFile);
      if (processedAadhaarFile) formData.append('aadhaarFile', processedAadhaarFile);

      await addDonor(formData);
      setSuccess(true);
      setForm(EMPTY_FORM);
    } catch (err) {
      console.error("Registration Error: ", err);
      setError(
        err.response?.data?.message || err.response?.data?.error || err.message || 'Failed to register donor. Please try again.'
      );
    } finally {
      setLoading(false);
    }
  };

  return (
    <div>
      <div className="page-header">
        <h2>Register New Donor</h2>
        <p>Add a new donor to the database with their identity details to enable invoice generation.</p>
      </div>

      <div className="card">
        {success ? (
          <div className="success-box" style={{ marginTop: 0, marginBottom: '24px' }}>
            <h3>🎉 Donor Registered Successfully!</h3>
            <p>The donor can now be looked up by email on the Donation Entry page.</p>
            <div style={{ display: 'flex', gap: '12px', flexWrap: 'wrap' }}>
              <button className="btn-success" onClick={() => navigate('/donate')}>
                → Go to Donation Entry
              </button>
              <button className="btn-secondary" onClick={() => setSuccess(false)}>
                + Register Another Donor
              </button>
            </div>
          </div>
        ) : (
          <form onSubmit={handleSubmit}>
            {/* ── Row 1: Name & Email ── */}
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

            {/* ── Row 2: Phone & Address ── */}
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

            {/* ── Row 3: PAN, Aadhaar & Station Strings ── */}
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
                {/* Empty block for equal spacing */}
              </div>
            </div>

            {/* ── Row 4: PAN & Aadhaar Files ── */}
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

            <button className="btn-primary" type="submit" disabled={loading}>
              {loading ? 'Registering Donor…' : 'Save Donor Details'}
            </button>
          </form>
        )}
      </div>
    </div>
  );
}
