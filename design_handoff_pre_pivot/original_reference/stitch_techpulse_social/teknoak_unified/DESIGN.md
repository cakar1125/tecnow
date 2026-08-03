---
name: TeknoAkış Unified
colors:
  surface: '#111318'
  surface-dim: '#111318'
  surface-bright: '#37393e'
  surface-container-lowest: '#0c0e12'
  surface-container-low: '#1a1c20'
  surface-container: '#1e2024'
  surface-container-high: '#282a2e'
  surface-container-highest: '#333539'
  on-surface: '#e2e2e8'
  on-surface-variant: '#b9cacb'
  inverse-surface: '#e2e2e8'
  inverse-on-surface: '#2f3035'
  outline: '#849495'
  outline-variant: '#3b494b'
  surface-tint: '#00dbe9'
  primary: '#dbfcff'
  on-primary: '#00363a'
  primary-container: '#00f0ff'
  on-primary-container: '#006970'
  inverse-primary: '#006970'
  secondary: '#ebb2ff'
  on-secondary: '#520072'
  secondary-container: '#b600f8'
  on-secondary-container: '#fff6fc'
  tertiary: '#f4f5fe'
  on-tertiary: '#2d3037'
  tertiary-container: '#d7d9e1'
  on-tertiary-container: '#5c5e66'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#7df4ff'
  primary-fixed-dim: '#00dbe9'
  on-primary-fixed: '#002022'
  on-primary-fixed-variant: '#004f54'
  secondary-fixed: '#f8d8ff'
  secondary-fixed-dim: '#ebb2ff'
  on-secondary-fixed: '#320047'
  on-secondary-fixed-variant: '#74009f'
  tertiary-fixed: '#e1e2ea'
  tertiary-fixed-dim: '#c4c6ce'
  on-tertiary-fixed: '#191c22'
  on-tertiary-fixed-variant: '#44474d'
  background: '#111318'
  on-background: '#e2e2e8'
  surface-variant: '#333539'
typography:
  display-lg:
    fontFamily: Geist
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Geist
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Geist
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  title-md:
    fontFamily: Geist
    fontSize: 20px
    fontWeight: '500'
    lineHeight: 28px
  body-lg:
    fontFamily: Geist
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Geist
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-caps:
    fontFamily: Geist
    fontSize: 12px
    fontWeight: '700'
    lineHeight: 16px
    letterSpacing: 0.08em
  mono-data:
    fontFamily: Geist
    fontSize: 13px
    fontWeight: '500'
    lineHeight: 18px
    letterSpacing: 0.02em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 8px
  container-max: 1280px
  gutter: 24px
  margin-mobile: 16px
  margin-desktop: 32px
---

## Brand & Style

The brand personality is high-octane, technical, and forward-looking, catering to a sophisticated audience of developers, hardware enthusiasts, and tech futurists. The design system leverages a **Technical Glassmorphism** style, blending the precision of developer tools with the immersive depth of high-end consumer electronics interfaces.

The emotional response should be one of "controlled power"—an interface that feels fast, deeply layered, and computationally advanced. Key visual drivers include:
- **Depth through Translucency:** Interfaces are built on semi-transparent layers that reveal subtle background movements.
- **Luminescent Accents:** High-vibrancy "Electric Cyan" and "Cyber Purple" are used as light sources within the UI, rather than just flat fills.
- **Precision Detailing:** Micro-borders and hairline dividers reinforce the feeling of a well-engineered machine.

## Colors

The palette is anchored in a true dark-mode experience, optimized for OLED displays and high-contrast technical readability.

- **Primary Surface (#0A0C10):** Used for the base background. It provides the "void" upon which all glass layers sit.
- **Electric Cyan (#00F0FF):** The primary action color. Used for critical CTAs, progress indicators, and active states. It should often carry a subtle outer glow (0-2px) to simulate a display filament.
- **Cyber Purple (#BC13FE):** A secondary accent used for data visualization, secondary interactive elements, and providing "heat" or depth to gradients.
- **System States:**
  - **Surface-Elevated:** #1A1D23 (used for card backgrounds with 60-80% opacity).
  - **Stroke-Technical:** #FFFFFF with 10% opacity (for subtle "glass" borders).

## Typography

This design system utilizes **Geist** exclusively to maintain a monospaced-adjacent aesthetic that feels technical yet remains highly legible for long-form social content.

- **Headlines:** Use tight letter-spacing and semi-bold weights to create a "locked-in" technical feel.
- **Data Labels:** Utilize the `mono-data` and `label-caps` roles for metadata, timestamps, and hardware specs. These should be rendered in high-contrast (White or Cyan) against the dark surfaces.
- **Body Text:** Maintains a generous line height (1.5x) to ensure readability against semi-transparent backgrounds.

## Layout & Spacing

The layout follows a **Fluid Grid** model based on an 8px square rhythm. 

- **Desktop (1280px+):** A 12-column grid with 24px gutters. Content is centered with wide margins to allow background blurs to bleed into the edges.
- **Tablet (768px - 1279px):** An 8-column grid with 20px gutters. Sidebar navigation collapses into a condensed icon rail.
- **Mobile (< 767px):** A 4-column grid with 16px margins. Cards span full width minus the margins.

**Spacing Logic:** Use 8px (1 unit) for tight groupings, 16px (2 units) for standard element spacing, and 32px+ (4 units) for sectional padding.

## Elevation & Depth

Elevation is achieved through **Backdrop Saturation and Blur** rather than traditional drop shadows.

- **Base Layer (L0):** Deep Midnight (#0A0C10), solid.
- **Card Layer (L1):** 60% opacity surface with a `20px` backdrop-blur. Includes a `1px` inner border of Cyan at 10% opacity to "catch the light."
- **Overlay Layer (L2 - Modals/Menus):** 80% opacity surface with a `40px` backdrop-blur. Features a subtle "glow" border—a 1px solid stroke with a 4px outer bloom using the primary accent color.
- **Interactions:** When an element is hovered, its backdrop blur should increase slightly while the border opacity scales from 10% to 40%.

## Shapes

The design system uses a **"Rounded Eight"** philosophy. All standard containers, cards, and buttons use a base radius of 8px (0.5rem). 

- **Standard (8px):** Buttons, Input Fields, and small Feed Cards.
- **Large (16px):** Primary content containers and Modals.
- **Extra Large (24px):** Hero sections or featured visual modules.

Avoid pill-shaped buttons; the 8px radius maintains the "architectural" and "engineered" feel of the system.

## Components

- **Buttons:** Solid Electric Cyan for primary actions with black text for maximum contrast. Secondary buttons use a transparent background with a 1px Cyan stroke. All buttons have an 8px radius.
- **Feed Cards:** Must utilize the glassmorphism stack (blur + semi-transparent fill). Header area of cards should feature a `label-caps` category indicator in Cyber Purple.
- **Inputs:** Darker than the surface (#000000 40% opacity) with a 1px border that glows Cyan only on focus.
- **Chips/Tags:** Small, 4px rounded rectangles with a Cyber Purple background at 15% opacity and solid Purple text.
- **Navigation Bar:** A fixed-top or fixed-side blur-pane. Icons should be "duotone," using white for the primary shape and Electric Cyan for accent details.
- **Data Visualizers:** Use Cyber Purple for historical data and Electric Cyan for real-time/active data streams.