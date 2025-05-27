

Je veux faire le i18n anglais,japonais et chinois avec le framework astro js et qwik js je ne peux pas installer qwik-city.
J'ai deja fait des tentatives mais je ne sais pas si c'est bon car pour le moment j'ai la traduction pour les composants astro mais pas pour les composants qwik

j'ai installé compiled-i18n pour qwik 

voici la documentation : 
compiled-i18n

Framework-independent buildtime and runtime translations.

This module statically generates translated copies of code bundles, so that you can serve them to clients as-is, without any runtime translation code. This concept is based on $localize from Angular.

Anywhere in your code, you have simple template string interpolation:

import {_} from 'compiled-i18n'

console.log(_`Logenv ${process.env.NODE_ENV}`)

export const Count = ({count}) => (
	<div title={_`countTitle`}>{_`${count} items`}</div>
)

For French, this becomes:

import {interpolate} from 'compiled-i18n'

console.log(`Mode de Node.JS: ${process.env.NODE_ENV}`)

export const Count = ({count}) => (
	<div title="Nombre d'articles">
		{interpolate(
			{
				0: 'aucun article',
				1: 'un article',
				'*': '$1 articles',
			},
			count
		)}
	</div>
)

Translations are in JSON files. /i18n/fr.json:

{
	"locale": "fr",
	"fallback": "en",
	"name": "Français",
	"translations": {
		"Logenv $1": "Mode de Node.JS: $1",
		"countTitle": "Nombre d'articles",
		"$1 items": {
			"0": "aucun article",
			"1": "un article",
			"*": "$1 articles"
		}
	}
}

On the server, these translations are loaded into memory and translated dependening on the current locale (you can define a callback with setLocaleGetter to choose the locale per translation call). On the client, the translations are embedded directly into the code, and there is a folder per locale. Note that the interpolate function is only added when a translation uses plurals.

You can also use the API functions to implement dynamic translations that you load at runtime.
Installation

Add the plugin as a dev dependency:

npm install --save-dev compiled-i18n
pnpm i -D compiled-i18n
yarn add -D compiled-i18n

There are several parts to localization:

    the translations
    the runtime locale selection (cookie, url, ...)
    the translation function
    getting the translations to the client

compiled-i18n helps with most of these. You have to hook up the helpers to your project. To do this, you add the vite plugin and connect the locale selection.

The vite plugin will automatically create the JSON data files under the i18n/ folder, add new keys to existing files, and embed the data in the build. Add the plugin to your vite config:

import {defineConfig} from 'vite'
import {i18nPlugin} from 'compiled-i18n/vite'

export default defineConfig({
	plugins: [
		// ... other plugins
		i18nPlugin({
			locales: ['en_us', 'en_uk', 'en', 'nl'],
		}),
	],
})

Warning

If you are using an older qwik version than 1.8 please see Plugin order using older qwik versions

You have to set up your project so the plugin knows the current locale, both on the server during SSR, and on the client.

On the server, you can use the setLocaleGetter function to set a callback that returns the current locale, or you can call the setDefaultLocale function to set the locale directly if you only process one locale at a time. See qwik.md for an example setup for Qwik.

In the browser code during development, you need to either set the lang attribute on the <html> tag, or call setDefaultLocale to set the locale. In production, the locale is fixed, so no need to set it. However, you need to make sure that your HTML file loads the correct bundle for the locale. For example, if your entry point is /main.js and your locales are en and fr, you need to load /en/main.js or /fr/main.js depending on the locale.
Qwik

See detailed instructions in qwik.md.
Usage

In your code, use the _ or localize function to translate strings (you must use template string notation). For example:

import {_} from 'compiled-i18n'

// ...

const name = 'John'
const emoji = '👋'
const greeting = _`Hello ${name} ${emoji}!`

You will need to specify the translations for the key "Hello $1 $2!" in the JSON files for the locales.

It is recommended to keep your keys short and descriptive, with capitalization when appropriate. If you would like to change what's shown in your base language, it's easiest if you change the translation and keep the key the same.

In your server code, you need to set the locale getter, which returns the locale that is needed for each translation. This differs per framework. For example, for Qwik:

import {defaultLocale, setLocaleGetter} from 'compiled-i18n'
import {getLocale} from '@builder.io/qwik'

setLocaleGetter(() => getLocale(defaultLocale))

How it works

In the server and in dev mode, all translations are loaded into memory eagerly, but for a production client build, all the localize`x` calls are replaced with their translation.

Translations are stored in json files, by default under /i18n in the project root. The plugin will create missing files and add new keys to existing files.
Types

See index.ts for the full types.
JSON translations format

The JSON files are stored in the project root under /i18n/$locale.json, in the format I18n.Data. A translation is either a string or a Plural object.

export type Data = {
	locale: Locale // the locale key, e.g. en_US or en
	fallback?: Locale // try this locale for missing keys
	name?: string // the name of the locale in the locale, e.g. "Nederlands"
	translations: {
		[key: Key]: Translation | Plural
	}
}

A Translation is a string can that contain $# for interpolation, and $$ for a literal $. For example, _`Hello ${name} ${emoji}` looks up the key "Hello $1 $2" and interpolates the values of name and emoji. Note that this definition means that the Key is also a Translation, so for missing translations, the Key is used as a fallback.

A Plural object contains keys to select a translation with the first interpolation value. The key "*" is used as a fallback. String values are treated as a translation string, and numbers are used to point to other keys. For example, the plural object

{
	"$1 items": {
		"0": "no items",
		"1": "some items",
		"2": 1,
		"3": "three items",
		"three": 3,
		"*": "many items ($1)"
	}
}

