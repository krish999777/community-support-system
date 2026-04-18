import axios from 'axios';

const API_URL = 'http://localhost:5001';

const API = axios.create({
  baseURL: API_URL,
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
export const loginWithPin = (pin) => API.post('/api/admin/login-pin', { pin });
export const getDashboardStats = () => API.get('/api/admin/stats');
export const exportDonationsUrl = () => `${API_URL}/api/admin/export?token=${localStorage.getItem('token')}`;

// PIN Management
export const getPins = () => API.get('/api/admin/pins');
export const createPin = (data) => API.post('/api/admin/pins', data);
export const deletePin = (id) => API.delete(`/api/admin/pins/${id}`);

// Donor
export const searchDonor = (query) => API.get(`/api/donor/search/${encodeURIComponent(query)}`);
export const getDonors = () => API.get('/api/donor/all');
export const getDonorProfile = (mobile) => API.get(`/api/donor/profile/${encodeURIComponent(mobile)}`);
export const updateDonorProfile = (mobile, data) => API.put(`/api/donor/profile/${encodeURIComponent(mobile)}`, data, {
  headers: {
    'Content-Type': 'multipart/form-data'
  }
});
export const deleteDonorProfile = (mobile) => API.delete(`/api/donor/profile/${encodeURIComponent(mobile)}`);
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
