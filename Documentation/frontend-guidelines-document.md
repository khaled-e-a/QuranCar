# QuranCar Frontend Guidelines

This document outlines the design system, UI components, and styling guidelines for the QuranCar iOS application to ensure consistency across both iPhone and CarPlay interfaces.

## Design Principles

### 1. Distraction-Free
- Minimize cognitive load while driving
- Clear visual hierarchy
- Large touch targets
- High contrast for readability

### 2. Consistency
- Uniform styling across iPhone and CarPlay
- Predictable interface patterns
- Coherent visual language

### 3. Accessibility
- Support for Dynamic Type
- VoiceOver compatibility
- Sufficient color contrast ratios
- Support for right-to-left languages (Arabic)

## Color System

### Brand Colors

#### Primary
- Normal: `#3B82F6` - Main brand color
- Hover: `#60A5FA` - Hover state
- Active: `#2563EB` - Active state
- Disabled: `#3B82F6 50%` - Disabled state
- Subtle: `#DBEAFE` - Subtle emphasis
- Strong: `#1E40AF` - Strong emphasis

#### Secondary
- Normal: `#007BFF` - Secondary brand color
- Hover: `#1190FF` - Hover state
- Active: `#085EC5` - Active state
- Disabled: `#007BFF 50%` - Disabled state
- Subtle: `#91DFFF` - Subtle emphasis
- Strong: `#0E315D` - Strong emphasis



#### Tertiary
- Normal: `#60A5FA` - Tertiary brand color
- Hover: `#93C5FD` - Hover state
- Active: `#3B82F6` - Active state
- Disabled: `#60A5FA 50%` - Disabled state
- Subtle: `#EFF6FF` - Subtle emphasis
- Strong: `#1D4ED8` - Strong emphasis

### Functional Colors

#### Success
- Normal: `#17D074` - Success state
- Hover: `#40E894` - Hover state
- Active: `#0DAC5D` - Active state
- Disabled: `#17D074 50%` - Disabled state

#### Information
- Normal: `#3264FF` - Information state
- Hover: `#5B8EFF` - Hover state
- Active: `#1840F8` - Active state
- Disabled: `#3264FF 50%` - Disabled state

#### Warning
- Normal: `#FF9210` - Warning state
- Hover: `#FFAC38` - Hover state
- Active: `#F67500` - Active state
- Disabled: `#FF9210 50%` - Disabled state

#### Danger
- Normal: `#FA4023` - Danger state
- Hover: `#FF7E6A` - Hover state
- Active: `#E8361A` - Active state
- Disabled: `#FA4023 50%` - Disabled state

### Text Colors
- Title: `#030712` - Primary text
- Body: `#1F2937` - Body text
- Body-subtle: `#4B5563` - Secondary text
- Caption: `#9CA3AF` - Caption text

### Background Colors
1. `#F9FAFB` - Background 1
2. `#F3F4F6` - Background 2
3. `#E5E7EB` - Background 3

### Stroke Colors
1. `#F3F4F6` - Stroke 1
2. `#D1D5DB` - Stroke 2
3. `#6B7280` - Stroke 3

## Typography

### System Fonts
- Primary: SF Pro Text
- Arabic: SF Arabic

### Text Styles

#### iPhone Interface
- H1: 34pt Bold
- H2: 28pt Bold
- H3: 22pt Semibold
- Body: 17pt Regular
- Caption: 15pt Regular
- Button: 17pt Medium

#### CarPlay Interface
- H1: 44pt Bold
- H2: 34pt Bold
- Body: 22pt Regular
- Button: 28pt Medium

### Font Weights
- Regular: 400
- Medium: 500
- Semibold: 600
- Bold: 700

## Icons and Assets

### System Icons
- Use SF Symbols where possible
- Minimum tap target: 44x44pt
- Line weight: 2pt
- Corner radius: 8pt

### Custom Icons
- Match SF Symbols style
- Export in PDF format for vector scaling
- Provide dark mode variants
- Follow Apple Human Interface Guidelines

### Icon Sizes
- Navigation bar: 28x28pt
- Tab bar: 24x24pt
- Toolbar: 24x24pt
- List items: 20x20pt
- CarPlay: 44x44pt minimum

## Components

### Buttons

#### Primary Button
- Height: 48pt
- Corner radius: 8pt
- Font: 17pt Medium
- Background: Primary normal
- Text color: White

#### Secondary Button
- Height: 48pt
- Corner radius: 8pt
- Font: 17pt Medium
- Border: 1pt
- Background: Transparent
- Text color: Primary normal

### Cards
- Corner radius: 12pt
- Shadow: y:2, blur:8, opacity:0.1
- Background: White
- Padding: 16pt

### Lists
- Row height: 56pt
- Divider: 1pt Stroke color 1
- Padding: 16pt horizontal

### Navigation Bar
- Height: 44pt
- Background: System background
- Title: 17pt Semibold

## Layout

### Spacing System
- XS: 4pt
- S: 8pt
- M: 16pt
- L: 24pt
- XL: 32pt
- XXL: 48pt

### Safe Areas
- Respect system safe areas
- Additional 16pt minimum margin
- CarPlay-specific safe areas for driving

### Grid System
- Base unit: 8pt
- Column grid: 12 columns
- Gutter: 16pt
- Margins: 16pt (iPhone), 32pt (CarPlay)

## CarPlay-Specific Guidelines

### Templates
- Use standard CarPlay templates when possible
- Custom templates must be simple and glanceable
- Avoid scrolling content while driving

### Touch Targets
- Minimum size: 44x44pt
- Preferred size: 64x64pt
- Spacing between elements: 16pt minimum

### Text
- Minimum font size: 22pt
- Maximum lines: 2
- High contrast colors only
- No thin font weights

## Animation and Transitions

### Duration
- Quick actions: 0.2s
- Standard transitions: 0.3s
- Complex animations: 0.5s

### Easing
- Standard: ease-out
- Enter: ease-out
- Exit: ease-in

### Motion
- Keep animations subtle
- Avoid complex animations while driving
- Support reduced motion settings

## Accessibility

### VoiceOver
- Meaningful labels for all interactive elements
- Proper heading structure
- Clear navigation flow

### Dynamic Type
- Support all text size categories
- Maintain layout integrity at larger sizes
- Test with maximum font size

### Color Contrast
- Meet WCAG AA standards minimum
- Test all interactive states
- Provide sufficient contrast in CarPlay interface

## Dark Mode

### Colors
- Use semantic colors
- Maintain sufficient contrast
- Adapt imagery for dark mode

### Assets
- Provide dark variants of custom icons
- Adjust shadows and borders
- Test all UI elements in both modes
