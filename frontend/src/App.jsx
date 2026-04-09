import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import Login from './pages/Login';
import DonationForm from './pages/DonationForm';
import DonorRegistration from './pages/DonorRegistration';
import PublicRegistration from './pages/PublicRegistration';
import InvoiceLookup from './pages/InvoiceLookup';
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

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<Login />} />
        <Route
          path="/donate"
          element={
            <ProtectedRoute>
              <Layout><DonationForm /></Layout>
            </ProtectedRoute>
          }
        />
        <Route
          path="/register-donor"
          element={
            <ProtectedRoute>
              <Layout><DonorRegistration /></Layout>
            </ProtectedRoute>
          }
        />
        <Route
          path="/invoice"
          element={
            <ProtectedRoute>
              <Layout><InvoiceLookup /></Layout>
            </ProtectedRoute>
          }
        />
        <Route
          path="/donor-lookup"
          element={
            <ProtectedRoute>
              <Layout><DonorLookup /></Layout>
            </ProtectedRoute>
          }
        />
        <Route
          path="/donor-lookup/:phone"
          element={
            <ProtectedRoute>
              <Layout><DonorLookup /></Layout>
            </ProtectedRoute>
          }
        />
        <Route
          path="/donors"
          element={
            <ProtectedRoute>
              <Layout><AllDonors /></Layout>
            </ProtectedRoute>
          }
        />
        <Route path="/" element={<PublicRegistration />} />
        <Route path="/register" element={<PublicRegistration />} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </BrowserRouter>
  );
}
