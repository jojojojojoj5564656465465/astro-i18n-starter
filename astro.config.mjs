import mdx from "@astrojs/mdx";
import sitemap from "@astrojs/sitemap";
import { defineConfig } from "astro/config";
import { DEFAULT_LOCALE_SETTING, LOCALES_SETTING } from "./src/locales"; // Assurez-vous que ces imports sont corrects
import { i18nPlugin } from "compiled-i18n/vite";
import qwikdev from "@qwikdev/astro";

// https://astro.build/config
export default defineConfig({
  site: "https://astro-i18n-starter.pages.dev", // Remplacez par l'URL de VOTRE site
  i18n: {
    defaultLocale: DEFAULT_LOCALE_SETTING, // ex: "en"
    locales: Object.keys(LOCALES_SETTING), // ex: ["en", "ja", "zh-cn", "ar"]
    routing: {
      prefixDefaultLocale: true,
      redirectToDefaultLocale: false,
    },
  },
  integrations: [
    mdx(),
    sitemap({
      i18n: {
        defaultLocale: DEFAULT_LOCALE_SETTING,
        locales: Object.fromEntries(
          Object.entries(LOCALES_SETTING).map(([key, value]) => [
            key,
            value.lang ?? key, // Utilise la valeur `lang` si définie, sinon la clé
          ])
        ),
      },
    }),
    qwikdev(), // Intégration Qwik
  ],
  vite: {
    plugins: [
      i18nPlugin({
        locales: Object.keys(LOCALES_SETTING), // Doit correspondre aux locales d'Astro
        defaultLocale: DEFAULT_LOCALE_SETTING,
        localesDir: "./src/i18n", // Chemin vers vos fichiers JSON de traduction
        addMissing: true, // Crée les clés manquantes dans les fichiers JSON
        removeUnusedKeys: false, // Ne supprime pas les clés non utilisées
        // assetsDir: 'build', // La valeur par défaut est 'build' si qwikVite est détecté
      }),
      // qwikdev() ajoute déjà les plugins Vite nécessaires pour Qwik via l'intégration
    ],
  },
});