will translate _`${count} items` to "no items" for count = 0, "some items" for count = 1 or count = 2, "three items" for count = 3 or count = "three", and `many items (${count})` for any other number.

You can use any string or number as a Plural key, so you could also use it for enums, but perhaps it would be better to use runtime translation for that.
Client-side API
localize`str` or _`str` 

translate template string using in-memory maps

_`Hi ${name}!` converts into a lookup of the I18nKey "Hi $1". A literal $ will be converted to $$. Missing translations fall back to the key.

Nesting is achieved by passing result strings into translations again.

_`There are ${_`${boys} boys`} and ${_`${girls} girls`}.`

localize(key: I18nKey, ...params: any[]) or _(key: I18nKey, ...params: any[])

Translates the key, but this form does not get statically replaced with the translation. This means that when you interpolate, you are generating new keys instead of a single key with a $1 placeholder. For example:

const name = 'Wout'

_`Hi ${name}!` // key: "Hi $1", params: ["Wout"]
_(`Hi ${name}`) // key: "Hi Wout", params: []

It is also your duty to call loadTranslations with data you provide, so the requested translations are present. The built client code will not include any translations. Missing translations use the key.
currentLocale: readonly string

Current locale. Is automatically set by the locate getter that runs on every translation.

On the client side in production it is hardcoded. During dev mode on the client it is automatically set to the lang attribute of the HTML tag if that's valid. You can also set it with setDefaultLocale.
locales: readonly string[]

e.g. ['en_US', 'fr'].
localeNames: readonly const {[key: string]: string}

e.g. {en_US: "English (US)", fr: "Français"}
loadTranslations(translations: I18n.Data['translations'], locale?: string)

Add translations for a locale to the in-memory map. If you don't specify the locale, it uses currentLocale.

This is only needed for dynamic translations. You need to run this both on the client and the server (when using SSR), so they have the same translations available.
Server-side API
setLocaleGetter(getLocale: () => Locale)

getLocale will be used to retrieve the locale on every translation. It defaults to defaultLocale. For example, use this to grab the locale from context during SSR.

This should not be called on the client, as the locale is fixed in production. Instead, the client should set the locale via the HTML lang attribute or with setDefaultLocale.
setDefaultLocale(locale: string)

Sets the default locale at runtime, which is used when no locale can be determined. This is useful during dev mode on the client side if you can't change the HTML's lang attribute. In production on the client, the locale is fixed, and this function has no effect.
Utility API
defaultLocale: readonly string

Default locale, defaults to the first specified locale. Can be set with setDefaultLocale, useful during dev mode on the client side if you can't change the HTML's lang attribute.
guessLocale(acceptsLanguage: string)

Given an accepts-language header value, return the first matching locale. If the given string is invalid, returns undefined. Falls back to defaultLocale
interpolate(translation: I18nTranslation | I18nPlural, ...params: unknown[])

Perform parameter interpolation given a translation string or plural object. Normally you won't use this.
makeKey(...tpl: string[]): string

Returns the calculated key for a given template string array. For example, it returns "Hi $1" for ["Hi ", ""]
Qwik API (from 'compiled-i18n/qwik')
extractBase({serverData}: RenderOptions): string

This sets the base path for assets for a Qwik application. Pass it to the base property of the render options.

If running in development mode, the base path is simply /build. Otherwise, it's /build/${locale}. It also includes the base path given to vite.
setSsrLocaleGetter(): void

Configure compiled-i18n to use the locale from Qwik during SSR.

Call this in your entry.ssr file.
Vite API (from 'compiled-i18n/vite')

The vite plugin accepts these options:

type Options = {
	/** The locales you want to support */
	locales?: string[]
	/** The directory where the locale files are stored, defaults to /i18n */
	localesDir?: string
	/** The default locale, defaults to the first locale */
	defaultLocale?: string
	/** Extra Babel plugins to use when transforming the code */
	babelPlugins?: any[]
	/**
	 * The subdirectory of browser assets in the output. Locale post-processing
	 * and locale subdirectory creation will only happen under this subdirectory.
	 * Do not include a leading slash.
	 *
	 * If the qwikVite plugin is detected, this defaults to `build/`.
	 */
	assetsDir?: string
	/** Automatically add missing keys to the locale files. Defaults to true */
	addMissing?: boolean
	/** Automatically remove unused keys from the locale files. Defaults to false. */
	removeUnusedKeys?: boolean
	/** Use tabs on new JSON files */
	tabs?: boolean
}

Choosing a key name

It is recommended to keep your keys short and descriptive, with capitalization when appropriate. If you would like to change what's shown in your base language, it's easiest if you change the translation and keep the key the same.

If you need to provide some context for the translator, put it inside the key. For example, when translating the word "right" as a capitalized button label, you might want to specify if it's the direction or the opposite of wrong. In that case, you could use the keys "Right-direction" and "Right-correct".

If it's unclear what the parameter is, you can add a comment to the key. For example:

_`Greeting ${name}:name`

Newlines are not allowed in keys.
Automatic translation

The JSON format includes the keys and tools like Github Copilot actually have enough context to translate the keys for you. This is workable for small amounts of translations.

A more robust way is to a tool like deepl-localize. It includes support for compiled-i18n's JSON format.
Roadmap

    allow specifying helper libs that re-export localize and interpolate, so those re-exports are also processed
    build client locales in dev mode as well, being smart about missing keys and hot reloading. In Qwik this might be hard because dev and prod are quite different.
    move unused keys to unused in the JSON files?


Voici la documentation de qwik js pour l'internationalisation

Internationalization

