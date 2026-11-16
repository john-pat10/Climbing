# Climb Log

A logbook for outdoor climbing ("Strava meets AllTrails"). This first version covers:

1. Crag and route search (via the [OpenBeta](https://openbeta.io) API)
2. Logging a climbing session with ascents
3. Session history

Stack: Expo (React Native, TypeScript, Expo Router) · Supabase (auth + Postgres) · OpenBeta GraphQL API.

## Prerequisites

- **Node.js 20 or newer** (22 LTS recommended) and **git** on your computer
- **Expo Go** on your phone (App Store / Google Play), latest version. This project uses Expo SDK 58.
- A free **Supabase** project (https://supabase.com)

You do not need Xcode or Android Studio to run the app in Expo Go.

## Setup

1. Clone and install:

   ```bash
   git clone <this repo's URL>
   cd climb-log
   npm install
   ```

2. Configure Supabase:
   - In the Supabase dashboard, open **SQL Editor**, paste the contents of
     `supabase/migrations/0001_init.sql`, and run it.
   - For development, turn off email confirmation: **Authentication → Sign In / Providers → Email →
     Confirm email** (off). Otherwise sign-up waits for an email link.
   - Copy `.env.example` to `.env` and fill in your **Project URL** and **anon/publishable key**
     from **Project Settings → API Keys**. Never use the `service_role`/secret key in the app.

3. Start the dev server:

   ```bash
   npx expo start
   ```

   Scan the QR code with your phone's camera (iOS) or the Expo Go app (Android). Your phone and
   computer must be on the same Wi-Fi network. If that doesn't work (e.g. on a work or guest
   network), try `npx expo start --tunnel`.

## Scripts

| Command | What it does |
|---|---|
| `npm start` | Start the Expo dev server |
| `npm run web` | Run the app in a browser (handy for quick checks) |
| `npm run typecheck` | TypeScript type check |
| `npm test` | Unit tests (Jest, `jest-expo` preset) |
| `npm run check` | Type check + tests |

## Project structure

```
src/app/        Expo Router screens (every file is a route)
src/lib/        Supabase client, OpenBeta client, grade helpers
supabase/       SQL migrations
```

## Data and licensing rules

- Route and crag data comes from OpenBeta. We only store **factual** fields (names, grades,
  location, discipline), never descriptions or photos.
- Every crag and route row has a `source` column (`openbeta` or `user`) for attribution.
- We never scrape Mountain Project or any other site.
- Climbers can add crags and routes that aren't in OpenBeta; these are stored with `source = 'user'`.

## Dependencies and why they're here

| Package | Why |
|---|---|
| `expo`, `react`, `react-native` | App framework |
| `expo-router` (+ `react-native-screens`, `react-native-safe-area-context`, `expo-linking`, `expo-constants`) | File-based navigation; the others are its required peers |
| `expo-status-bar` | Status bar styling (from the template) |
| `react-dom`, `react-native-web` | Lets the app run in a browser for quick checks, and pins `react-dom` to the SDK's React version (avoids an npm peer conflict) |
| `jest`, `jest-expo`, `@types/jest` (dev) | Unit tests |
