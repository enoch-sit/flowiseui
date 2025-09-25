import { defineConfig, loadEnv } from 'vite'
import react from '@vitejs/plugin-react'

// https://vitejs.dev/config/
export default defineConfig(({ mode }) => {
  // Load env file based on `mode` in the current working directory.
  const env = loadEnv(mode, process.cwd(), '')

  return {
    plugins: [react()],
    base: env.VITE_BASE_PATH || '/projectui/',
    server: {
      host: '0.0.0.0',
      port: parseInt(env.VITE_PORT) || 3000
    },
    preview: {
      host: '0.0.0.0',
      allowedHosts: 'all',
      port: parseInt(env.VITE_PORT) || 3002
    },
    build: {
      outDir: 'dist'
    }
  }
})