/** @type {import('tailwindcss').Config} */
export default {
  content: ['./src/**/*.{astro,html,js,jsx,md,mdx,svelte,ts,tsx,vue}'],
  theme: {
    extend: {
      colors: {
        // Paper-like book aesthetic palette
        paper: '#FBF9F5',
        ink: '#2C2C2C',
        'ink-light': '#555555',
        'ink-muted': '#888888',
        'paper-border': '#E8E3D8',
        'paper-accent': '#F0EBE0',
        accent: '#8B6914',
        'accent-light': '#B8942A',
      },
      fontFamily: {
        // Serif for body text — book-like reading experience
        serif: [
          '"Noto Serif JP"',
          '"Source Serif 4"',
          'Georgia',
          '"Times New Roman"',
          'serif',
        ],
        // Sans-serif for UI elements and headings
        sans: [
          '"Noto Sans JP"',
          '"Inter"',
          'system-ui',
          '-apple-system',
          'sans-serif',
        ],
        // Monospace for code
        mono: [
          '"JetBrains Mono"',
          '"Fira Code"',
          '"Cascadia Code"',
          'ui-monospace',
          'monospace',
        ],
      },
      typography: (theme) => ({
        DEFAULT: {
          css: {
            '--tw-prose-body': theme('colors.ink'),
            '--tw-prose-headings': theme('colors.ink'),
            '--tw-prose-lead': theme('colors.ink-light'),
            '--tw-prose-links': theme('colors.accent'),
            '--tw-prose-bold': theme('colors.ink'),
            '--tw-prose-counters': theme('colors.ink-muted'),
            '--tw-prose-bullets': theme('colors.ink-muted'),
            '--tw-prose-hr': theme('colors.paper-border'),
            '--tw-prose-quotes': theme('colors.ink'),
            '--tw-prose-quote-borders': theme('colors.accent'),
            '--tw-prose-captions': theme('colors.ink-muted'),
            '--tw-prose-code': theme('colors.ink'),
            '--tw-prose-pre-code': '#e2e8f0',
            '--tw-prose-pre-bg': '#1e2433',
            '--tw-prose-th-borders': theme('colors.paper-border'),
            '--tw-prose-td-borders': theme('colors.paper-border'),
            maxWidth: 'none',
            fontSize: '1.0625rem',
            lineHeight: '1.875',
            // Headings
            h1: {
              fontFamily: theme('fontFamily.sans').join(', '),
              fontWeight: '700',
              letterSpacing: '-0.02em',
            },
            h2: {
              fontFamily: theme('fontFamily.sans').join(', '),
              fontWeight: '600',
              borderBottom: `1px solid ${theme('colors.paper-border')}`,
              paddingBottom: '0.5rem',
            },
            h3: {
              fontFamily: theme('fontFamily.sans').join(', '),
              fontWeight: '600',
            },
            // Inline code style
            'code::before': { content: '""' },
            'code::after': { content: '""' },
            code: {
              backgroundColor: theme('colors.paper-accent'),
              borderRadius: '0.25rem',
              padding: '0.1em 0.35em',
              fontFamily: theme('fontFamily.mono').join(', '),
              fontSize: '0.875em',
            },
            // Block quote — like a margin note
            blockquote: {
              fontStyle: 'italic',
              borderLeftColor: theme('colors.accent'),
              borderLeftWidth: '3px',
              paddingLeft: '1.25rem',
              color: theme('colors.ink-light'),
            },
            // Links
            a: {
              color: theme('colors.accent'),
              textDecoration: 'underline',
              textDecorationColor: theme('colors.accent-light'),
              textUnderlineOffset: '3px',
              '&:hover': {
                color: theme('colors.accent-light'),
              },
            },
          },
        },
      }),
    },
  },
  plugins: [require('@tailwindcss/typography')],
};
