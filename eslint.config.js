// @ts-check
import js from '@eslint/js';
import { defineConfig, globalIgnores } from 'eslint/config';
import reactHooks from 'eslint-plugin-react-hooks';
import tseslint from 'typescript-eslint';
import { fileURLToPath } from 'node:url';
import { dirname } from 'node:path';

const __dirname = dirname(fileURLToPath(import.meta.url));

export default defineConfig(
  // Never lint generated or third-party output.
  globalIgnores(['**/dist/', '**/coverage/', '**/generated/']),

  // Baseline rules for every JavaScript and TypeScript file.
  js.configs.recommended,

  // Type-aware TypeScript rules: they read the types of the whole program,
  // so they catch bugs (floating promises, unsafe any) that syntax alone cannot.
  tseslint.configs.recommendedTypeChecked,
  {
    languageOptions: {
      parserOptions: {
        // Finds the nearest tsconfig.json of each file (one per app/package).
        projectService: true,
        tsconfigRootDir: __dirname,
      },
    },
  },

  // Project rules (quality only: formatting belongs to Prettier).
  {
    rules: {
      eqeqeq: ['error', 'always'],
      'no-console': 'warn',
      '@typescript-eslint/switch-exhaustiveness-check': [
        'error',
        { considerDefaultExhaustiveForUnions: false, requireDefaultForNonUnion: true },
      ],
      '@typescript-eslint/no-unused-vars': [
        'error',
        { argsIgnorePattern: '^_', varsIgnorePattern: '^_' },
      ],
      // Raw SQL must go through tagged templates (bound parameters), never string-built queries.
      'no-restricted-syntax': [
        'error',
        {
          selector: 'MemberExpression[property.name=/^\\$(queryRawUnsafe|executeRawUnsafe)$/]',
          message:
            'Use the $queryRaw / $executeRaw tagged templates: unsafe raw queries enable SQL injection.',
        },
      ],
    },
  },

  // React: rules of hooks (call order, dependencies) for the web app only.
  {
    files: ['apps/web/**/*.{ts,tsx}'],
    extends: [reactHooks.configs.flat.recommended],
  },

  // Plain JavaScript files (configs) are not part of any tsconfig: no type-aware rules.
  {
    files: ['**/*.{js,mjs,cjs}'],
    extends: [tseslint.configs.disableTypeChecked],
  },
);
