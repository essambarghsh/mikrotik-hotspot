/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./components/**/*.html",
    "./support/**/*.html",
    "login.html",
    "alogin.html",
    "header.html",
    "footer.html",
    "pos.html",
    "app.js",
    "loadComponents.js",
  ],
  theme: {
    extend: {
      textColor: {
  			skin: {
  				primary: 'var(--primary-color)',
  				primary_dark: 'var(--primary-dark-color)',
  			}
  		},
  		backgroundColor: {
  			skin: {
  				primary: 'var(--primary-color)',
  				primary_dark: 'var(--primary-dark-color)',
  			}
  		},
  		borderColor: {
  			skin: {
  				primary: 'var(--primary-color)',
  				primary_dark: 'var(--primary-dark-color)',
  			}
  		},
    },
    container: {
      center: true,
      padding: "1rem",
      screens: {
        sm: "100%",
        md: "100%",
        lg: "100%",
        xl: "1240px",
        "2xl": "1360px",
      },
    },
  },
  plugins: [],
};
