import { cleanup } from '@testing-library/react';
import i18next from 'i18next';
import { afterEach, beforeAll } from 'vitest';

import { initI18n } from './src/i18n/init-i18n';

// Translations are loaded once, like in main.tsx (jsdom's browser language is en-US).
beforeAll(async () => {
  await initI18n();
});

// Every test starts from the same state: empty DOM, English, no stored preference.
afterEach(async () => {
  cleanup();
  localStorage.clear();
  await i18next.changeLanguage('en');
});
