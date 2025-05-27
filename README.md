Okay, here's the README.md file written in English, based on your project and the previous French version.

---

# Astro + Qwik i18n Starter

This project is a fork of the [astro-i18n-starter](https://github.com/psephopaiktes/astro-i18n-starter) with a major enhancement: the ability to **translate interactive Qwik components** directly within an Astro project.

It combines the power of Astro's i18n routing with Qwik's performance and the simplicity of the `compiled-i18n` library to offer a comprehensive solution for multilingual and interactive websites.

[![Logo Image](docs/hero.svg)](https://astro-i18n-starter.pages.dev/ "See document")

## Features

-   ✅ **Qwik Component Translation**: Use a simple syntax (`` _`text` ``) to translate your Qwik components.
-   ✅ **Compile-Time Internationalization**: Translations are integrated during the build process for maximum performance, with no client-side runtime impact.
-   ✅ **Official Astro i18n Support**: Leverages Astro 4.0+'s built-in i18n routing system (`/en/page`, `/fr/page`).
-   ✅ **Automatic Key Extraction**: New strings to be translated are automatically added to your JSON files.
-   ✅ **Vanilla CSS & SEO-friendly**: Retains all the benefits of the original starter.

## How it Works

This starter solves a complex problem: how can a Qwik component, rendered on the server, know the language selected by Astro's routing?

1.  **Astro Manages the Route**: Astro identifies the language from the URL (e.g., `/en/`) and makes it available via `Astro.currentLocale`.
2.  **The Layout Passes the Information**: In the main layout (`src/layouts/Base.astro`), Astro's current locale is passed to our translation system just before the page content (and thus Qwik components) is rendered.
    ```typescript
    // src/layouts/Base.astro
    import { setCurrentLocale } from "@/lib/i18n-setup";
    setCurrentLocale(Astro.currentLocale);
    ```
3.  **`compiled-i18n` Does the Magic**: This library uses a Vite plugin configured in `astro.config.mjs`.
    -   During development and build, it scans all files, including Qwik components (`.tsx`).
    -   It identifies texts to be translated, marked with the `` _`my text` `` syntax.
    -   It replaces these texts with the corresponding translation from your JSON files (`src/i18n/fr.json`, `src/i18n/en.json`, etc.).

The `src/lib/i18n-setup.ts` file acts as the "glue code" to ensure `compiled-i18n` correctly uses the locale provided by Astro during Server-Side Rendering (SSR).

## Quick Start

```sh
# Replace with your username and repository name once published
npx degit YOUR_USER/YOUR_REPO my-astro-qwik-project
```
Or to clone this repository:
```sh
git clone https://github.com/YOUR_USER/YOUR_REPO.git
cd YOUR_REPO
npm install
npm run dev
```

## How to Add Translations

The process is simple and seamless.

**1. Mark Text in a Qwik Component:**

Open a component file (`.tsx`), import `_`, and use it to wrap your string.

```tsx
// src/components/Counter.tsx
import { component$ } from "@builder.io/qwik";
import { _ } from "compiled-i18n";

export default component$(() => {
  return (
    <div>
      {/* This string will now be handled by the i18n system */}
      <h2>{_`Counter Title`}</h2>
      <p>{_`This is a counter example.`}</p>
    </div>
  );
});
```

**2. Let the Magic Happen:**

Start your development server (`npm run dev`). Thanks to the `addMissing: true` option in `astro.config.mjs`, `compiled-i18n` will automatically detect the new key `"Counter Title"` and add it to all your language files in `src/i18n/`.

**3. Translate in JSON Files:**

Open your translation files (e.g., `src/i18n/en.json`, `src/i18n/fr.json`) and add the translation for the new keys.

```json
// src/i18n/en.json
{
  "locale": "en",
  "translations": {
    "Counter Title": "Counter Title"
  }
}
```

```json
// src/i18n/fr.json (Example)
{
  "locale": "fr",
  "translations": {
    "Counter Title": "Titre du Compteur"
  }
}
```

Your component will now display the correct translation based on the URL!

## Project Structure

Here are the most important files for understanding this integration:

```
/
├── astro.config.mjs        # Astro, Qwik, and `i18nPlugin` configuration.
├── src/
│   ├── components/
│   │   └── Counter.tsx     # Example of a translated Qwik component.
│   ├── i18n/
│   │   ├── en.json         # Translation files in JSON format.
│   │   └── fr.json         # (and other languages)
│   ├── layouts/
│   │   └── Base.astro      # Main layout that initializes the locale for SSR.
│   └── lib/
│       └── i18n-setup.ts   # Glue code between Astro and `compiled-i18n`.
└── package.json            # Project dependencies, notably `compiled-i18n`.
```

## Legacy from the Original

This project retains all the qualities of the base `astro-i18n-starter`, including an excellent Lighthouse score, semantic structure, and a focus on SEO.

[![All scores are 100.](docs/lighthouse.png)](https://pagespeed.web.dev/analysis/https-astro-i18n-starter-pages-dev-en/8sg3q21r6c?form_factor=desktop "Check score")