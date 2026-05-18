# Design

## Overview
Design system constants and utilities that ensure consistency across the app. This includes spacing, colors, typography, and other visual design tokens.

## Files & Purpose

- **Spacing.swift** - Consistent spacing scale used throughout the app
  - `xs`, `sm`, `md`, `lg`, `xl` - Spacing increments
  - Ensures visual harmony and alignment
  - Single source of truth for margins and padding

## When to Update

### Adding New Design Tokens
1. Add to appropriate constant in `Spacing.swift`
2. Use consistent naming conventions (xs, sm, md, lg, xl)
3. Ensure values are multiples of 4px for alignment
4. Document the purpose of new tokens

### When to Scale Spacing
- Adjust spacing values if doing a major redesign
- Consider responsive design for different device sizes (iPhone, iPad)
- Test spacing changes across all views before deploying
- Maintain visual hierarchy with consistent scaling

### Color Management
- Reference colors through `ThemeManager` (see Managers/)
- Darkened accent colors for WCAG AA contrast compliance
- Always test new colors in light and dark modes
- Verify contrast ratios with accessibility tools

### Typography
- Use system fonts (SF Pro Display, SF Pro Text) for consistency
- Maintain consistent font weights and sizes
- Consider adding new typography tokens if needed

### Design System Best Practices
- Keep design tokens in one place for easy updates
- Use semantic names (not color-specific: use "primary" not "blue")
- Document the purpose of each token
- Test changes across all screen sizes and modes
