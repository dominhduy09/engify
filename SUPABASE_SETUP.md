# Supabase Setup Guide for Engify

This project is a SwiftUI iOS app, so the Next.js instructions you pasted do not apply directly here.

The app already uses the native `supabase-swift` SDK and now loads configuration from environment-style inputs instead of hardcoding keys in Swift files.

## What is already implemented

- Sign up
- Sign in
- Logout
- Persistent session restore
- Protected app entry via `AuthGateView`
- Centralized auth state in `AuthenticationManager`
- Form validation and friendly error handling
- Supabase config loading from environment variables or generated `Info.plist` keys

Relevant files:

- `Engify/Engify/Config/SupabaseConfiguration.swift`
- `Engify/Engify/Auth/AuthService.swift`
- `Engify/Engify/Managers/AuthenticationManager.swift`
- `Engify/Engify/App/AuthGateView.swift`
- `Engify/Engify/Views/LoginView.swift`

## Credentials provided

The local config file has been created with your Supabase project values:

- `Engify/Engify/Support/SupabaseEnvironment.local.xcconfig`

It contains:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

## Recommended setup in Xcode

Use the local xcconfig or scheme environment variables.

### Option 1: Scheme Environment Variables

1. Open Xcode.
2. Go to `Product > Scheme > Edit Scheme`.
3. Select `Run`.
4. Open the `Arguments` tab.
5. Add:
   - `SUPABASE_URL = https://gjuuhndceqcmkfjabwnc.supabase.co`
   - `SUPABASE_ANON_KEY = sb_publishable_OQl5o32fCahcUDU5B23dEA_KAv_0dnE`

This is the easiest option because `SupabaseConfiguration.load()` reads `ProcessInfo.processInfo.environment` first.

### Option 2: Generated Info.plist Build Settings

Because this app uses `GENERATE_INFOPLIST_FILE = YES`, you can also add build settings:

1. Open the `Engify` target.
2. Go to `Build Settings`.
3. Add custom keys:
   - `INFOPLIST_KEY_SUPABASE_URL`
   - `INFOPLIST_KEY_SUPABASE_ANON_KEY`
4. Set them to your Supabase values.

`SupabaseConfiguration.load()` already falls back to `Bundle.main.object(forInfoDictionaryKey:)`.

## About the local xcconfig file

The file created for you is:

- `Engify/Engify/Support/SupabaseEnvironment.local.xcconfig`

You can use it as your source of truth, but Xcode will only apply it if you attach it to a build configuration or copy its values into scheme/build settings.

The example template remains here:

- `Engify/Engify/Support/SupabaseEnvironment.example.xcconfig`

## Security notes

- Use only the Supabase anon or publishable key in the client app.
- Never put the service role key in iOS code or client-side config.
- The current setup is correct for a client application.

## Database setup

Make sure your Supabase project has the tables this app already references:

- `users`
- `user_progress`
- `saved_words`
- `lesson_results`

If you want, I can generate the SQL for these tables and Row Level Security policies next.

## What not to use here

These items from the pasted instructions are for a Next.js web app and should not be added to this repo:

- `npm install @supabase/supabase-js @supabase/ssr`
- `page.tsx`
- `utils/supabase/server.ts`
- `utils/supabase/client.ts`
- `utils/supabase/middleware.ts`
- `.env.local`

This iOS app should continue using the native `Supabase` Swift package that is already installed in Xcode.
