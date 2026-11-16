import { fireEvent, render, screen } from '@testing-library/react';
import { describe, expect, it } from 'vitest';

import { LanguageSwitcher } from './language-switcher';

describe('LanguageSwitcher', () => {
  it('switches to French, remembers the choice and updates the page language', async () => {
    render(<LanguageSwitcher />);

    fireEvent.change(screen.getByRole('combobox', { name: 'Language' }), {
      target: { value: 'fr' },
    });

    // The label is re-rendered in French once i18next has switched.
    expect(await screen.findByRole('combobox', { name: 'Langue' })).toBeDefined();
    expect(localStorage.getItem('portolens.language')).toBe('fr');
    expect(document.documentElement.lang).toBe('fr');
  });
});
