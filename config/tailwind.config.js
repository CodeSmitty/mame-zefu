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
        primary:"rgb(29 32 34)",
        secondary: "#eeb14a",
        'tertiary-color': "rgb(165 68 29)",
        'input-label': "rgb(238 177 74 / 73%)"
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
