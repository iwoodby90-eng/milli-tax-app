# Milli Apple-Grade Visual Standard

Milli should feel like a private financial instrument, not a neon concept dashboard.

## Hierarchy

1. The user's available balance, protected taxes, and next required action are always the strongest elements.
2. Decorative chrome, glow, and glass effects must never compete with financial information.
3. Cyan is a precision accent for state and action, not a background wash.
4. Use one dominant action per screen.

## Surfaces

- Prefer solid obsidian and carbon surfaces with restrained elevation.
- Limit glass effects to overlays and moments where depth communicates hierarchy.
- Avoid stacking multiple translucent cards inside translucent cards.
- Use borders sparingly and at sufficient contrast.

## Typography

- Support Dynamic Type and avoid fixed-height text containers.
- Body copy should normally be at least 15 CSS pixels in the WebView.
- Avoid long all-caps labels and excessive tracking for essential information.
- Use tabular figures for balances, rates, and tax calculations.

## Motion

- Motion must explain navigation, progress, or state change.
- Respect `prefers-reduced-motion` in every animated component.
- Avoid white flashes, perpetual pulsing, and decorative loops on operational screens.
- Keep primary transitions under 350 milliseconds.

## Controls

- Minimum interactive target: 44 by 44 points.
- Icon-only controls require accessible labels.
- Disabled and pending states must remain legible.
- Destructive financial actions require explicit confirmation and clear consequences.

## Accessibility

- Meet WCAG AA contrast for text and controls.
- Never communicate financial status by color alone.
- Validate VoiceOver order and meaningful labels.
- Support Bold Text, Increase Contrast, Reduce Motion, and larger text sizes.
