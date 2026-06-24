/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: '#E8007D',
        'primary-soft': '#fce8f3',
        'bg-base': '#fdf5f9',
        line: '#f0d6e8',
        muted: '#64748b',
      },
      fontFamily: {
        sans: ['Inter', 'Segoe UI', 'Arial', 'sans-serif'],
      },
      borderRadius: {
        '2xl': '24px',
        '3xl': '28px',
      },
      boxShadow: {
        knevo: '0 10px 30px rgba(232, 0, 125, 0.08)',
      },
    },
  },
  plugins: [],
}