Internationalization is a complex problem. Qwik does not solve the internationalization problem directly instead it only provides low-level APIs to allow other libraries to solve it.
Runtime vs compile time translation

At a high level there are two ways in which the translation problem can be solved:

    Runtime: load a translation map and look up the translations at runtime.
    Compile time: Have a compile step inline the translations into the output string.

Both of the above approaches have trade-offs that one should take into consideration.

The advantages of runtime approaches are:

    Simplicity. Does not require an additional build step.

Disadvantages of the runtime approach are:

    Each string is present in triplicate:
        Once as the original string in the code.
        Once as a key in a translation map.
        Once as a translated value in the translation map.
    The tools currently lack the capability to break up the translation map. The whole translation map must be loaded eagerly on application startup. This is a less than ideal situation because it works against Qwik's effort to break up and lazy load your codebase. Additionally, because translation maps are not broken up, the browser will download unnecessary translations. For example, translations for static components that will never re-render on the client.
    There is a runtime cost to translation lookups.

The advantages of compile-time approaches are:

    Qwik's lazy loading of code now extends to the lazy loading of translation strings. (No unnecessary translation text is loaded)
    No runtime translation map means strings are not in triplicate.

Disadvantages of compile time approaches are:

    Extra build step.
    Changing languages requires a page reload.

Recommendation

With the above in mind, Qwik recommends that you use a tool that best fits your constraints. To help you make a decision there are three different considerations: Browser, Server, and Development.
Browser

Qwik's goal is to deliver the best possible user experience. It achieves this by deferring the loading of code to later so that the initial startup performance is not overwhelmed. Because the runtime approach requires eager loading of all translations, we don't recommend this approach. We think that the compile-time approach is best for the browser.
Server

The server does not have the constraint of lazy loading. For this reason, the server can use either the runtime or compiled approach. The disadvantage of compile time approach on the server is that we need to have a separate deployment for each translation. This complicates the deployment process as well as puts greater demand on the number of servers. For this reason, we think the runtime approach is preferable on the server.
Development

During development, fewer build steps will result in a faster turnaround. For this reason, runtime translation should result in a simpler development workflow.
Our Recommendation

Our recommendation is to use a tool that would provide a runtime approach on the server, and runtime or compile time on the client depending on whether we are in development or production. This way it is possible to prove the best user experience and development experience, and use the least server resources.
Internationalization Libraries
$localize

$localize the translation system is based on the $localize system from Angular. The translations can be extracted in xmb, xlf, xlif, xliff, xlf2, xlif2, xliff2, and json formats.

    NOTE: The $localize system is a compile-time translation system and is completely removed from the final output. $localize is a sub-project of Angular, and including its usage does not mean that Angular is used for rendering of applications.

The easiest way to add $localize to Qwik is using the Qwik CLI command. This will install the required dependencies and create a new public route /src/routes/[locale] showcasing i18n $localize integration.

pnpm run qwik add localize

For further reference, please check this example repo.
Extract translations

When you are done with your changes, you can use the i18n-extract command to extract the translations from the code. This will update the file you see in package.json.

pnpm run i18n-extract

Auto translations for $localize with deepl

For auto translations, you can use the deepl-localize package. It will automatically translate your strings using the deepl.com API.

Use the deepl-localize command to translate your strings with:

pnpm dlx deepl-localize translate -b src/locales/message.en.json -l de-DE fr-FR -a "YOUR-DEEPL-API-KEY"

Alternatively, you can use the deepl-localize command to translate your strings within your script section:

{
  "scripts":{
    "translate":"deepl-localize translate -b src/locales/message.en.json -l de-DE fr-FR -a 'your-deepl-api-key'"
  }
}

compiled-i18n

compiled-i18n is inspired by the $localize system from Angular. It only requires a plugin to be added to the Vite configuration.

It supports both runtime and compile-time translations.

See the Qwik-specific instructions.

Automatic translation is supported via deepl-localize.
qwik-speak

qwik-speak library to translate texts, dates and numbers in Qwik apps.

The easiest way to add qwik-speak to Qwik is following the official guide.

Qwik + compiled-i18n

Make sure you have the vite plugin installed.

    Qwik + compiled-i18n
        Server code
        Client code
            Route-based locale selection
            Query-based locale selection
            Cookie-based locale selection
        Client UI
        Plugin order using older qwik versions

Server code

In your entry.ssr.tsx file, which is your server entry point, you need to set the locale getter, as well as the HTML lang attribute and the base path for assets. Apply the lines marked with +++:

// +++ Extra import
import {extractBase, setSsrLocaleGetter} from 'compiled-i18n/qwik'

// +++ Allow compiled-i18n to get the current SSR locale
setSsrLocaleGetter()

export default function (opts: RenderToStreamOptions) {
	return renderToStream(<Root />, {
		manifest,
		...opts,

		// +++ Configure the base path for assets
		base: extractBase,

		// Use container attributes to set attributes on the html tag.
		containerAttributes: {
			// +++ Set the HTML lang attribute to the SSR locale
			lang: opts.serverData!.locale,

			...opts.containerAttributes,
		},
	})
}

Client code

Then, in the client code, you either need to manage the locale as a route, a query parameter, or use a cookie.
Route-based locale selection

When using a route, you can use the onGet handler on / to redirect GET requests to the correct locale, and then use the locale() function to set the locale for the current request:

    /src/routes/index.tsx:

import type {RequestHandler} from '@builder.io/qwik-city'
import {guessLocale} from 'compiled-i18n'

export const onGet: RequestHandler = async ({request, redirect, url}) => {
	const acceptLang = request.headers.get('accept-language')
	const guessedLocale = guessLocale(acceptLang)
	throw redirect(301, `/${guessedLocale}/${url.search}`)
}

    /src/routes/[locale]/layout.tsx:

