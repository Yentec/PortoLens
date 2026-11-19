import { useTranslation } from 'react-i18next';

import { HealthStatus } from './features/health/health-status';
import { LanguageSwitcher } from './i18n/language-switcher';

export function App() {
  const { t } = useTranslation();

  return (
    <main>
      <h1>{t('app.title')}</h1>
      <LanguageSwitcher />
      <HealthStatus />
    </main>
  );
}
