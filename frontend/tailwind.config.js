/** @type {import('tailwindcss').Config} */
module.exports = {
    darkMode: ["class"],
    content: [
    "./src/**/*.{js,jsx,ts,tsx}",
    "./public/index.html"
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['-apple-system', 'BlinkMacSystemFont', '"SF Pro Display"', '"Sora"', '"Inter"', 'system-ui', 'sans-serif'],
        display: ['"Sora"', '"Inter"', 'system-ui', 'sans-serif'],
        chrome: ['"Sora"', '"Inter"', 'system-ui', 'sans-serif'],
        mono: ['"JetBrains Mono"', 'ui-monospace', 'monospace'],
      },
      borderRadius: {
        lg: 'var(--radius)',
        md: 'calc(var(--radius) - 4px)',
        sm: 'calc(var(--radius) - 8px)',
        '2xl': '20px',
        '3xl': '28px',
      },
      colors: {
        background: 'hsl(var(--background))',
        foreground: 'hsl(var(--foreground))',
        // Milli Brand Palette — locked to design system spec.
        volt: {
          DEFAULT: '#00E5FF',       // Electric Cyan — primary accent
          hover: '#00B4C2',         // Deep Teal — hover / secondary
        },
        cyan: {
          300: '#7AF6FF',
          400: '#00E5FF',
          500: '#00B4C2',
          600: '#008593',
        },
        chrome: {
          100: '#FFFFFF',           // Alpine White
          200: '#E6E7EA',
          300: '#C0C0C0',           // Polished Silver
          400: '#8A8F98',
          500: '#5B6068',
        },
        // Layered darks — matches the design system swatches exactly.
        obsidian: '#07090B',        // Deep Black
        charcoal: '#0E1114',        // Carbon Charcoal
        surface: '#161A1F',         // Card surface (from the design system)
        hairline: '#232830',        // Thin metallic border tone
        danger: '#FF5C67',
        success: '#39D98A',
        warning: '#FFB547',
        info: '#00E5FF',
        card: {
          DEFAULT: 'hsl(var(--card))',
          foreground: 'hsl(var(--card-foreground))'
        },
        popover: {
          DEFAULT: 'hsl(var(--popover))',
          foreground: 'hsl(var(--popover-foreground))'
        },
        primary: {
          DEFAULT: 'hsl(var(--primary))',
          foreground: 'hsl(var(--primary-foreground))'
        },
        secondary: {
          DEFAULT: 'hsl(var(--secondary))',
          foreground: 'hsl(var(--secondary-foreground))'
        },
        muted: {
          DEFAULT: 'hsl(var(--muted))',
          foreground: 'hsl(var(--muted-foreground))'
        },
        accent: {
          DEFAULT: 'hsl(var(--accent))',
          foreground: 'hsl(var(--accent-foreground))'
        },
        destructive: {
          DEFAULT: 'hsl(var(--destructive))',
          foreground: 'hsl(var(--destructive-foreground))'
        },
        border: 'hsl(var(--border))',
        input: 'hsl(var(--input))',
        ring: 'hsl(var(--ring))',
        chart: {
          '1': 'hsl(var(--chart-1))',
          '2': 'hsl(var(--chart-2))',
          '3': 'hsl(var(--chart-3))',
          '4': 'hsl(var(--chart-4))',
          '5': 'hsl(var(--chart-5))'
        }
      },
      keyframes: {
        'accordion-down': { from: { height: '0' }, to: { height: 'var(--radix-accordion-content-height)' } },
        'accordion-up': { from: { height: 'var(--radix-accordion-content-height)' }, to: { height: '0' } },
        'pulse-volt': {
          '0%, 100%': { boxShadow: '0 0 0 0 rgba(0, 229, 255, 0.55)' },
          '50%': { boxShadow: '0 0 0 16px rgba(0, 229, 255, 0)' }
        },
        'glow-pulse': {
          '0%, 100%': { boxShadow: '0 0 24px rgba(0, 229, 255, 0.18), inset 0 0 24px rgba(0, 229, 255, 0.04)' },
          '50%': { boxShadow: '0 0 36px rgba(0, 229, 255, 0.3), inset 0 0 32px rgba(0, 229, 255, 0.08)' }
        },
        'ticker': {
          '0%': { transform: 'translateY(8px)', opacity: '0' },
          '100%': { transform: 'translateY(0)', opacity: '1' }
        }
      },
      animation: {
        'accordion-down': 'accordion-down 0.2s ease-out',
        'accordion-up': 'accordion-up 0.2s ease-out',
        'pulse-volt': 'pulse-volt 2.2s infinite',
        'glow-pulse': 'glow-pulse 3.5s ease-in-out infinite',
        'ticker': 'ticker 220ms ease-out',
      }
    }
  },
  plugins: [require("tailwindcss-animate")],
};
