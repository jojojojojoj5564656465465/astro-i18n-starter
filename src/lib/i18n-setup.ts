import {
	setLocaleGetter,
	setDefaultLocale,
	locales as compiledLocales,
} from "compiled-i18n";
import { DEFAULT_LOCALE } from "@/i18n"; // DEFAULT_LOCALE est votre locale par défaut Astro (ex: 'en')

// Configuration pour le serveur (SSR)
export function setupI18nServer() {
	setLocaleGetter(() => {
		let currentSsrLocale: string | undefined = undefined;
		if (
			typeof globalThis !== "undefined" &&
			(globalThis as any).currentLocale
		) {
			currentSsrLocale = (globalThis as any).currentLocale;
		}

		// Vérifie si la locale SSR est supportée par compiled-i18n
		if (currentSsrLocale && compiledLocales.includes(currentSsrLocale)) {
			return currentSsrLocale;
		}

		// Fallback à la DEFAULT_LOCALE de l'application si elle est supportée par compiled-i18n
		if (compiledLocales.includes(DEFAULT_LOCALE)) {
			return DEFAULT_LOCALE;
		}

		// Ultime fallback à la première locale configurée dans compiled-i18n
		return compiledLocales[0] || "en"; // Mettez une valeur sûre si compiledLocales peut être vide
	});
}

// Configuration pour le client (uniquement en mode développement)
export function setupI18nClient() {
	if (import.meta.env.DEV) {
		const htmlLang = document.documentElement.lang; // ex: "en-US", "ja"
		let targetLocale = DEFAULT_LOCALE; // Fallback par défaut

		if (htmlLang) {
			// Essayer la langue complète (ex: "en-US")
			if (compiledLocales.includes(htmlLang)) {
				targetLocale = htmlLang;
			} else {
				// Essayer la partie langue de base (ex: "en" de "en-US")
				const baseLang = htmlLang.split("-")[0];
				if (compiledLocales.includes(baseLang)) {
					targetLocale = baseLang;
				}
				// Si rien ne correspond, targetLocale reste DEFAULT_LOCALE,
				// qui devrait idéalement être dans compiledLocales
			}
		}

		// S'assurer que la targetLocale finale est bien supportée
		if (!compiledLocales.includes(targetLocale)) {
			console.warn(
				`[compiled-i18n DEV] Fallback locale ${targetLocale} not in compiled-i18n locales. Using ${compiledLocales[0] || DEFAULT_LOCALE}.`,
			);
			targetLocale = compiledLocales.includes(DEFAULT_LOCALE)
				? DEFAULT_LOCALE
				: compiledLocales[0] || "en";
		}

		// console.log(`[compiled-i18n DEV] Setting client defaultLocale to: ${targetLocale} (from html lang: ${htmlLang || 'not set'})`);
		setDefaultLocale(targetLocale);
	}
	// En production, la locale est "baked-in" dans le bundle, setDefaultLocale n'a pas d'effet.
}

// Helper pour définir la locale actuelle dans le contexte global pour le SSR
export function setCurrentLocale(locale: string) {
	if (typeof globalThis !== "undefined") {
		// On stocke la locale d'Astro. setLocaleGetter s'occupera de mapper si besoin.
		(globalThis as any).currentLocale = locale;
		// console.log(`[compiled-i18n SSR] setCurrentLocale (from Astro) to: ${locale}`);
	}
}