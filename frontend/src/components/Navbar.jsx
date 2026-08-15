import { useState } from 'react';
import { Link, useNavigate, useLocation } from 'react-router-dom';

export default function Navbar() {
  const navigate = useNavigate();
  const location = useLocation();
  let role = null;
  let username = 'User';
  try {
    const token = localStorage.getItem('token');
    if (token) {
      const payload = JSON.parse(atob(token.split('.')[1]));
      role = payload.role;
      username = payload.label || 'User';
    }
  } catch (err) {
    console.error('Failed to parse token payload');
  }

  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  const handleLogout = () => {
    localStorage.removeItem('token');
    navigate('/login');
  };

  const isAdmin = role === 'admin';

  return (
    <nav className="navbar">
      <div className="navbar-brand">
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
          <div className="navbar-logo" style={{ overflow: 'hidden', padding: 0, background: 'none' }}>
            <img 
              src="/WhatsApp Image 2026-04-09 at 14.10.43.jpeg" 
              alt="Logo" 
              style={{ width: '100%', height: '100%', objectFit: 'cover' }} 
            />
          </div>
          <div>
            <div className="navbar-title">Samastha Darji Samaaj Babariyawad</div>
            <div className="navbar-subtitle">Donor Management System</div>
          </div>
        </div>
        <button className="mobile-menu-btn" onClick={() => setMobileMenuOpen(!mobileMenuOpen)}>
          ☰
        </button>
      </div>
      
      <div className={`navbar-links ${mobileMenuOpen ? 'mobile-open' : ''}`}>
        {isAdmin && (
          <Link to="/dashboard" className={`nav-link ${location.pathname === '/dashboard' ? 'active' : ''}`}>
            Dashboard
          </Link>
        )}
        
        <div className="nav-dropdown">
          <span className={`nav-link ${['/donate', '/invoice'].includes(location.pathname) ? 'active' : ''}`} style={{ cursor: 'pointer' }}>
            Donations ▾
          </span>
          <div className="nav-dropdown-content">
            <Link to="/donate" className="nav-link">New Donation</Link>
            {isAdmin && <Link to="/invoice" className="nav-link">Invoice Lookup</Link>}
          </div>
        </div>

        {isAdmin && (
          <>
            <div className="nav-dropdown">
              <span className={`nav-link ${['/register-donor', '/donor-lookup', '/donors'].some(p => location.pathname.startsWith(p)) ? 'active' : ''}`} style={{ cursor: 'pointer' }}>
                Donors ▾
              </span>
              <div className="nav-dropdown-content">
                <Link to="/register-donor" className="nav-link">Register Donor</Link>
                <Link to="/donor-lookup" className="nav-link">Donor Lookup</Link>
                <Link to="/donors" className="nav-link">All Donors</Link>
              </div>
            </div>

            <Link to="/manage-pins" className={`nav-link ${location.pathname === '/manage-pins' ? 'active' : ''}`}>
              Access Management
            </Link>
          </>
        )}
        <button 
          className="btn-logout" 
          onClick={handleLogout} 
          style={{ marginTop: '10px', display: 'none' }} // Hidden by default, shown via CSS on mobile
        >
          Logout
        </button>
      </div>

      <div className="navbar-right">
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', marginRight: '15px' }}>
          <span className="navbar-user" style={{ fontSize: '13px', fontWeight: 700 }}>📍 {username}</span>
          <span style={{ fontSize: '10px', textTransform: 'uppercase', color: 'var(--primary)', opacity: 0.8 }}>{role}</span>
        </div>
        <button className="btn-logout" onClick={handleLogout}>Logout</button>
      </div>
    </nav>
  );
}
