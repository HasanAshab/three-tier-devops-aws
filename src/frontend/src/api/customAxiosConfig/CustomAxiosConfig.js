import axios from "axios";

const config = {
  development: {
    baseUrl: "http://localhost:8080",
  },
  production: {
    baseUrl: "http://api.three-tier-app.com",
  },
}
  
// axios instance for making requests
const axiosInstance = axios.create({
  baseURL: config[process.env.NODE_ENV].baseUrl,
});

// request interceptor for adding token
axiosInstance.interceptors.request.use((config) => {
  // add token to request headers
  config.headers["Authorization"] = localStorage.getItem("token");
  return config;
});

export default axiosInstance;
