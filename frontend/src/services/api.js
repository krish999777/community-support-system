import axios from 'axios';

const API = axios.create({
  baseURL: 'http://localhost:5001',
});

// Attach JWT to every request
API.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Auth
export const loginAdmin = (data) => API.post('/api/admin/login', data);
export const getDashboardStats = () => API.get('/api/admin/stats');
export const exportDonationsUrl = () => `http://localhost:5001/api/admin/export?token=${localStorage.getItem('token')}`;

// Donor
export const searchDonor = (query) => API.get(`/api/donor/search/${encodeURIComponent(query)}`);
export const getDonors = () => API.get('/api/donor/all');
export const getDonorProfile = (mobile) => API.get(`/api/donor/profile/${encodeURIComponent(mobile)}`);
export const updateDonorProfile = (mobile, data) => API.put(`/api/donor/profile/${encodeURIComponent(mobile)}`, data, {
  headers: {
    'Content-Type': 'multipart/form-data'
  }
});
export const addDonor = (data) => API.post('/api/donor/add', data, {
  headers: {
    'Content-Type': 'multipart/form-data'
  }
});
export const addPublicDonor = (data) => axios.post('http://localhost:5001/api/donor/add', data, {
  headers: {
    'Content-Type': 'multipart/form-data'
  }
});

// Receipts
export const addDonation = (data) => API.post('/api/receipt/donate', data);
export const getReceiptByNumber = (receiptNo) => API.get(`/api/receipt/receipt/${receiptNo}`);
export const downloadReceiptUrl = (receiptNo) => `http://localhost:5001/api/receipt/download/${receiptNo}`;
