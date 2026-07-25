---
name: Cyber-Minimalist Tech Feed
colors:
  surface: '#0d1515'
  surface-dim: '#0d1515'
  surface-bright: '#333b3b'
  surface-container-lowest: '#080f10'
  surface-container-low: '#151d1e'
  surface-container: '#192122'
  surface-container-high: '#232b2c'
  surface-container-highest: '#2e3637'
  on-surface: '#dce4e5'
  on-surface-variant: '#b9cacb'
  inverse-surface: '#dce4e5'
  inverse-on-surface: '#2a3233'
  outline: '#849495'
  outline-variant: '#3b494b'
  surface-tint: '#00dbe9'
  primary: '#dbfcff'
  on-primary: '#00363a'
  primary-container: '#00f0ff'
  on-primary-container: '#006970'
  inverse-primary: '#006970'
  secondary: '#c0c7d7'
  on-secondary: '#2a313d'
  secondary-container: '#424956'
  on-secondary-container: '#b2b8c8'
  tertiary: '#fff5de'
  on-tertiary: '#3b2f00'
  tertiary-container: '#fed639'
  on-tertiary-container: '#715d00'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#7df4ff'
  primary-fixed-dim: '#00dbe9'
  on-primary-fixed: '#002022'
  on-primary-fixed-variant: '#004f54'
  secondary-fixed: '#dce2f3'
  secondary-fixed-dim: '#c0c7d7'
  on-secondary-fixed: '#151c27'
  on-secondary-fixed-variant: '#404754'
  tertiary-fixed: '#ffe179'
  tertiary-fixed-dim: '#eac324'
  on-tertiary-fixed: '#231b00'
  on-tertiary-fixed-variant: '#554500'
  background: '#0d1515'
  on-background: '#dce4e5'
  surface-variant: '#2e3637'
typography:
  headline-lg:
    fontFamily: Geist
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg-mobile:
    fontFamily: Geist
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Geist
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Geist
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
    letterSpacing: 0.01em
  body-sm:
    fontFamily: Geist
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-code:
    fontFamily: JetBrains Mono
    fontSize: 13px
    fontWeight: '500'
    lineHeight: 16px
  label-caps:
    fontFamily: Geist
    fontSize: 12px
    fontWeight: '700'
    lineHeight: 16px
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 4px
  gutter: 16px
  margin-mobile: 16px
  margin-desktop: 32px
  stack-sm: 8px
  stack-md: 16px
  stack-lg: 24px
---

## Brand & Style
The design system is engineered for a high-performance, developer-centric social environment. It balances a **Futuristic Minimalist** aesthetic with extreme functional clarity. The personality is precise, technical, and forward-leaning, catering to a user base that values speed and digital craftsmanship.

The visual direction avoids traditional skeuomorphism in favor of **low-contrast outlines** and **monochromatic layering**. Depth is achieved through luminosity and color temperature rather than physical shadows. The interface should feel like a high-end IDE—efficient, organized, and immersive—utilizing the "true black" surface to make content and primary accents oscillate with a neon-like energy.

## Colors
The palette is optimized for OLED displays and long-form technical reading. 

- **Primary (Electric Cyan):** Reserved for high-intent actions, active states, and brand-critical iconography. It serves as a light source within the dark environment.
- **Surface Strategy:** 
  - The base layer is `#0a0a0a` to ensure infinite contrast ratios. 
  - Containers use `#1a1a1a` for structural grouping. 
  - Elevated elements (hover states or modals) use `#242424`.
- **Secondary:** Muted slate-blue is utilized for utility icons, inactive tabs, and tags, preventing the UI from feeling overly aggressive.

## Typography
This design system utilizes **Geist** for its systematic, geometric precision. The typeface is optimized for screen readability and aligns with the developer-centric brand narrative. 

- **Hierarchical Contrast:** Titles are pure white (#FFFFFF) with tight letter-spacing to emphasize authority. Body text is pushed back to light gray (#B0B0B0) to reduce eye strain.
- **Technical Accents:** **JetBrains Mono** is introduced for metadata, timestamps, and snippets of code to reinforce the "tech-focused" identity.
- **Scale:** On mobile, large headlines scale down to ensure information density is maintained without breaking the layout.

## Layout & Spacing
The layout follows a **8px soft grid** system to ensure logical proportions. 

- **Desktop:** A 12-column centered grid (max-width: 1280px) with 24px gutters. Sidebars are fixed at 280px, while the central feed remains fluid.
- **Mobile:** A single-column fluid layout with 16px side margins. 
- **Spacing Rhythm:** Use tight spacing (8px) for related elements (e.g., avatar and username) and generous spacing (24px) between distinct feed items or sections. Content should feel airy despite the dark color palette to avoid a "cramped" feel.

## Elevation & Depth
In this design system, depth is communicated through **luminance and borders** rather than shadows. 

- **Surface Tiers:** Higher elevation is represented by lighter shades of gray (Surface Container High).
- **Outlines:** All cards and interactive containers use a 1px solid border. For standard cards, the border is `#242424`. For active or "featured" states, the border may transition to the Primary Cyan at 30% opacity.
- **Backdrop Blurs:** Modals and navigation bars should use a `saturate(180%) blur(20px)` effect over the base `#0a0a0a` at 80% opacity to create a "glass" layered effect that maintains the OLED black where possible.

## Shapes
The shape language is modern and approachable. 
- **Standard UI:** 0.5rem (8px) for buttons and inputs.
- **Large Components:** Cards, modals, and main feed containers use `rounded-xl` (1.5rem / 24px) or `rounded-lg` (1rem / 16px) to create a distinct, friendly container for technical content.
- **Avatars:** Strictly circular (full-round) to provide a soft counter-point to the otherwise geometric and sharp UI.

## Components
- **Buttons:** 
  - *Primary:* Solid Electric Cyan with black text. No shadow; high-glow hover state.
  - *Secondary:* Ghost style with `#3d4451` border and white text.
- **Cards:** Background of `#1a1a1a`, 1px border of `#242424`, and 16px corner radius. On hover, the border color shifts to Primary Cyan.
- **Inputs:** Darker background than the card (`#0a0a0a`). On focus, the 1px border glows in Primary Cyan with a subtle 4px outer blur.
- **Chips/Tags:** Small, high-contrast labels. Use `label-caps` typography. Backgrounds should be a 10% opacity version of the accent color (e.g., Cyan 10% for tech tags).
- **Lists:** Clean separators using 1px lines of `#1a1a1a`. Every list item should have a 12px vertical padding to ensure touch-friendly targets.
- **Feed Interaction:** Like/Share/Comment buttons use the Secondary slate color, turning into Primary Cyan only when active/toggled.