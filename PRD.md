# Product Requirements Document: IdeaBox

## Overview

IdeaBox is a native iOS application for capturing and managing ideas. The app provides a simple, intuitive interface for users to quickly record ideas with titles and descriptions, and track which ideas have been completed or acted upon.

## Objectives

- Provide a fast, distraction-free way to capture ideas on iOS devices
- Enable users to organize and track their ideas with minimal friction
- Create a clean, native iOS experience using modern SwiftUI

## Target Users

- Creative professionals who need to quickly capture inspiration
- Product managers and entrepreneurs tracking feature ideas
- Students organizing thoughts and project concepts
- Anyone who wants a simple idea management tool

## Features

### Core Features (MVP)

#### 1. Idea List View
- Display all ideas in a scrollable list
- Each idea shows:
  - Title (prominent)
  - Description (secondary/preview)
  - Checkbox indicating completion status
- Visual distinction between completed and active ideas
- Empty state when no ideas exist

#### 2. Idea Creation
- Add new ideas with:
  - Title (required)
  - Description (optional)
  - Default unchecked status
- Quick entry form/sheet
- Immediate feedback when idea is saved

#### 3. Idea Completion Tracking
- Toggle completion status via checkbox
- Visual feedback when marking complete/incomplete
- Completed ideas remain visible in the list

#### 4. Idea Management
- Delete ideas (swipe-to-delete)
- Edit existing ideas (future consideration)

### Technical Requirements

#### Platform
- iOS 26+
- iPhone and iPad support
- Portrait and landscape orientations

#### Technology Stack
- SwiftUI using modern APIs:
  - `@Observable` for state management
  - `NavigationStack` for navigation
  - `foregroundStyle()` for styling
  - Two-parameter `onChange(of:)` for state observation
  - **Liquid Glass** material effects (iOS 26+) for modern, translucent UI elements

#### Data Management
- **Phase 1 (MVP)**: Mock/sample data for demonstration
- **Phase 2**: In-memory state management with @State
- **Phase 3**: Local persistence (SwiftData or similar)
- **Phase 4**: Cloud sync (future consideration)

#### Performance
- Instant app launch
- Smooth scrolling for lists with 100+ ideas
- No lag when toggling checkboxes

### User Interface

#### Design Principles
- Native iOS look and feel
- Clean, minimal interface
- Clear visual hierarchy
- Accessible and inclusive

#### Key Screens

1. **Ideas List Screen**
   - Navigation bar with app title
   - "+" button to add new idea
   - List of ideas with checkboxes
   - Empty state illustration/message

2. **Add Idea Sheet**
   - Modal presentation
   - Title text field (auto-focus)
   - Description text field (multi-line)
   - Cancel and Save buttons
   - Keyboard-optimized layout

#### Visual Design
- System fonts for consistency
- SF Symbols for icons
- iOS standard spacing and padding
- Support for Light and Dark modes
- Dynamic Type support for accessibility
- **Liquid Glass materials** for cards, sheets, and background elements to create depth and modern translucency

### User Flows

#### Flow 1: Adding a New Idea
1. User taps "+" button
2. Sheet appears with empty form
3. User enters title (required)
4. User optionally enters description
5. User taps "Save"
6. Sheet dismisses
7. New idea appears at top of list

#### Flow 2: Marking Idea as Complete
1. User taps checkbox next to idea
2. Checkbox fills/animates
3. Idea text style updates (strikethrough or color change)
4. Status persists

#### Flow 3: Deleting an Idea
1. User swipes left on idea
2. Delete button appears
3. User taps delete
4. Idea is removed with animation

## Success Metrics

- User can add an idea in < 5 seconds
- Zero crashes during basic operations
- App launches in < 1 second
- Smooth 60fps scrolling and animations

## Out of Scope (Future Considerations)

- Categories or tags for ideas
- Search and filtering
- Idea prioritization
- Rich text formatting
- Attachments (images, links)
- Sharing ideas
- Cloud backup/sync
- Collaboration features
- Reminders or notifications
- Export functionality

## Development Phases

### Phase 1: MVP with Mock Data (Current)
- Basic UI implementation
- Mock data display
- Core interactions (add, check, delete)
- No persistence

### Phase 2: State Management
- Real data entry
- In-memory state management
- Data only persists during app session

### Phase 3: Local Persistence
- SwiftData integration
- Data survives app restarts
- Migration support

### Phase 4: Polish & Enhancement
- Animations and transitions
- Haptic feedback
- Additional features based on user feedback

## Technical Considerations

### Accessibility
- VoiceOver support for all interactive elements
- Proper labels for checkboxes and buttons
- Dynamic Type support
- Sufficient color contrast

### Localization
- English only for MVP
- Design with localization in mind

### Testing
- Unit tests for data models
- UI tests for critical user flows
- Manual testing on various device sizes

## Open Questions

1. Should completed ideas automatically move to the bottom of the list?
2. Should there be a limit on idea title/description length?
3. Do we need undo/redo functionality?
4. Should there be confirmation before deleting?

## Revision History

- **v1.1** (2025-10-01): Added Liquid Glass material requirements for iOS 26+
- **v1.0** (2025-10-01): Initial PRD for MVP
