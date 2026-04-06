import { Link, useNavigate, useLocation } from 'react-router-dom';

export default function Navbar() {
  const navigate = useNavigate();
  const location = useLocation();
  const username = localStorage.getItem('username');

  const handleLogout = () => {
    localStorage.removeItem('token');
    localStorage.removeItem('username');
    navigate('/login');
  };

  return (
    <nav className="navbar">
      <div className="navbar-brand">
        <div className="navbar-logo">BSC</div>
        <div>
          <div className="navbar-title">Babariyawad Social Community</div>
          <div className="navbar-subtitle">Donor Management System</div>
        </div>
      </div>
      <div className="navbar-links">
        <Link to="/donate" className={`nav-link ${location.pathname === '/donate' ? 'active' : ''}`}>
          New Donation
        </Link>
        <Link to="/register-donor" className={`nav-link ${location.pathname === '/register-donor' ? 'active' : ''}`}>
          Register Donor
        </Link>
        <Link to="/invoice" className={`nav-link ${location.pathname === '/invoice' ? 'active' : ''}`}>
          Invoice Lookup
        </Link>
        <Link to="/donor-lookup" className={`nav-link ${location.pathname === '/donor-lookup' ? 'active' : ''}`}>
          Donor Lookup
        </Link>
      </div>
      <div className="navbar-right">
        <span className="navbar-user">👤 {username}</span>
        <button className="btn-logout" onClick={handleLogout}>Logout</button>
      </div>
    </nav>
  );
}
