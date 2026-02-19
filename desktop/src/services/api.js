import axios from 'axios';

const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL,
  // No forzamos Content-Type global para dejar que axios elija (json o formdata)
});

// Interceptor para añadir el token a cada petición
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
    console.log("Interceptor: Token found?", !!token); // DEBUG
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
      console.log("Interceptor: Header added"); // DEBUG
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Interceptor para manejar errores (ej. token expirado)
api.interceptors.response.use(
  (response) => response,
  (error) => {
    console.error("API Error:", error.response || error.message);
    
    // Desactivamos logout automático temporalmente para debug
    /*
    if (error.response && error.response.status === 401) {
      localStorage.removeItem('token');
      window.location.href = '/login';
    }
    */
    return Promise.reject(error);
  }
);

export default api;
