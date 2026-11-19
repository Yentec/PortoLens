// Architecture rules checked in CI (ADR 0002, ADR 0011).
// Each rule name appears in the error output: read its comment to know why it exists.

const API_MODULES = '^apps/api/src/modules';
const TEST_FILES = '[.](spec|test)[.]tsx?$|^apps/[^/]+/(test|src/test)/';

/** @type {import('dependency-cruiser').IConfiguration} */
export default {
  forbidden: [
    {
      name: 'no-circular',
      comment: 'Circular imports make initialisation order fragile and hide bad boundaries.',
      severity: 'error',
      from: {},
      to: { circular: true },
    },
    {
      name: 'no-unresolvable',
      comment: 'Every import must resolve to a real file or installed package.',
      severity: 'error',
      from: {},
      to: { couldNotResolve: true },
    },
    {
      name: 'web-not-to-api',
      comment:
        'The web app talks to the API over HTTP only; shared types go through packages/contracts.',
      severity: 'error',
      from: { path: '^apps/web/' },
      to: { path: '^apps/api/' },
    },
    {
      name: 'api-not-to-web',
      comment: 'The API never depends on the web app.',
      severity: 'error',
      from: { path: '^apps/api/' },
      to: { path: '^apps/web/' },
    },
    {
      name: 'packages-not-to-apps',
      comment: 'Shared packages are dependencies of the apps, never the other way round.',
      severity: 'error',
      from: { path: '^packages/' },
      to: { path: '^apps/' },
    },
    {
      name: 'domain-is-pure',
      comment:
        'A domain layer depends only on its own module domain, packages/primitives and decimal.js: ' +
        'no NestJS, no Prisma, no HTTP, no contracts, no Node.js built-ins (ADR 0011).',
      severity: 'error',
      from: { path: `${API_MODULES}/([^/]+)/domain/` },
      to: {
        pathNot: [
          `${API_MODULES}/$1/domain/`,
          '^packages/primitives/',
          '(^|/)node_modules/decimal[.]js/',
        ],
      },
    },
    {
      name: 'application-not-to-outer-layers',
      comment: 'Use cases depend on ports, never on infrastructure or HTTP code (ADR 0011).',
      severity: 'error',
      from: { path: `${API_MODULES}/[^/]+/application/` },
      to: { path: `${API_MODULES}/[^/]+/(infrastructure|http)/` },
    },
    {
      name: 'infrastructure-not-to-http',
      comment: 'Persistence code never depends on controllers.',
      severity: 'error',
      from: { path: `${API_MODULES}/[^/]+/infrastructure/` },
      to: { path: `${API_MODULES}/[^/]+/http/` },
    },
    {
      name: 'no-cross-module-internals',
      comment:
        'A module uses another module only through its application services or its NestJS module file, ' +
        'never through its domain, infrastructure or HTTP layers (ADR 0011).',
      severity: 'error',
      from: { path: `${API_MODULES}/([^/]+)/` },
      to: {
        path: `${API_MODULES}/[^/]+/(domain|infrastructure|http)/`,
        pathNot: `${API_MODULES}/$1/`,
      },
    },
    {
      name: 'ledger-and-reporting-independent',
      comment: 'Reporting reads ledger tables in SQL; neither module imports the other (ADR 0011).',
      severity: 'error',
      from: { path: `${API_MODULES}/(ledger|reporting)/` },
      to: { path: `${API_MODULES}/(ledger|reporting)/`, pathNot: `${API_MODULES}/$1/` },
    },
    {
      name: 'no-test-code-in-production',
      comment: 'Production code never imports tests or test helpers.',
      severity: 'error',
      from: { path: '^apps/[^/]+/src/', pathNot: TEST_FILES },
      to: { path: TEST_FILES },
    },
    {
      name: 'api-not-to-dev-dependencies',
      comment:
        'The API is deployed without devDependencies: production code must only use dependencies. ' +
        '(The web app is bundled at build time, so this does not apply to it.)',
      severity: 'error',
      from: { path: '^apps/api/src/', pathNot: TEST_FILES },
      to: { dependencyTypes: ['npm-dev'] },
    },
  ],
  options: {
    doNotFollow: { path: 'node_modules' },
    exclude: { path: '^(apps|packages)/[^/]+/(dist|coverage|generated)/' },
    // Also check type-only imports: a domain must not even reference Prisma types.
    tsPreCompilationDeps: true,
    // Resolve packages through their "exports" map, like Node.js and Vite do
    // (ESM-only packages such as vite cannot be resolved otherwise).
    enhancedResolveOptions: {
      exportsFields: ['exports'],
      conditionNames: ['import', 'require', 'node', 'default'],
    },
  },
};
