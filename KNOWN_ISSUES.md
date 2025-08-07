## Known CI Errors

- High-severity CVE in both frontend and backend  
- Lint errors in both frontend and backend  

> These are inherited from the original repository. Addressing them is the responsibility of the maintainers or future developers.

---

## Deployment Workaround: React Dev Server in Production

⚠️ **Not recommended for production**  
The current `Dockerfile` for the frontend uses `react-scripts start` (Webpack Dev Server) instead of a proper static file server. This setup is used **only as a workaround** to inject environment variables (e.g., `REACT_APP_API_URL`) **at runtime**.

### Why this workaround is used:
React's static build (`npm run build`) inlines environment variables **at build time**, making it impossible to set values like `REACT_APP_API_URL` during container runtime without additional hacks.

### Known issues with this setup:
- Hot reload and watch mode are enabled by default.
- High memory usage and performance issues in production.
- Not suitable for caching, compression, or serving static assets efficiently.
- Webpack Dev Server is not designed for secure, production-grade deployments.

### Mitigation:
- We have an alternate `Dockerfile.recommended` that uses `npm run build` and a proper static server (e.g., Nginx).


Developers are advised to use `Dockerfile.recommended` for actual production deployment and avoid relying on the dev server in prod-like setups.