import {component$, Slot} from '@builder.io/qwik'
import type {RequestHandler} from '@builder.io/qwik-city'
import {guessLocale, locales} from 'compiled-i18n'

const replaceLocale = (pathname: string, oldLocale: string, locale: string) => {
	const idx = pathname.indexOf(oldLocale)
	return (
		pathname.slice(0, idx) + locale + pathname.slice(idx + oldLocale.length)
	)
}

export const onRequest: RequestHandler = async ({
	request,
	url,
	redirect,
	pathname,
	params,
	locale,
}) => {
	if (locales.includes(params.locale)) {
		// Set the locale for this request
		locale(params.locale)
	} else {
		const acceptLang = request.headers.get('accept-language')
		// Redirect to the correct locale
		const guessedLocale = guessLocale(acceptLang)
		const path =
			// You can use `__` as the locale in URLs to auto-select it
			params.locale === '__' ||
			/^([a-z]{2})([_-]([a-z]{2}))?$/i.test(params.locale)
				? // invalid locale
					'/' + replaceLocale(pathname, params.locale, guessedLocale)
				: // no locale
					`/${guessedLocale}${pathname}`
		throw redirect(301, `${path}${url.search}`)
	}
}

export default component$(() => {
	return <Slot />
})

Query-based locale selection

When using a query parameter, you can use the onRequest handler in the top layout to set the locale for the current request:

    /src/routes/layout.tsx:

// ... other imports
import {guessLocale} from 'compiled-i18n'

export const onRequest: RequestHandler = async ({query, headers, locale}) => {
	// Allow overriding locale with query param `locale`
	const maybeLocale = query.get('locale') || headers.get('accept-language')
	locale(guessLocale(maybeLocale))
}

Cookie-based locale selection

When using a cookie, you can use the onRequest handler in the top layout to set the locale for the current request:

    /src/routes/layout.tsx:

// ... other imports
import {guessLocale} from 'compiled-i18n'

export const onRequest: RequestHandler = async ({
	query,
	cookie,
	headers,
	locale,
}) => {
	// Allow overriding locale with query param `locale`
	// This sets the cookie but doesn't redirect to save another request
	if (query.has('locale')) {
		const newLocale = guessLocale(query.get('locale'))
		cookie.delete('locale')
		cookie.set('locale', newLocale, {})
		locale(newLocale)
	} else {
		// Choose locale based on cookie or accept-language header
		const maybeLocale =
			cookie.get('locale')?.value || headers.get('accept-language')
		locale(guessLocale(maybeLocale))
	}
}

Note that you still need to set the cookie, this is done here with a query parameter. You could also set it in the client and reload.

If you like, you can also add a task to remove the entire query string from the URL:

    /src/routes/layout.tsx, in the exported component:

useOnDocument(
	'load',
	$(() => {
		// remove all query params except allowed
		const allowed = new Set(['page'])
		if (location.search) {
			const params = new URLSearchParams(location.search)
			for (const [key] of params) {
				if (!allowed.has(key)) {
					params.delete(key)
				}
			}
			let search = params.toString()
			if (search) search = '?' + search
			history.replaceState(
				history.state,
				'',
				location.href.slice(0, location.href.indexOf('?')) + search
			)
		}
	})
)

Client UI

Finally, to allow the user to change the locale, you can use a locale selector like this:

    /src/components/locale-selector.tsx:

import {component$, getLocale} from '@builder.io/qwik'
import {_, locales} from 'compiled-i18n'

export const LocaleSelector = component$(() => {
	const currentLocale = getLocale()
	return (
		<>
			{locales.map(locale => {
				const isCurrent = locale === currentLocale
				return (
					// Note, you must use `<a>` and not `<Link>` so the page reloads
					<a
						key={locale}
						// When using route-based locale selection, build the URL here
						href={`?locale=${locale}`}
						aria-disabled={isCurrent}
						class={
							'btn btn-ghost btn-sm' +
							(isCurrent
								? ' bg-neutralContent text-neutral pointer-events-none'
								: ' bg-base-100 text-base-content')
						}
					>
						{locale}
					</a>
				)
			})}
		</>
	)
})

Plugin order using older qwik versions

If you are using a qwik version lower than 1.8, you will need to move the i18nPlugin to the top of the plugin list.

import { qwikVite } from '@builder.io/qwik/optimizer';
import { qwikCity } from '@builder.io/qwik-city/vite';
import {defineConfig} from 'vite'
import {i18nPlugin} from 'compiled-i18n/vite'

export default defineConfig({
	plugins: [
		i18nPlugin({
			locales: ['en_us', 'en_uk', 'en', 'nl'],
		}),
		qwikCity(),
		qwikVite(),
	],
})
----------------------------------------

=== FICHIER: /home/tom/Documents/astro-i18n-starter/src/consts.ts ===

// Place any global data in this file.
// You can import this data from anywhere in your site by using the `import` keyword.

import type { Multilingual } from "@/i18n";

export const SITE_TITLE: string | Multilingual = "Astro i18n Starter";

export const SITE_DESCRIPTION: string | Multilingual = {
	en: "A starter template for Astro with i18n support.",
	ja: "i18n 対応の Astro スターターテンプレート。",
	"zh-cn": "具有 i18n 支持的 Astro 入门模板。",
	ar: "قالب بداية لـ Astro مع دعم i18n.",
};

export const X_ACCOUNT: string | Multilingual = "@psephopaiktes";

