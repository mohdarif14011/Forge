import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      '/api': {
        target: 'https://privacy-mustiness-showpiece.ngrok-free.dev',
        changeOrigin: true,
        secure: false,
      }
    }
  }
})
