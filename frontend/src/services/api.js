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

// Donor
export const searchDonor = (query) => API.get(`/api/donor/search/${encodeURIComponent(query)}`);
export const getDonorProfile = (mobile) => API.get(`/api/donor/profile/${encodeURIComponent(mobile)}`);
export const addDonor = (data) => API.post('/api/donor/add', data, {
  headers: {
    'Content-Type': 'multipart/form-data'
  }
});

// Receipts
export const addDonation = (data) => API.post('/api/receipt/donate', data);
export const getReceiptByNumber = (receiptNo) => API.get(`/api/receipt/receipt/${receiptNo}`);
export const downloadReceiptUrl = (receiptNo) => `http://localhost:5001/api/receipt/download/${receiptNo}`;
