import { useQuery } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';

import { fetchHealth } from './health-api';

export function HealthStatus() {
  const { t } = useTranslation();
  const health = useQuery({
    queryKey: ['health'],
    queryFn: ({ signal }) => fetchHealth(signal),
  });

  if (health.isPending) {
    return <p>{t('health.checking')}</p>;
  }
  if (health.isError) {
    return <p role="alert">{t('health.unreachable')}</p>;
  }
  return <p>{t('health.ok')}</p>;
}
