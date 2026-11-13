import 'i18next';

import type en from './locales/en.json';

// Type-safe translation keys: t('health.ok') is checked, t('health.typo') does not compile.
declare module 'i18next' {
  interface CustomTypeOptions {
    defaultNS: 'translation';
    resources: { translation: typeof en };
  }
}
