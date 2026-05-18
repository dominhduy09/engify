# Services

## Overview
Network services that handle API calls and external data fetching. Services are called by ViewModels to fetch data and should be abstracted from view logic.

## Files & Purpose

### Dictionary Service
- **DictionaryService.swift** - Fetches word definitions and examples
  - Uses Free Dictionary API: https://api.dictionaryapi.dev
  - Handles word lookups
  - Parses pronunciation data
  - Error handling for not found / network errors

### Suggestions Service (Embedded in DictionaryService)
- Fetches word suggestions using Datamuse API: https://www.datamuse.com/api/
- Supports autocomplete as user types
- Hint/hint text for suggestions

### News Service
- **NewsService.swift** - Fetches English learning articles
  - Currently a placeholder (needs real API)
  - Suggested APIs: NewsAPI, GNews, Guardian API
  - Should fetch articles suitable for ESL learners

## When to Update

### Adding New Services
1. Create new `.swift` file in this folder
2. Use `URLSession` with async/await
3. Include error handling with custom error types
4. Return structured models (see Models/)
5. Add timeout and retry logic if needed

### API Integration Best Practices
- Keep API credentials in Config/environment variables
- Handle rate limiting and throttling
- Cache responses when appropriate (news articles)
- Add proper error messages for network failures
- Test with real network calls before deploying

### Modifying Existing Services
1. **DictionaryService**:
   - Add caching for common words
   - Implement fallback sources if API is down
   - Add support for multiple languages

2. **NewsService**:
   - Select and integrate real news API
   - Add article difficulty level filtering
   - Include reading time estimates
   - Cache articles for offline access

### Testing Services
- Mock services for unit tests
- Test with real API in staging
- Monitor API rate limits
- Log API errors for debugging
