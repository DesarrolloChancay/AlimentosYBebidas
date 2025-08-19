/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./app/templates/**/*.html",
    "./app/static/js/**/*.js",
  ],
  darkMode: 'class', // Esto habilita el modo oscuro basado en clases
  theme: {
    extend: {
      colors: {
        // Puedes personalizar los colores aquí si lo necesitas
      },
    },
  },
  plugins: [],
}
