---
name: TeknoAkış Core
colors:
  surface: '#141218'
  surface-dim: '#141218'
  surface-bright: '#3b383e'
  surface-container-lowest: '#0f0d13'
  surface-container-low: '#1d1b20'
  surface-container: '#211f24'
  surface-container-high: '#2b292f'
  surface-container-highest: '#36343a'
  on-surface: '#e6e0e9'
  on-surface-variant: '#cbc4d2'
  inverse-surface: '#e6e0e9'
  inverse-on-surface: '#322f35'
  outline: '#948e9c'
  outline-variant: '#494551'
  surface-tint: '#cfbcff'
  primary: '#cfbcff'
  on-primary: '#381e72'
  primary-container: '#6750a4'
  on-primary-container: '#e0d2ff'
  inverse-primary: '#6750a4'
  secondary: '#cdc0e9'
  on-secondary: '#342b4b'
  secondary-container: '#4d4465'
  on-secondary-container: '#bfb2da'
  tertiary: '#e7c365'
  on-tertiary: '#3e2e00'
  tertiary-container: '#c9a74d'
  on-tertiary-container: '#503d00'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#e9ddff'
  primary-fixed-dim: '#cfbcff'
  on-primary-fixed: '#22005d'
  on-primary-fixed-variant: '#4f378a'
  secondary-fixed: '#e9ddff'
  secondary-fixed-dim: '#cdc0e9'
  on-secondary-fixed: '#1f1635'
  on-secondary-fixed-variant: '#4b4263'
  tertiary-fixed: '#ffdf93'
  tertiary-fixed-dim: '#e7c365'
  on-tertiary-fixed: '#241a00'
  on-tertiary-fixed-variant: '#594400'
  background: '#141218'
  on-background: '#e6e0e9'
  surface-variant: '#36343a'
typography:
  display-lg:
    fontFamily: Geist
    fontSize: 48px
    fontWeight: '700'
    lineHeight: '1.1'
    letterSpacing: -0.04em
  display-sm:
    fontFamily: Geist
    fontSize: 32px
    fontWeight: '700'
    lineHeight: '1.2'
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Geist
    fontSize: 24px
    fontWeight: '600'
    lineHeight: '1.3'
  headline-sm:
    fontFamily: Geist
    fontSize: 20px
    fontWeight: '600'
    lineHeight: '1.3'
  body-lg:
    fontFamily: Geist
    fontSize: 16px
    fontWeight: '400'
    lineHeight: '1.6'
  body-sm:
    fontFamily: Geist
    fontSize: 14px
    fontWeight: '400'
    lineHeight: '1.5'
  label-caps:
    fontFamily: Geist
    fontSize: 12px
    fontWeight: '600'
    lineHeight: '1'
    letterSpacing: 0.1em
  mono-label:
    fontFamily: Geist
    fontSize: 13px
    fontWeight: '500'
    lineHeight: '1.4'
    letterSpacing: -0.01em
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
---

## Brand & Style
The design system is engineered for a high-performance technology environment, blending the precision of developer tools with the high-energy aesthetic of cyber-culture. It targets a tech-literate audience that values speed, clarity, and visual flair.

The style is **Cyber-Modernism**: a hybrid of sleek minimalism and high-contrast futurism. It utilizes deep surface depths, vibrant light-source accents, and sharp geometry to create a sense of digital immersion. Across all themes, the interface maintains a "command center" feel—highly functional, data-dense, and visually striking.

## Colors
The color strategy relies on a "Glow and Depth" model. 

1.  **Futuristic Neon (Default):** Uses cyan as a light source against dark navy surfaces. The purple accent provides a secondary "energy" layer for non-critical interactive elements.
2.  **Minimalist Dark:** A high-contrast, OLED-ready palette. It focuses on pure white against pure black to minimize distractions and maximize legibility.
3.  **Modern Cyber:** An aggressive, high-energy palette. Neon green serves as the primary action color, while cyber red is used for high-attention alerts or destructive actions.

In all themes, backgrounds are tiered using slight shifts in surface luminance rather than borders where possible.

## Typography
This design system uses **Geist** exclusively to achieve a technical, monolinear appearance that feels both engineered and modern.

- **Headlines:** Use tight letter-spacing and heavy weights to create a "blocky" impact.
- **Body:** Standardized at 16px for readability, with a generous line height to balance the dark UI density.
- **Labels:** Utilize `label-caps` for section headers and `mono-label` for data points, version numbers, or status indicators to reinforce the technical narrative.
- **Mobile Scaling:** For screens under 768px, `display-lg` should downscale to 32px and `display-sm` to 24px.

## Layout & Spacing
The layout follows a **Rigid Grid System** based on a 4px baseline. 

- **Grid:** A 12-column fluid grid is used for desktop, shifting to a 4-column grid for mobile.
- **Spacing Rhythm:** Use `md` (16px) for standard component padding and `lg` (24px) for gutter spacing between major layout blocks. 
- **Alignment:** All elements must snap to the 4px grid. Components should use horizontal padding that is consistently 2x the vertical padding to maintain a wide, cinematic feel.

## Elevation & Depth
Depth is conveyed through **Luminous Layering** rather than traditional soft shadows.

- **Level 0 (Background):** The base `surface` color.
- **Level 1 (Cards/Panels):** A slightly lighter variant of the surface or a 1px inner border (0.1 opacity white) to define edges.
- **Level 2 (Modals/Popovers):** These use a "Neon Glow" instead of a shadow—a subtle outer drop shadow using the `primary` color at 15-20% opacity with a large 32px blur.
- **Glassmorphism:** Use backdrop-blur (12px to 20px) on navigation bars and floating action buttons to maintain context of the content beneath.

## Shapes
The shape language is **Technical and Precise**. 

- **Core Radius:** 4px (`rounded-sm`) is the standard for buttons and inputs, providing a sharp, engineered look.
- **Large Elements:** Cards and containers use 8px (`rounded-lg`).
- **Accent Shapes:** For specific UI "flair," use 45-degree clipped corners (chamfers) on button hover states or status tags to reinforce the cyber-tech aesthetic. 
- **Interactive Elements:** Avoid pill shapes; maintain the rectangular structural integrity of the grid.

## Components
- **Buttons:** Primary buttons use a solid fill of the theme's `primary` color with black text. Secondary buttons are "Ghost" style with a 1px border and a subtle glow on hover.
- **Inputs:** Dark backgrounds with a subtle bottom-border only in the "Minimalist Dark" theme, or full 1px outlines in "Futuristic Neon" and "Modern Cyber". The active state must trigger a `primary` color glow.
- **Chips/Tags:** Small, rectangular, with `label-caps` typography. Use `accent` colors for tags to differentiate from primary actions.
- **Cards:** No shadows. Use 1px borders in a slightly lighter shade than the surface. In "Modern Cyber", a 2px left-border of the `primary` color is required for active cards.
- **Progress Bars:** Use thin 4px tracks with a neon "pulse" animation on the `primary` fill to indicate active data flow.
- **Data Tables:** High-density, minimal cell padding, using `mono-label` for numerical data. Zebra striping should be very subtle (2% opacity difference).