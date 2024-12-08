/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "login.html",
    "alogin.html",
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