export const NOT_TRANSLATED_CAUTION: string | Multilingual = {
	en: "This page is not available in your language.",
	ja: "このページはご利用の言語でご覧いただけません。",
	"zh-cn": "此页面不支持您的语言。",
	ar: "هذه الصفحة غير متوفرة بلغتك.",
};

----------------------------------------

=== FICHIER: /home/tom/Documents/astro-i18n-starter/src/content.config.ts ===

import { defineCollection, z } from "astro:content";
import { glob } from "astro/loaders";

const blog = defineCollection({
	loader: glob({ pattern: "**/[^_]*.mdx", base: "./src/blog" }),
	schema: ({ image }) =>
		z.object({
			title: z.string(),
			description: z.string(),
			date: z.coerce.date(),
			cover: image().optional(),
		}),
});

export const collections = { blog };

----------------------------------------

=== FICHIER: /home/tom/Documents/astro-i18n-starter/src/i18n.ts ===

import { DEFAULT_LOCALE_SETTING, LOCALES_SETTING } from "./locales";
import { getRelativeLocaleUrl } from "astro:i18n";


/**
 * User-defined locales list
 * @constant @readonly
 */
export const LOCALES = LOCALES_SETTING as Record<string, LocaleConfig>;
type LocaleConfig = {
  readonly label: string;
  readonly lang?: string;
  readonly dir?: "ltr" | "rtl";
};


/**
 * Type for the language code
 * @example
 * "en" | "ja" | ...
 */
export type Lang = keyof typeof LOCALES;


/**
 * Default locale code
 * @constant @readonly
*/
export const DEFAULT_LOCALE = DEFAULT_LOCALE_SETTING as Lang;


/**
 * Type for the multilingual object
 * @example
 * { en: "Hello", ja: "こんにちは", ... }
 */
export type Multilingual = { [key in Lang]?: string };


/**
 * Helper to get the translation function
 * @param - The current language
 * @returns - The translation function
 */
export function useTranslations(lang: Lang) {
  return function t(multilingual: Multilingual | string): string {
    if (typeof multilingual === "string") {
      return multilingual;
    // biome-ignore lint/style/noUselessElse: <explanation>
    } else {
      return multilingual[lang] || multilingual[DEFAULT_LOCALE] || "";
    }
  };
}


/**
 * Helper to get corresponding path list for all locales
 * @param url - The current URL object
 * @returns - The list of locale paths
 */
export function getLocalePaths(url: URL): LocalePath[] {
  return Object.keys(LOCALES).map((lang) => {
    return {
      lang: lang as Lang,
      path: getRelativeLocaleUrl(lang, url.pathname.replace(/^\/[a-zA-Z-]+/, ''))
    };
  });
}
type LocalePath = {
  lang: Lang;
  path: string;
};


/**
 * Helper to get locale parms for Astro's `getStaticPaths` function
 * @returns - The list of locale params
 * @see https://docs.astro.build/en/guides/routing/#dynamic-routes
 */
export const localeParams = Object.keys(LOCALES).map((lang) => ({
  params: { lang },
}));

----------------------------------------

=== FICHIER: /home/tom/Documents/astro-i18n-starter/src/locales.ts ===

// locales settings for this theme
// Set the languages you want to support on your site.
// https://astro-i18n-starter.pages.dev/setup/

export const DEFAULT_LOCALE_SETTING: string = "en";

interface LocaleSetting {
	[key: Lowercase<string>]: {
		label: string;
		lang?: string;
		dir?: "rtl" | "ltr";
	};
} // refer: https://starlight.astro.build/reference/configuration/#locales

export const LOCALES_SETTING: LocaleSetting = {
	en: {
		label: "English",
		lang: "en-US",
	},
	ja: {
		label: "日本語",
	},
	"zh-cn": {
		label: "简体中文",
		lang: "zh-CN",
	},
	ar: {
		label: "العربية",
		dir: "rtl",
	},
};

----------------------------------------

=== FICHIER: /home/tom/Documents/astro-i18n-starter/astro.config.mjs ===

import mdx from '@astrojs/mdx';
import sitemap from '@astrojs/sitemap';
import { defineConfig } from 'astro/config';
import { DEFAULT_LOCALE_SETTING, LOCALES_SETTING } from './src/locales';
import { i18nPlugin } from "compiled-i18n/vite";
import qwikdev from '@qwikdev/astro';

// https://astro.build/config
export default defineConfig({
  site: "https://astro-i18n-starter.pages.dev", // Set your site's URL
  i18n: {
    defaultLocale: DEFAULT_LOCALE_SETTING,
    locales: Object.keys(LOCALES_SETTING),
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
            value.lang ?? key,
          ])
        ),
      },
    }),
    qwikdev(),
  ],
  vite: {
    plugins: [
      i18nPlugin({
        // Utilisez les mêmes codes que dans votre locales.ts
        locales: Object.keys(LOCALES_SETTING), // ["en", "ja", "zh-cn", "ar"]
        defaultLocale: DEFAULT_LOCALE_SETTING, // "en"
        localesDir: "./src/i18n",
        addMissing: true,
        removeUnusedKeys: false,
      }),
    ],
  },
});
----------------------------------------

=== FICHIER: /home/tom/Documents/astro-i18n-starter/package.json ===

