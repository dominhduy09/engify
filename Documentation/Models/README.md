# Models

## Overview
Data models and structures that represent domain entities throughout the app. These models are used by Services, ViewModels, and Views.

## Files & Purpose

- **EngifyModels.swift** - Core data models
  - `Word` - Represents a vocabulary word with definition, examples, etc.
  - `DictionaryEntry` - Full dictionary entry with phonetics, meanings, examples
  - `NewsArticle` - News article metadata and content
  - `Suggestion` - Word suggestion from autocomplete API

## When to Update

### Adding New Models
1. Add new struct/class to `EngifyModels.swift` or create separate file
2. Implement `Codable` for API responses
3. Implement `Identifiable` if used in Lists
4. Add `Hashable` if used in Sets or as Dictionary keys
5. Include sensible default values

### Modifying Existing Models
1. **Word**: Update if vocabulary system changes
2. **DictionaryEntry**: Keep synchronized with Free Dictionary API schema
3. **NewsArticle**: Update when news API is selected
4. **Suggestion**: Align with Datamuse API response format

### Model Best Practices
- Keep models immutable when possible
- Use value types (struct) instead of reference types (class)
- Implement proper Codable conformance for JSON serialization
- Add helper computed properties for derived data
- Document complex properties with comments

### API Response Mapping
- Maps should handle API schema changes gracefully
- Use key decoding strategies if API uses snake_case
- Provide defaults for optional fields
- Handle null values appropriately
