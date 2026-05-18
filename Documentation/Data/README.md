# Data

## Overview
Sample data, test fixtures, and mock data used for development, previews, and testing. This folder helps with prototyping and UI development without relying on live APIs.

## Files & Purpose

- **EngifySampleData.swift** - Sample words, definitions, articles, and test data
  - Mock vocabulary words for testing
  - Sample dictionary entries for preview
  - Test data for ViewModels
  - Used in SwiftUI previews throughout the app

## When to Update

### Adding Test Data
1. Add sample models to `EngifySampleData.swift`
2. Create realistic examples matching API response format
3. Include edge cases (very long text, special characters, etc.)
4. Document the purpose of test data sets

### Sample Data Best Practices
- Keep sample data realistic and representative
- Include both typical and edge case examples
- Update sample data when models change
- Use for preview generation in SwiftUI components
- Keep file organized with sections by model type

### Mock Data for Testing
- Create comprehensive test sets covering:
  - Happy path scenarios
  - Error states (empty, network errors)
  - Edge cases (very long words, special characters)
  - Boundary conditions

### Preview Workflow
- Use sample data in `#Preview` blocks
- Test component behavior with different data sets
- Verify UI handles long text gracefully
- Check rendering in both light and dark modes