{
  "name": "astro-i18n-starter",
  "description": "A starter for Astro with i18n support",
  "version": "3.0.0",
  "private": false,
  "license": "MIT",
  "homepage": "https://astro-i18n-starter.pages.dev/",
  "engines": {
    "node": ">=20"
  },
  "scripts": {
    "dev": "astro dev",
    "start": "astro dev --open",
    "build": "astro check && astro build",
    "preview": "astro preview",
    "astro": "astro",
    "i18n-extract": "node_modules/.bin/localize-extract -s \"dist/build/*.js\" -f json -o src/locale/message.en.json",
    "i18n-translate": "node_modules/.bin/localize-translate -s \"*.js\" -t src/locale/message.*.json -o dist/build/{{LOCALE}} -r ./dist/build"
  },
  "dependencies": {
    "@astrojs/check": "^0.9.4",
    "@astrojs/mdx": "^4.3.0",
    "@astrojs/rss": "^4.0.11",
    "@astrojs/sitemap": "^3.4.0",
    "@builder.io/qwik": "^1.14.1",
    "@qwikdev/astro": "^0.8.0",
    "astro": "^5.8.0",

    "typescript": "^5.8.3"
  },
  "devDependencies": {
    "compiled-i18n": "^1.1.1"
  }
}
----------------------------------------

=== FICHIER: /home/tom/Documents/astro-i18n-starter/src/lib/i18n-setup.ts ===

import { setLocaleGetter, setDefaultLocale } from "compiled-i18n";
import { DEFAULT_LOCALE } from "@/i18n";

// Configuration pour le serveur (SSR)
export function setupI18nServer() {
	setLocaleGetter(() => {
		// Pendant le SSR, nous devons récupérer la locale depuis le contexte Astro
		// Cette fonction sera appelée à chaque traduction
		if (
			typeof globalThis !== "undefined" &&
			(globalThis as any).currentLocale
		) {
			return (globalThis as any).currentLocale;
		}
		return DEFAULT_LOCALE;
	});
}

// Configuration pour le client
export function setupI18nClient() {
	// En mode développement, utilise l'attribut lang du HTML
	if (import.meta.env.DEV) {
		const htmlLang = document.documentElement.lang;
		if (htmlLang) {
			setDefaultLocale(htmlLang);
		} else {
			setDefaultLocale(DEFAULT_LOCALE);
		}
	}
	// En production, la locale est fixée par le build
}

// Helper pour définir la locale actuelle dans le contexte global
export function setCurrentLocale(locale: string) {
	if (typeof globalThis !== "undefined") {
		(globalThis as any).currentLocale = locale;
	}
}
----------------------------------------

=== FICHIER: /home/tom/Documents/astro-i18n-starter/src/components/Counter.tsx ===

import { component$, useSignal, useStylesScoped$ } from "@builder.io/qwik";
import { _ } from "compiled-i18n";

export default component$(() => {
  useStylesScoped$(`
    div {
      background-color: red;
      padding: 1rem;
      border-radius: 0.5rem;
      margin: 1rem 0;
    }
    
    button {
      background: #007acc;
      color: white;
      border: none;
      padding: 0.5rem 1rem;
      margin: 0 0.5rem;
      border-radius: 0.25rem;
      cursor: pointer;
    }
    
    button:hover {
      background: #005f99;
    }
    
    .counter-display {
      margin: 0 1rem;
      font-weight: bold;
    }
  `);

  const count = useSignal(0);
  const userName = useSignal("John");

  return (
    <div>
      <h2>{_`welcome`}</h2>
      <p>{_`hello ${userName.value}`}</p>
      <div>
        <button type="button" onClick$={() => count.value--}>
          -
        </button>
        <span class="counter-display">
          {_`counter`}: {count.value}
        </span>
        <button type="button" onClick$={() => count.value++}>
          +
        </button>
      </div>
    </div>
  );
});

----------------------------------------

=== FICHIER: /home/tom/Documents/astro-i18n-starter/src/layouts/Base.astro ===

---
// Basic Layout for All Pages
import { setupI18nServer, setCurrentLocale } from "@/lib/i18n-setup";
import Footer from "@/components/Footer.astro";
import Header from "@/components/Header.astro";
import LocaleHtmlHead from "@/components/i18n/LocaleHtmlHead.astro";
import LocaleSuggest from "@/components/i18n/LocaleSuggest.astro";

import { SITE_TITLE, SITE_DESCRIPTION, X_ACCOUNT } from "@/consts";
import { useTranslations, LOCALES, getLocalePaths, type Lang } from "@/i18n";
const t = useTranslations(Astro.currentLocale as Lang);
import "@/styles/global.css";
if (import.meta.env.SSR) {
  setupI18nServer();
  // Définir la locale actuelle pour ce rendu
  setCurrentLocale(Astro.currentLocale as Lang);
}
interface Props {
  title?: string;
  description?: string;
  frontmatter?: undefined;
}

const {
  title,
  description,
} = Astro.props.frontmatter || Astro.props;

const locale = Astro.currentLocale as Lang;
const localeTitle = title ? `${title} - ${t(SITE_TITLE)}` : t(SITE_TITLE);
const localeDescription = description || t(SITE_DESCRIPTION);
---

<!--

  Source Code:
  https://github.com/psephopaiktes/astro-i18n-starter

