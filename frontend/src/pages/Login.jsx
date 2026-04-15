import { useState, useRef, useEffect } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { loginWithPin } from '../services/api';

export default function Login() {
  const [pin, setPin] = useState(['', '', '', '']);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const inputRefs = [useRef(), useRef(), useRef(), useRef()];
  const navigate = useNavigate();

  useEffect(() => {
    // Focus first input on mount
    inputRefs[0].current.focus();
  }, []);

  const handleChange = (index, value) => {
    if (isNaN(value)) return; // Only allow numbers
    
    const newPin = [...pin];
    newPin[index] = value.substring(value.length - 1);
    setPin(newPin);

    // Auto-focus next input
    if (value && index < 3) {
      inputRefs[index + 1].current.focus();
    }
  };

  const handleKeyDown = (index, e) => {
    if (e.key === 'Backspace' && !pin[index] && index > 0) {
      inputRefs[index - 1].current.focus();
    }
  };

  const handlePaste = (e) => {
    e.preventDefault();
    const pasteData = e.clipboardData.getData('text').slice(0, 4);
    if (!/^\d+$/.test(pasteData)) return;

    const newPin = [...pin];
    pasteData.split('').forEach((char, i) => {
      if (i < 4) newPin[i] = char;
    });
    setPin(newPin);
    
    // Focus the appropriate input after paste
    const nextIndex = Math.min(pasteData.length, 3);
    inputRefs[nextIndex].current.focus();
  };

  const handleSubmit = async (e) => {
    if (e) e.preventDefault();
    const pinString = pin.join('');
    if (pinString.length !== 4) return;

    setLoading(true);
    setError('');
    try {
      const res = await loginWithPin(pinString);
      localStorage.setItem('token', res.data.token);
      localStorage.setItem('username', res.data.username);
      localStorage.setItem('role', res.data.role);

      if (res.data.role === 'operator') {
        navigate('/donate');
      } else {
        navigate('/dashboard');
      }
    } catch (err) {
      setError(err.response?.data?.message || 'Login failed. Invalid PIN.');
      setPin(['', '', '', '']);
      inputRefs[0].current.focus();
    } finally {
      setLoading(false);
    }
  };

  // Trigger submit when all fields are filled
  useEffect(() => {
    if (pin.every(digit => digit !== '')) {
      handleSubmit();
    }
  }, [pin]);

  return (
    <div className="login-bg">
      <div className="login-card">
        <div style={{ position: 'relative', width: '70px', height: '70px', margin: '0 auto 20px', overflow: 'hidden', borderRadius: '15px' }}>
          <img src="/WhatsApp Image 2026-04-09 at 14.10.43.jpeg" alt="Logo" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
        </div>
        <h1 className="login-title">Samastha Darji Samaaj Babariyawad</h1>
        <p className="login-subtitle">Secured Administrator Portal</p>

        <form onSubmit={handleSubmit} className="login-form">
          <div style={{ display: 'flex', justifyContent: 'center', gap: '12px', margin: '30px 0' }}>
            {pin.map((digit, index) => (
              <input
                key={index}
                ref={inputRefs[index]}
                type="text"
                inputMode="numeric"
                maxLength="1"
                value={digit}
                onChange={(e) => handleChange(index, e.target.value)}
                onKeyDown={(e) => handleKeyDown(index, e)}
                onPaste={handlePaste}
                style={{
                  width: '50px',
                  height: '60px',
                  fontSize: '24px',
                  textAlign: 'center',
                  borderRadius: '12px',
                  border: '2px solid var(--border)',
                  background: 'var(--surface-2)',
                  color: 'var(--text)',
                  transition: 'all 0.3s ease'
                }}
                className="pin-input-box"
              />
            ))}
          </div>

          <p style={{ textAlign: 'center', fontSize: '14px', color: 'rgba(255,255,255,0.6)', marginBottom: '20px' }}>
            Enter your 4-digit access code
          </p>

          {error && <div className="error-box" style={{ marginBottom: '20px' }}>{error}</div>}

          <button 
            className="btn-primary" 
            type="submit" 
            disabled={loading || pin.join('').length !== 4}
            style={{ width: '100%', padding: '14px', borderRadius: '12px', fontWeight: 600 }}
          >
            {loading ? 'Verifying PIN…' : 'Unlock Portal'}
          </button>
        </form>

        <div className="login-footer" style={{ marginTop: '24px', textAlign: 'center' }}>
          <Link to="/" style={{ color: 'rgba(255,255,255,0.8)', textDecoration: 'none', fontSize: '14px' }}>
            ← Back to Public Registration
          </Link>
        </div>
      </div>
    </div>
  );
}
