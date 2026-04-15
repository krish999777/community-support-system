import { Link, useNavigate, useLocation } from 'react-router-dom';

export default function Navbar() {
  const navigate = useNavigate();
  const location = useLocation();
  const username = localStorage.getItem('username');
  const role = localStorage.getItem('role');

  const handleLogout = () => {
    localStorage.removeItem('token');
    localStorage.removeItem('username');
    localStorage.removeItem('role');
    navigate('/login');
  };

  const isAdmin = role === 'admin';

  return (
    <nav className="navbar">
      <div className="navbar-brand">
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
      
      <div className="navbar-links">
        {isAdmin && (
          <Link to="/dashboard" className={`nav-link ${location.pathname === '/dashboard' ? 'active' : ''}`}>
            Dashboard
          </Link>
        )}
        
        <Link to="/donate" className={`nav-link ${location.pathname === '/donate' ? 'active' : ''}`}>
          New Donation
        </Link>

        {isAdmin && (
          <>
            <Link to="/register-donor" className={`nav-link ${location.pathname === '/register-donor' ? 'active' : ''}`}>
              Register Donor
            </Link>
            <Link to="/invoice" className={`nav-link ${location.pathname === '/invoice' ? 'active' : ''}`}>
              Invoice Lookup
            </Link>
            <Link to="/donor-lookup" className={`nav-link ${location.pathname.startsWith('/donor-lookup') ? 'active' : ''}`}>
              Donor Lookup
            </Link>
            <Link to="/donors" className={`nav-link ${location.pathname === '/donors' ? 'active' : ''}`}>
              All Donors
            </Link>
            <Link to="/manage-pins" className={`nav-link ${location.pathname === '/manage-pins' ? 'active' : ''}`}>
              Access Management
            </Link>
          </>
        )}
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