-->
<html lang={LOCALES[locale].lang || locale} dir={LOCALES[locale].dir || null}>
  <head>
    <meta charset="UTF-8" />
    <title>{localeTitle}</title>
    <meta name="description" content={localeDescription} />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <link rel="sitemap" href="/sitemap-index.xml" />
    <meta name="generator" content={Astro.generator} />
    {
      getLocalePaths(Astro.url).map((props) => (
        <link
          rel="alternate"
          hreflang={LOCALES[props.lang].lang || props.lang}
          href={Astro.site?.origin + props.path}
        />
      ))
    }

    <!-- icon -->
    <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
    <link rel="icon alternate" sizes="64x64" type="image/png" href="/favicon.png">
    <link rel="icon" sizes="192x192" href="/android-chrome.png" />
    <link rel="apple-touch-icon" sizes="180x180" href="/apple-touch-icon.png" />
    <meta name="color-scheme" content="light dark" />

    <!-- OGP -->
    <meta property="og:type" content="website" />
    <meta property="og:title" content={localeTitle} />
    <meta property="og:site_name" content={localeTitle} />
    <meta property="og:description" content={localeDescription} />
    <meta property="og:image" content={Astro.site + "ogp.png"} />
    <meta property="og:url" content={Astro.url} />
    <meta property="og:locale" content={LOCALES[locale].lang || locale} />
    <meta name="twitter:card" content="summary" />
    <meta name="twitter:site" content={t(X_ACCOUNT)} />

    <!-- External Resource -->
    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />

    <link rel="preload" as="style" fetchpriority="high" href="https://fonts.googleapis.com/css2?family=Noto+Sans:wght@400;800&display=swap" />
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Noto+Sans:wght@400;800&display=swap" media="print" onload={`this.media='all'`} />

    <link rel="preload" as="style" fetchpriority="high" href="https://fonts.googleapis.com/icon?family=Material+Icons+Sharp&display=swap" />
    <link rel="stylesheet" href="https://fonts.googleapis.com/icon?family=Material+Icons+Sharp&display=swap" media="print" onload={`this.media='all'`} />

    <LocaleHtmlHead />
  </head>

  <body>
    <LocaleSuggest />
    <Header />

    <main class="l-main l-content">
      <slot />
    </main>

    <Footer />

    { import.meta.env.DEV && <style>:root { scroll-behavior: auto }</style> }
  </body>
</html>
    <!-- Script pour configurer compiled-i18n côté client -->
    <script>
      // Configuration côté client
      import { setupI18nClient } from '@/lib/i18n-setup';
      if (typeof window !== 'undefined') {
        setupI18nClient();
      }
    </script>
----------------------------------------

=== FICHIER: /home/tom/Documents/astro-i18n-starter/src/pages/index.astro ===

---
// Redirect to Top page for user's system locale
// Basically, you don't need to edit this file.

import {
  useTranslations,
  getLocalePaths,
  LOCALES,
  DEFAULT_LOCALE,
  type Lang,
} from "@/i18n";
import { SITE_TITLE, SITE_DESCRIPTION, X_ACCOUNT } from "@/consts";

const t = useTranslations(Astro.currentLocale as Lang);
const langs = Object.keys(LOCALES);
const baseUrl = import.meta.env.PROD ? Astro.site : "/";
const defaultLocale = DEFAULT_LOCALE;
---

<html lang={DEFAULT_LOCALE}>
  <head>
    <meta charset="UTF-8" />
    <title>redirect...</title>
    <link rel="sitemap" href="/sitemap-index.xml" />
    <meta name="generator" content={Astro.generator} />
    {
      getLocalePaths(Astro.url).map((props) => (
        <link
          rel="alternate"
          hreflang={LOCALES[props.lang].lang || props.lang}
          href={Astro.site?.origin + props.path}
        />
      ))
    }

    <!-- icon -->
    <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
    <link rel="icon" sizes="192x192" href="/android-chrome.png" />
    <link rel="apple-touch-icon" sizes="180x180" href="/apple-touch-icon.png" />
    <meta name="color-scheme" content="light dark" />

    <!-- OGP -->
    <meta property="og:type" content="website" />
    <meta property="og:title" content={t(SITE_TITLE)} />
    <meta property="og:site_name" content={t(SITE_TITLE)} />
    <meta property="og:description" content={t(SITE_DESCRIPTION)} />
    <meta property="og:image" content={Astro.site + "ogp.png"} />
    <meta property="og:url" content={Astro.url} />
    <meta property="og:locale" content={DEFAULT_LOCALE} />
    <meta name="twitter:card" content="summary" />
    <meta name="twitter:site" content={t(X_ACCOUNT)} />

    <noscript>
      <meta
        http-equiv="refresh"
        content={`0;url=${baseUrl + DEFAULT_LOCALE}/`}
      />
    </noscript>

    <script is:inline define:vars={{ langs, baseUrl, defaultLocale }}>
      if (
        localStorage.selectedLang &&
        langs.includes(localStorage.selectedLang)
      ) {
        location.href = `${baseUrl + localStorage.selectedLang}/`;
      } else {
        const browserLang = navigator.language.toLowerCase();

        if (langs.includes(browserLang)) {
          location.href = `${baseUrl + browserLang}/`;
        } else if (langs.includes(browserLang.split("-")[0])) {
          location.href = `${baseUrl + browserLang.split("-")[0]}/`;
        } else {
          location.href = `${baseUrl + defaultLocale}/`;
        }
      }
    </script>
  </head>
  <body>
    <h1>redirect...</h1>
  </body>
</html>

----------------------------------------

=== FICHIER: /home/tom/Documents/astro-i18n-starter/src/pages/[lang]/index.astro ===

---
import { LOCALES, useTranslations, type Lang } from "@/i18n";
import Layout from "@/layouts/Base.astro";
const t = useTranslations(Astro.currentLocale as Lang);
import { getRelativeLocaleUrl } from "astro:i18n";

import CounterQwik from "src/components/Counter.tsx";
import heroImageAr from "@/assets/ar/hero.svg";
import heroImageEn from "@/assets/en/hero.svg";
import heroImageJa from "@/assets/ja/hero.svg";
import heroImageZhCn from "@/assets/zh-cn/hero.svg";
import { Image } from "astro:assets";
import Help from "src/components/Help.tsx";
const locale = Astro.currentLocale as Lang;

