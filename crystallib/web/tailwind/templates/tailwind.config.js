const colors = require('tailwindcss/colors')

module.exports = {
  content: [@{content_paths}],
  darkMode: false,
  important: true,
  theme: {
    fontSize: {
        'xs': '.75rem',
        'sm': '.875rem',
        'tiny': '.875rem',
        'base': '1rem',
        'md': '1.05rem',
        'lg': '1.125rem',
        'xl': '1.25rem',
        '2xl': '1.5rem',
        '3xl': '1.875rem',
        '4xl': '2.25rem',
        '5xl': '3rem',
        '6xl': '4rem',
        '7xl': '5rem',
    },
    colors: {
      transparent: 'transparent',
      white: '#ffffff',
      black: '#000000',
      gray: colors.gray,
      slate: colors.slate,
      stone: colors.stone,
      zinc: colors.zinc,
      yellow: colors.yellow,
      orange: colors.orange,
      sky: colors.sky,
      blue: {
        '100': '#bbeeff',
        '200': '#00aaff',
        '300': '#0088ff',
        '400': '#0033ff',
        '500': '#0000ff',
        '600': '#0000bb',
        '700': '#0000aa',
        '800': '#000088',
        '900': '#000066',
      },
      
    },
    extend: {
        screens: {
          '2xl': '1450px',
        },
      },
  },
  plugins: [], // if we add forms, do it here
}