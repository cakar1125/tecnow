---
name: Synthetic Intelligence Interface
colors:
  surface: '#111317'
  surface-dim: '#111317'
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
  secondary: '#e9b3ff'
  on-secondary: '#510074'
  secondary-container: '#7d01b1'
  on-secondary-container: '#e5a9ff'
  tertiary: '#deffd6'
  on-tertiary: '#00390a'
  tertiary-container: '#59f766'
  on-tertiary-container: '#006e1c'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#7df4ff'
  primary-fixed-dim: '#00dbe9'
  on-primary-fixed: '#002022'
  on-primary-fixed-variant: '#004f54'
  secondary-fixed: '#f6d9ff'
  secondary-fixed-dim: '#e9b3ff'
  on-secondary-fixed: '#310048'
  on-secondary-fixed-variant: '#7200a3'
  tertiary-fixed: '#70ff76'
  tertiary-fixed-dim: '#42e355'
  on-tertiary-fixed: '#002204'
  on-tertiary-fixed-variant: '#005313'
  background: '#111317'
  on-background: '#e2e2e8'
  surface-variant: '#333539'
typography:
  headline-xl:
    fontFamily: Geist
    fontSize: 40px
    fontWeight: '700'
    lineHeight: 48px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Geist
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Geist
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 34px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  code-snippet:
    fontFamily: JetBrains Mono
    fontSize: 13px
    fontWeight: '500'
    lineHeight: 20px
  label-caps:
    fontFamily: JetBrains Mono
    fontSize: 11px
    fontWeight: '700'
    lineHeight: 16px
    letterSpacing: 0.08em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base-unit: 4px
  gutter: 16px
  margin-mobile: 20px
  stack-sm: 8px
  stack-md: 16px
  stack-lg: 32px
---

## Brand & Style

This design system is built for the high-velocity world of AI and technology news. The brand personality is **technical, forward-leaning, and precise**. It aims to evoke a sense of being "at the edge" of innovation, providing a calm but high-energy environment for consuming complex data.

The visual style is a fusion of **Modern Minimalism** and **Glassmorphism**. By utilizing deep charcoal surfaces and translucent overlays, the interface feels multi-dimensional without being cluttered. The aesthetic is "SaaS-meets-Cyberpunk"—functional enough for professional information gathering, but expressive enough to feel like a next-generation social platform.

High-readability is the primary functional goal, ensuring that code snippets, repo names, and technical jargon remain the hero of the experience.

## Colors

The palette is rooted in a deep, "true-black" adjacent neutral to maximize OLED efficiency and visual depth.

- **Primary (Cyber Blue):** Used for primary actions, focus states, and key data visualizations. It represents the "pulse" of the network.
- **Secondary (Electric Purple):** Used for AI-generated content indicators, special feature highlights, and secondary interactive elements.
- **Accent (Neon Green):** Reserved strictly for "Live," "Trending," or "New" status indicators to provide immediate visual hierarchy.
- **Surface Tiers:** 
  - `Base`: #0F1115 (Background)
  - `Elevated`: #1C1E26 (Cards/Modules)
  - `Overlays`: Semi-transparent variants of the elevated surface with backdrop blurs.

## Typography

The system utilizes a tri-font strategy to balance character and utility:
1. **Geist** handles headlines, providing a technical, "engineered" look that remains clean and modern.
2. **Inter** is the workhorse for body copy and social comments, chosen for its exceptional legibility in dark mode.
3. **JetBrains Mono** is used for metadata, labels, and code blocks to reinforce the developer-centric nature of the content.

Maintain tight tracking on larger headlines to ensure a "dense" tech-journalism feel. Use the `label-caps` style for all "status" highlights (e.g., "REPO UPDATED").

## Layout & Spacing

The layout follows a **Fluid Grid** model with a hard focus on vertical stacking for mobile feeds. 

- **Grid:** Use a 4-column mobile grid with 16px gutters.
- **Rhythm:** All spacing must be multiples of the 4px base unit. 
- **Containment:** Content blocks (cards) should use a 20px margin from the screen edge.
- **Density:** Use tight vertical spacing (`stack-sm`) for metadata groups and wider spacing (`stack-lg`) to separate distinct news stories or repository cards.

## Elevation & Depth

Depth is achieved through **Glassmorphism** and tonal layering rather than traditional shadows.

- **Level 0 (Base):** The darkest surface (#0F1115).
- **Level 1 (Cards):** Slightly lighter (#1C1E26) with a subtle 1px inner stroke of 10% white to define edges.
- **Level 2 (Overlays/Modals):** A semi-transparent surface (70% opacity) with a 20px backdrop-blur. This creates a "frosted glass" effect that allows the neon colors of the feed to glow through the UI.
- **Highlights:** Use a subtle "Cyan Glow" (Primary color at 5% opacity) as a background drop-shadow for active states only.

## Shapes

The shape language is **Rounded**, striking a balance between the "organic" nature of social media and the "geometric" nature of technology.

- **Primary Radius:** 0.5rem (8px) for standard buttons and input fields.
- **Large Radius:** 1rem (16px) for cards and news snippet containers.
- **Interactive Elements:** Floating Action Buttons (FABs) and status chips use a pill-shape (full radius) to stand out against the structured rectangular grid of the feed.

## Components

- **News/Repo Cards:** Use the Level 1 surface with a 16px corner radius. Include a `label-caps` category tag at the top left and a "Star/Save" icon at the top right.
- **Primary Buttons:** High-contrast Cyber Blue background with black text for maximum visibility. No shadows; use a 1px glow-stroke if the button is in a focused state.
- **Glass Chips:** Used for tags like "LLM", "Python", or "Breaking". These should be semi-transparent with a border color matching the category (e.g., Primary or Secondary).
- **Floating Action Button:** A pill-shaped, Electric Purple button with a minimal white icon. This is the "Post" or "Search" trigger.
- **Input Fields:** Darker than the card surface, using a 1px border that illuminates to Cyber Blue when active.
- **Navigation:** A bottom tab bar using the Glassmorphism blur effect, featuring minimalist 2pt line icons. Active states should be indicated by a small neon dot below the icon.
- **Code Blocks:** Encapsulated in a separate black container with JetBrains Mono text and syntax highlighting using the system's neon palette.