export const getStaticPaths = () =>
  Object.keys(LOCALES).map((lang) => ({
    params: { lang },
  }));
---

<Layout>
  <Image
    src={locale === "ja"
      ? heroImageJa
      : locale === "zh-cn"
        ? heroImageZhCn
        : locale === "ar"
          ? heroImageAr
          : heroImageEn}
    alt={t({
      ja: "こんにちは",
      en: "Hello",
      "zh-cn": "你好",
      ar: "مرحبًا",
    })}
    loading="eager"
  />

  <p>
    <em>
      {
        t({
          ja: "i18n Starter は多言語対応サイトを作成するためのシンプルな Astro theme です。Astro v4.0からのi18n機能に対応しています。",
          en: "i18n Starter is a simple Astro theme for creating multilingual websites. It supports i18n feature from Astro v4.0.",
          "zh-cn":
            "i18n Starter 是一个用于创建多语言网站的简单 Astro 主题。它支持 Astro v4.0 的 i18n 功能。",
          ar: "i18n Starter هو موضوع Astro بسيط لإنشاء مواقع الويب متعددة اللغات.يدعم ميزة i18n من Astro v4.0.",
        })
      }
    </em>
  </p>

  <p>
    <a
      href={`https://docs.astro.build/${locale}/guides/internationalization/`}
      target="_blank"
    >
      Internationalization (i18n) Routing | Astro Docs
      <span class="material-icons-sharp dir">open_in_new</span>
    </a>
  </p>

  <p>
    {
      t({
        ja: "基本的にサブディレクトリ方式のURLのみサポートしています。言語ごとに以下のようなURLで管理されます。ルートURLは指定したデフォルト言語にリダイレクトされます。",
        en: "Basically, only the subdirectory URL scheme is supported. It is managed by the URL as follows for each language. The root URL is redirected to the specified default language.",
        "zh-cn":
          "基本上，只支持子目录 URL 方案。 它由以下 URL 为每种语言进行管理。 根 URL 将重定向到指定的默认语言。",
        ar: "أساساً، يتم دعم نظام URL الفرعي فقط. يتم إدارتها من خلال URL كما يلي لكل لغة. يتم توجيه عنوان URL الجذري إلى اللغة الافتراضية المحددة.",
      })
    }
  </p>

  <ul>
    <li>example.com/en/</li>
    <li>example.com/ja/</li>
  </ul>
  <CounterQwik />
  <h2>
    {
      t({
        ja: "特徴",
        en: "Feature",
        "zh-cn": "特点",
        ar: "ميزة",
      })
    }
  </h2>

  <ul>
    <li>
      {
        t({
          ja: "Astro公式のi18n機能をサポート",
          en: "support for Astro's official i18n feature",
          "zh-cn": "支持 Astro 官方的 i18n 功能",
          ar: "دعم لميزة i18n الرسمية لـ Astro",
        })
      }
    </li>
    <li>
      {
        t({
          ja: "多言語ページの様々な管理方法",
          en: "Various management methods for multilingual pages",
          "zh-cn": "多语言页面的各种管理方法",
          ar: "طرق إدارة متعددة للصفحات متعددة اللغات",
        })
      }
    </li>
    <li>Vanilla CSS</li>
    <li>
      {
        t({
          ja: "SEOフレンドリー",
          en: "SEO friendly",
          "zh-cn": "SEO 友好",
          ar: "SEO ودية",
        })
      }
    </li>
    <li>
      {
        t({
          en: "100/100 Lighthouse performance",
          ja: "100/100 Lighthouse スコア",
          "zh-cn": "100/100 Lighthouse 性能",
          ar: "أداء Lighthouse 100/100",
        })
      }
    </li>
  </ul>

  <h2>
    {
      t({
        en: "Getting Started",
        ja: "はじめに",
        "zh-cn": "入门指南",
        ar: "البدء",
      })
    }
  </h2>

  <p>
    {
      t({
        ja: "Astroの基本的な知識を前提とします。",
        en: "Assumes basic knowledge of Astro.",
        "zh-cn": "假设您具有 Astro 的基本知识。",
        ar: "يفترض المعرفة الأساسية بـ Astro.",
      })
    }
  </p>

  <p>
    <a href="https://docs.astro.build/" target="_blank">
      https://docs.astro.build/
      <span class="material-icons-sharp dir">open_in_new</span>
    </a>
  </p>

  <p>
    {
      t({
        ja: "大丈夫な方は、さっそく初めましょう！",
        en: "If you're okay, let's get started!",
        "zh-cn": "如果您没问题，让我们开始吧！",
        ar: "إذا كنت على ما يرام، دعنا نبدأ!",
      })
    }
  </p>

  <p>
    <a href={getRelativeLocaleUrl(locale, "setup")} class="start">
      <span class="material-icons-sharp dir">arrow_forward</span>
      {
        t({
          ja: "設定を開始",
          en: "Start Setup",
          "zh-cn": "开始设置",
          ar: "ابدأ الإعداد",
        })
      }
    </a>
  </p>
  <Help />
</Layout>

<style>
  ul {
    margin-block-start: var(--sp-s);
    list-style: disc;
    padding-inline-start: 1em;
  }

  h2 {
    color: var(--color-theme);
    margin-block-start: var(--sp-l);
  }

  em {
    display: block;
    font-style: normal;
    font-size: 1.3em;
    margin-block-end: var(--sp-m);
  }

  .start {
    display: block;
    width: fit-content;
    padding: 0.5em;
    border-radius: 0.5em;
    background: var(--color-main);
    color: var(--color-base);
    text-decoration: none;
    letter-spacing: 0.05em;
  }
</style>

----------------------------------------

