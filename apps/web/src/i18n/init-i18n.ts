import i18next from 'i18next';
import { initReactI18next } from 'react-i18next';

import en from './locales/en.json';
import fr from './locales/fr.json';

export const SUPPORTED_LANGUAGES = ['en', 'fr'] as const;
export type SupportedLanguage = (typeof SUPPORTED_LANGUAGES)[number];

const DEFAULT_LANGUAGE: SupportedLanguage = 'en';
const STORAGE_KEY = 'portolens.language';

function isSupported(value: string): value is SupportedLanguage {
  return (SUPPORTED_LANGUAGES as readonly string[]).includes(value);
}

/**
 * Picks the stored choice, then the browser preferences, then English (ADR 0014).
 * Storage can be unavailable (private mode, blocked site data): it is optional.
 */
export function detectLanguage(): SupportedLanguage {
  try {
    const stored = localStorage.getItem(STORAGE_KEY);
    if (stored && isSupported(stored)) {
      return stored;
    }
  } catch {
    // Ignore: fall back to browser preferences.
  }
  for (const tag of navigator.languages) {
    const base = tag.split('-')[0] ?? '';
    if (isSupported(base)) {
      return base;
    }
  }
  return DEFAULT_LANGUAGE;
}

export function rememberLanguage(language: SupportedLanguage): void {
  try {
    localStorage.setItem(STORAGE_KEY, language);
  } catch {
    // Ignore: the choice simply will not survive a reload.
  }
}

export async function initI18n(): Promise<void> {
  const language = detectLanguage();
  await i18next.use(initReactI18next).init({
    resources: { en: { translation: en }, fr: { translation: fr } },
    lng: language,
    fallbackLng: DEFAULT_LANGUAGE,
    supportedLngs: SUPPORTED_LANGUAGES,
    // React already escapes rendered values.
    interpolation: { escapeValue: false },
  });
  document.documentElement.lang = language;
}
