const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  content: [
    './public/*.html',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/views/**/*.{erb,haml,html,slim}'
  ],
  theme: {
    extend: {
      colors:{
        primary:"rgb(18 18 18)",
        secondary: "#eeb14a",
        'tertiary': "rgb(165 68 29)",
        'input-label': "rgb(238 177 74 / 73%)",
        'nav-backdrop': "rgb(45 45 45)",
        'nav-link-bg':  "rgba(0, 0, 0, .4)"
      },
      fontFamily: {
        sans: ['Inter var', ...defaultTheme.fontFamily.sans],
      }
    }
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/aspect-ratio'),
    require('@tailwindcss/typography'),
    require('@tailwindcss/container-queries')
  ]
}
