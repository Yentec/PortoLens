import { useTranslation } from 'react-i18next';

import { rememberLanguage, SUPPORTED_LANGUAGES, type SupportedLanguage } from './init-i18n';

export function LanguageSwitcher() {
  const { t, i18n } = useTranslation();

  async function change(language: SupportedLanguage): Promise<void> {
    await i18n.changeLanguage(language);
    rememberLanguage(language);
    document.documentElement.lang = language;
  }

  return (
    <label>
      {t('language.label')}{' '}
      <select
        value={i18n.resolvedLanguage}
        onChange={(event) => void change(event.target.value as SupportedLanguage)}
      >
        {SUPPORTED_LANGUAGES.map((language) => (
          <option key={language} value={language}>
            {t(`language.${language}`)}
          </option>
        ))}
      </select>
    </label>
  );
}
