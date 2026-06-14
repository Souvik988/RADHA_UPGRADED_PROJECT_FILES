#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';

const root = process.cwd();
const docsDir = path.join(root, 'docs');
const generatedDir = path.join(docsDir, 'generated');
const matrixPath = path.join(docsDir, 'GENERATED_API_CONTRACT_MATRIX.md');
const serverManifestPath = path.join(generatedDir, 'api-contract-server.json');
const mobileManifestPath = path.join(generatedDir, 'api-contract-mobile.json');
const dashboardManifestPath = path.join(generatedDir, 'api-contract-dashboard.json');
const checkMode = process.argv.includes('--check');

const lockedContracts = [
  ['GET', '/api/v1/subscriptions/plans'],
  ['GET', '/api/v1/subscriptions/status'],
  ['GET', '/api/v1/subscriptions/usage'],
  ['POST', '/api/v1/subscriptions/upgrade'],
  ['POST', '/api/v1/subscriptions/cancel'],
  ['POST', '/api/v1/subscriptions/reactivate'],
  ['POST', '/api/v1/payments/checkout'],
  ['POST', '/api/v1/payments/verify'],
  ['GET', '/api/v1/products/lookup/{ean}'],
  ['GET', '/api/v1/catalog/categories'],
  ['GET', '/api/v1/catalog/products'],
];

function walk(dir, predicate, acc = []) {
  if (!fs.existsSync(dir)) return acc;
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    if (['.git', 'node_modules', 'build', 'dist', '.dart_tool', '.next'].includes(entry.name)) {
      continue;
    }
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) walk(full, predicate, acc);
    else if (predicate(full)) acc.push(full);
  }
  return acc;
}

