import { defineConfig } from 'astro/config';
import mdx from '@astrojs/mdx';
import tailwind from '@astrojs/tailwind';
import remarkMath from 'remark-math';
import rehypeKatex from 'rehype-katex';

// https://astro.build/config
export default defineConfig({
  integrations: [
    mdx(),
    tailwind({
      // Apply Tailwind base styles globally
      applyBaseStyles: true,
    }),
  ],

  markdown: {
    // Shiki syntax highlighting
    syntaxHighlight: 'shiki',
    shikiConfig: {
      // Dark theme for code blocks
      theme: 'github-dark',
      // Enable word wrap for long lines
      wrap: true,
    },
    // Math rendering plugins
    remarkPlugins: [remarkMath],
    rehypePlugins: [
      [
        rehypeKatex,
        {
          // Render errors as text rather than throwing
          throwOnError: false,
          // Allow display math environments
          displayMode: false,
        },
      ],
    ],
  },

  // Content collections
  content: {
    collections: {
      chapters: {
        type: 'content',
      },
    },
  },
});
