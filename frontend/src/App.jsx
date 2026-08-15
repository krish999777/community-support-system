import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import Login from './pages/Login';
import DonationForm from './pages/DonationForm';
import DonorRegistration from './pages/DonorRegistration';
import PublicRegistration from './pages/PublicRegistration';
import InvoiceLookup from './pages/InvoiceLookup';
import Dashboard from './pages/Dashboard';
import PinManagement from './pages/PinManagement';
import DonorLookup from './pages/DonorLookup';
import AllDonors from './pages/AllDonors';
import ProtectedRoute from './components/ProtectedRoute';
import Navbar from './components/Navbar';

function Layout({ children }) {
  return (
    <>
      <Navbar />
      <main className="main-content">{children}</main>
    </>
  );
}

// Helper to restrict access based on role securely by reading the JWT payload
function RoleRoute({ children, allowedRoles }) {
  let role = null;
  try {
    const token = localStorage.getItem('token');
    if (token) {
      const payload = JSON.parse(atob(token.split('.')[1]));
      role = payload.role;
    }
  } catch (err) {
    console.error('Failed to parse token payload');
  }

  if (!role || !allowedRoles.includes(role)) {
    return <Navigate to="/donate" replace />;
  }
  return children;
}
export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<Login />} />
        
        {/* Public Route */}
        <Route path="/" element={<PublicRegistration />} />
        <Route path="/register" element={<PublicRegistration />} />

        {/* Protected Routes */}
        <Route
          path="/donate"
          element={
            <ProtectedRoute>
              <Layout><DonationForm /></Layout>
            </ProtectedRoute>
          }
        />

        {/* Admin-Only Routes */}
        <Route
          path="/dashboard"
          element={
            <ProtectedRoute>
              <RoleRoute allowedRoles={['admin']}>
                <Layout><Dashboard /></Layout>
              </RoleRoute>
            </ProtectedRoute>
          }
        />
        <Route
          path="/register-donor"
          element={
            <ProtectedRoute>
              <RoleRoute allowedRoles={['admin']}>
                <Layout><DonorRegistration /></Layout>
              </RoleRoute>
            </ProtectedRoute>
          }
        />
        <Route
          path="/invoice"
          element={
            <ProtectedRoute>
              <RoleRoute allowedRoles={['admin']}>
                <Layout><InvoiceLookup /></Layout>
              </RoleRoute>
            </ProtectedRoute>
          }
        />
        <Route
          path="/donor-lookup"
          element={
            <ProtectedRoute>
              <RoleRoute allowedRoles={['admin']}>
                <Layout><DonorLookup /></Layout>
              </RoleRoute>
            </ProtectedRoute>
          }
        />
        <Route
          path="/donor-lookup/:phone"
          element={
            <ProtectedRoute>
              <RoleRoute allowedRoles={['admin']}>
                <Layout><DonorLookup /></Layout>
              </RoleRoute>
            </ProtectedRoute>
          }
        />
        <Route
          path="/donors"
          element={
            <ProtectedRoute>
              <RoleRoute allowedRoles={['admin']}>
                <Layout><AllDonors /></Layout>
              </RoleRoute>
            </ProtectedRoute>
          }
        />
        <Route
          path="/manage-pins"
          element={
            <ProtectedRoute>
              <RoleRoute allowedRoles={['admin']}>
                <Layout><PinManagement /></Layout>
              </RoleRoute>
            </ProtectedRoute>
          }
        />

        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </BrowserRouter>
  );
}
