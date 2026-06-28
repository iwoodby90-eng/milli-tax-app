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
        sans: ['"Inter"', '"IBM Plex Sans"', 'system-ui', 'sans-serif'],
        display: ['"Audiowide"', '"Outfit"', 'system-ui', 'sans-serif'],
        chrome: ['"Orbitron"', '"Outfit"', 'system-ui', 'sans-serif'],
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
        // Brand: cyan / chrome aesthetic
        volt: {
          DEFAULT: '#00E5FF',
          hover: '#00C8E0',
        },
        cyan: {
          400: '#00E5FF',
          500: '#00C8E0',
          600: '#00A0B8',
        },
        chrome: {
          100: '#F4F8FA',
          200: '#D8E0E5',
          300: '#A8B3BA',
          400: '#7A8590',
          500: '#5B6670',
        },
        obsidian: '#03060A',
        surface: '#0A1015',
        hairline: '#1A2530',
        danger: '#FF4D6A',
        success: '#00FFB0',
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