function stripComments(source) {
  return source
    .replace(/\/\*[\s\S]*?\*\//g, '')
    .replace(/^\s*\/\/.*$/gm, '');
}

function firstString(raw) {
  if (!raw) return '';
  const pathMatch = raw.match(/path\s*:\s*['"`]([^'"`]+)['"`]/);
  if (pathMatch) return pathMatch[1];
  const stringMatch = raw.match(/['"`]([^'"`]*)['"`]/);
  return stringMatch ? stringMatch[1] : '';
}

function normalizeParamSyntax(value) {
  return value.replace(/:([A-Za-z0-9_]+)/g, '{$1}').replace(/\{([A-Za-z0-9_]+)\}/g, '{$1}');
}

function normalizePath(value) {
  let route = normalizeParamSyntax(value.trim());
  route = route.replace(/\/+/g, '/');
  if (!route.startsWith('/')) route = `/${route}`;
  return route.replace(/\/$/, '') || '/';
}

function joinServerPath(controllerPath, routePath) {
  const combined = [controllerPath, routePath]
    .filter(Boolean)
    .join('/')
    .replace(/^\/+|\/+$/g, '');
  if (combined.startsWith('api/v1/')) return normalizePath(combined);
  return normalizePath(`api/v1/${combined}`);
}

function parseRoles(decoratorBlock) {
  const roles = [];
  for (const match of decoratorBlock.matchAll(/@Roles\(([^)]*)\)/g)) {
    for (const role of match[1].matchAll(/['"`]([^'"`]+)['"`]/g)) roles.push(role[1]);
  }
  return [...new Set(roles)];
}

function parseServerManifest() {
  const files = walk(path.join(root, 'server', 'src'), (file) => file.endsWith('.controller.ts'));
  const routes = [];
  for (const file of files) {
    const source = stripComments(fs.readFileSync(file, 'utf8'));
    const controllerMatches = [...source.matchAll(/@Controller\s*\(([\s\S]*?)\)/g)];
    for (let index = 0; index < controllerMatches.length; index += 1) {
      const current = controllerMatches[index];
      const next = controllerMatches[index + 1];
      const controllerPath = firstString(current[1]);
      const segment = source.slice(current.index, next ? next.index : source.length);
      const lines = segment.split(/\r?\n/);
      for (let lineIndex = 0; lineIndex < lines.length; lineIndex += 1) {
        const route = lines[lineIndex].match(/@(?<method>Get|Post|Put|Patch|Delete)\s*\((?<args>[^)]*)\)/);
        if (!route) continue;
        let cursor = lineIndex + 1;
        const decoratorLines = [lines[lineIndex]];
        while (cursor < lines.length) {
          const trimmed = lines[cursor].trim();
          if (trimmed.length === 0) {
            cursor += 1;
            continue;
          }
          if (!trimmed.startsWith('@')) break;
          decoratorLines.push(lines[cursor]);
          cursor += 1;
        }
        const handlerLine = lines[cursor] ?? '';
        const handlerMatch = handlerLine.match(/(?:async\s+)?([A-Za-z0-9_]+)\s*\(/);
        const method = route.groups.method.toUpperCase();
        const routePath = firstString(route.groups.args);
        const decoratorBlock = decoratorLines.join('\n');
        const publicRoute = /@Public\(\)/.test(decoratorBlock);
        const usesAuth = /JwtAuthGuard|@RequireTenant\(\)|@Roles\(/.test(decoratorBlock);
        routes.push({
          method,
          path: joinServerPath(controllerPath, routePath),
          controller: path.relative(root, file).replaceAll(path.sep, '/'),
          handler: handlerMatch ? handlerMatch[1] : 'unknown',
          auth: publicRoute ? 'public' : usesAuth ? 'jwt' : 'unspecified',
          roles: parseRoles(decoratorBlock),
          tenant: /@RequireTenant\(\)|TenantScopeGuard/.test(decoratorBlock) ? 'required' : 'unspecified',
        });
      }
    }
  }
  return dedupe(routes, (route) => `${route.method} ${route.path} ${route.controller}#${route.handler}`);
}

function parseMobileManifest() {
  const file = path.join(root, 'apps', 'mobile', 'lib', 'core', 'network', 'api_client.dart');
  if (!fs.existsSync(file)) return [];
  const source = fs.readFileSync(file, 'utf8');
  const routes = [];
  const routeRegex = /@(GET|POST|PUT|PATCH|DELETE)\('([^']+)'\)([\s\S]*?)\n\s*Future<([^;\n]+?)>\s+([A-Za-z0-9_]+)\s*\(([\s\S]*?)\);/g;
  for (const match of source.matchAll(routeRegex)) {
    const args = match[6];
    const bodyTypeMatch = args.match(/@Body\([^)]*\)\s*([A-Za-z0-9_<>, ?]+)/);
    routes.push({
      method: match[1],
      path: normalizePath(match[2]),
      clientMethod: match[5],
      requestDto: bodyTypeMatch ? bodyTypeMatch[1].trim().replace(/\s+/g, ' ') : '',
      responseDto: match[4].trim().replace(/\s+/g, ' '),
      source: 'apps/mobile/lib/core/network/api_client.dart',
    });
  }
  return routes;
}

function parseDashboardClientTargets(dashboardDir) {
  const clientsDir = path.join(dashboardDir, 'lib', 'api', 'clients');
  const targets = new Map();
  for (const file of walk(clientsDir, (candidate) => candidate.endsWith('.ts'))) {
    const source = fs.readFileSync(file, 'utf8');
    const functionRegex = /export\s+async\s+function\s+([A-Za-z0-9_]+)[\s\S]*?\{([\s\S]*?)(?=\nexport\s+async\s+function|\nexport\s+function|\nconst\s+[A-Za-z0-9_]+\s*=|$)/g;
    for (const match of source.matchAll(functionRegex)) {
      const pathMatch = match[2].match(/['"`](\/api\/v1\/[^'"`?\s)]*)['"`]/);
      if (pathMatch) targets.set(match[1], normalizePath(pathMatch[1]));
    }
  }
  return targets;
}

function routePathFromDashboardFile(apiDir, file) {
  const rel = path.relative(apiDir, file).replaceAll(path.sep, '/').replace(/\/route\.ts$/, '');
  return normalizePath(`/api/${rel.replace(/\[([^\]]+)\]/g, '{$1}')}`);
}

function parseDashboardManifest() {
  const defaultDir = path.resolve(root, '..', 'RADHA_UPGRADED_PROJECT_FILES', 'radha_dashboard');
  const dashboardDir = process.env.RADHA_DASHBOARD_DIR || defaultDir;
  const apiDir = path.join(dashboardDir, 'app', 'api');
  if (!fs.existsSync(apiDir)) return [];
  const clientTargets = parseDashboardClientTargets(dashboardDir);
  const routes = [];
  for (const file of walk(apiDir, (candidate) => candidate.endsWith('route.ts'))) {
    const source = fs.readFileSync(file, 'utf8');
    const methods = [...source.matchAll(/export\s+async\s+function\s+(GET|POST|PUT|PATCH|DELETE)/g)].map(
      (match) => match[1],
    );
    const directTargets = [...source.matchAll(/['"`](\/api\/v1\/[^'"`?\s)]*)['"`]/g)].map((match) =>
      normalizePath(match[1]),
    );
    const importedCalls = [...source.matchAll(/import\s+\{([^}]+)\}\s+from\s+['"]@\/lib\/api\/clients\/[^'"]+['"]/g)]
      .flatMap((match) => match[1].split(',').map((part) => part.trim().split(/\s+as\s+/)[0].trim()))
      .filter(Boolean);
    const targetPaths = [
      ...directTargets,
      ...importedCalls.map((name) => clientTargets.get(name)).filter(Boolean),
    ];
    for (const method of methods) {
      routes.push({
        method,
        path: routePathFromDashboardFile(apiDir, file),
        backendTargets: [...new Set(targetPaths)],
        source: path.relative(dashboardDir, file).replaceAll(path.sep, '/'),
      });
    }
  }
  return routes;
}

function dedupe(items, keyFn) {
  const seen = new Set();
  const result = [];
  for (const item of items) {
    const key = keyFn(item);
    if (seen.has(key)) continue;
    seen.add(key);
    result.push(item);
  }
  return result;
}

function compareContracts(server, mobile, dashboard) {
  const serverKeys = new Set(server.map((route) => `${route.method} ${route.path}`));
  const mobileKeys = new Set(mobile.map((route) => `${route.method} ${route.path}`));
  const mismatches = [];
  for (const route of mobile) {
    if (!serverKeys.has(`${route.method} ${route.path}`)) {
      mismatches.push({
        class: 'SERVER_ROUTE_MISSING',
        method: route.method,
        path: route.path,
        source: `mobile:${route.clientMethod}`,
      });
    }
  }
  for (const route of server) {
    if (!mobileKeys.has(`${route.method} ${route.path}`)) {
      mismatches.push({
        class: 'CLIENT_ROUTE_MISSING',
        method: route.method,
        path: route.path,
        source: `server:${route.handler}`,
      });
    }
  }
  for (const route of dashboard) {
    for (const target of route.backendTargets) {
      const key = `${route.method} ${target}`;
      if (!serverKeys.has(key)) {
        mismatches.push({
          class: 'SERVER_ROUTE_MISSING',
          method: route.method,
          path: target,
          source: `dashboard:${route.path}`,
        });
      }
    }
  }
  return mismatches;
}

function renderMarkdown(server, mobile, dashboard, mismatches) {
  const serverKeys = new Set(server.map((route) => `${route.method} ${route.path}`));
  const lockedRows = lockedContracts.map(([method, contractPath]) => {
    const status = serverKeys.has(`${method} ${contractPath}`) ? 'LOCKED' : 'DRIFT';
    return `| ${method} | \`${contractPath}\` | ${status} |`;
  });
  const mismatchRows = mismatches
    .sort((a, b) => `${a.class} ${a.path}`.localeCompare(`${b.class} ${b.path}`))
    .map((item) => `| ${item.class} | ${item.method} | \`${item.path}\` | ${item.source} |`);
  const mobileRows = mobile.map(
    (route) =>
      `| ${route.method} | \`${route.path}\` | ${route.clientMethod} | ${route.requestDto || '-'} | ${route.responseDto || '-'} |`,
  );
  const serverRows = server.map(
    (route) =>
      `| ${route.method} | \`${route.path}\` | ${route.auth} | ${route.roles.join(', ') || '-'} | ${route.tenant} | ${route.controller}#${route.handler} |`,
  );
  const dashboardRows = dashboard.map(
    (route) =>
      `| ${route.method} | \`${route.path}\` | ${route.backendTargets.map((target) => `\`${target}\``).join('<br>') || '-'} | ${route.source} |`,
  );
  return `# Generated API Contract Matrix

Generated by \`tools/generate-api-contract-matrix.mjs\`.

- Generated deterministically from the current worktree.
- Backend manifest: \`docs/generated/api-contract-server.json\`
- Mobile manifest: \`docs/generated/api-contract-mobile.json\`
- Dashboard manifest: \`docs/generated/api-contract-dashboard.json\`
- Server routes: ${server.length}
- Mobile Retrofit routes: ${mobile.length}
- Dashboard BFF routes: ${dashboard.length}
- Mismatches classified: ${mismatches.length}

## Locked Production Contracts

These are the first contracts locked by the drift gate. \`pnpm contracts:check\` fails when any
locked route is absent from the generated server manifest.

| Method | Path | Gate |
|---|---|---|
${lockedRows.join('\n')}

## Classified Mismatches

The generator classifies current static drift. Not every row is a release blocker yet: the CI gate is
currently enforced on the locked production contracts above, then the locked set should expand as
each domain is live-verified.

| Class | Method | Path | Source |
|---|---|---|---|
${mismatchRows.length ? mismatchRows.join('\n') : '| - | - | - | - |'}

## Mobile Manifest

| Method | Path | Client method | Request DTO | Response DTO |
|---|---|---|---|---|
${mobileRows.join('\n')}

## Server Manifest

| Method | Path | Auth | Roles | Tenant | Source |
|---|---|---|---|---|---|
${serverRows.join('\n')}

## Dashboard BFF Manifest

Dashboard rows are extracted from the sibling export worktree when present:
\`../RADHA_UPGRADED_PROJECT_FILES/radha_dashboard\`.

| Method | BFF path | Backend target(s) | Source |
|---|---|---|---|
${dashboardRows.length ? dashboardRows.join('\n') : '| - | - | - | - |'}
`;
}

function writeJson(file, data) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, `${JSON.stringify(data, null, 2)}\n`);
}

const server = parseServerManifest().sort((a, b) => `${a.path} ${a.method}`.localeCompare(`${b.path} ${b.method}`));
const mobile = parseMobileManifest().sort((a, b) => `${a.path} ${a.method}`.localeCompare(`${b.path} ${b.method}`));
const dashboard = parseDashboardManifest().sort((a, b) => `${a.path} ${a.method}`.localeCompare(`${b.path} ${b.method}`));
const mismatches = compareContracts(server, mobile, dashboard);
const markdown = renderMarkdown(server, mobile, dashboard, mismatches);

const lockedDrift = lockedContracts.filter(([method, contractPath]) => {
  return !server.some((route) => route.method === method && route.path === contractPath);
});

if (checkMode) {
  const current = fs.existsSync(matrixPath) ? fs.readFileSync(matrixPath, 'utf8') : '';
  if (current !== markdown) {
    console.error('Generated API contract matrix is out of date. Run `pnpm contracts:generate`.');
    process.exit(1);
  }
  if (lockedDrift.length > 0) {
    console.error('Locked production API contracts drifted:');
    for (const [method, contractPath] of lockedDrift) console.error(`- ${method} ${contractPath}`);
    process.exit(1);
  }
  console.log('API contract drift gate passed.');
  process.exit(0);
}

writeJson(serverManifestPath, server);
writeJson(mobileManifestPath, mobile);
writeJson(dashboardManifestPath, dashboard);
fs.mkdirSync(docsDir, { recursive: true });
fs.writeFileSync(matrixPath, markdown);

if (lockedDrift.length > 0) {
  console.error('Generated matrix, but locked production API contracts drifted:');
  for (const [method, contractPath] of lockedDrift) console.error(`- ${method} ${contractPath}`);
  process.exit(1);
}

console.log(`Generated ${path.relative(root, matrixPath)}.`);
