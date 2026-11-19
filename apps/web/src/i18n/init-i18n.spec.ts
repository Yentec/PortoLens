import { describe, expect, it, vi } from 'vitest';

import { detectLanguage, rememberLanguage } from './init-i18n';

describe('detectLanguage', () => {
  it('prefers the stored choice over the browser languages', () => {
    vi.spyOn(navigator, 'languages', 'get').mockReturnValue(['en-US']);
    rememberLanguage('fr');

    expect(detectLanguage()).toBe('fr');
  });

  it('uses the first supported browser language, ignoring the region', () => {
    vi.spyOn(navigator, 'languages', 'get').mockReturnValue(['de-DE', 'fr-FR', 'en-US']);

    expect(detectLanguage()).toBe('fr');
  });

  it('falls back to English when no browser language is supported', () => {
    vi.spyOn(navigator, 'languages', 'get').mockReturnValue(['de-DE', 'es-ES']);

    expect(detectLanguage()).toBe('en');
  });

  it('ignores an unsupported stored value', () => {
    vi.spyOn(navigator, 'languages', 'get').mockReturnValue(['en-US']);
    localStorage.setItem('portolens.language', 'de');

    expect(detectLanguage()).toBe('en');
  });

  it('still works when storage is blocked (private browsing)', () => {
    vi.spyOn(Storage.prototype, 'getItem').mockImplementation(() => {
      throw new DOMException('Access denied', 'SecurityError');
    });
    vi.spyOn(navigator, 'languages', 'get').mockReturnValue(['fr-FR']);

    expect(detectLanguage()).toBe('fr');
  });
});
