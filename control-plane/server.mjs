import { createServer } from 'node:http';
import { readFile, mkdir, rename, writeFile } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { basename, dirname, extname, join, normalize, resolve } from 'node:path';
import { randomBytes, randomUUID, scryptSync, timingSafeEqual } from 'node:crypto';

const root = resolve(dirname(new URL(import.meta.url).pathname));
const publicDir = join(root, 'public');
const port = numberFromEnv('PORT', 8787);
const host = process.env.HOST || '0.0.0.0';
const isProduction = process.env.NODE_ENV === 'production';
const allowInsecureFirstAdmin = process.env.VSVD_ALLOW_INSECURE_FIRST_ADMIN === '1';
const secureCookie = process.env.VSVD_COOKIE_SECURE !== '0';
const bootstrapToken = process.env.VSVD_BOOTSTRAP_TOKEN || '';
const dataDir = resolve(process.env.VSVD_DATA_DIR || join(root, 'data'));
const storePath = join(dataDir, 'store.json');
const sessions = new Map();
const loginAttempts = new Map();
const MAX_BODY_BYTES = 64 * 1024;
const SESSION_TTL_MS = 12 * 60 * 60 * 1000;
const ALLOWED_SCOPES = new Set(['PROFILE', 'USER_LIST', 'MESSAGE_HEADER']);
const MIME_TYPES = {
  '.css': 'text/css; charset=utf-8',
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.svg': 'image/svg+xml',
};

let store = await loadStore();

function numberFromEnv(name, fallback) {
  const value = Number.parseInt(process.env[name] || '', 10);
  return Number.isSafeInteger(value) && value > 0 ? value : fallback;
}

function now() {
  return new Date().toISOString();
}

function defaultStore() {
  return {
    schemaVersion: 1,
    admins: [],
    badgeTemplates: [],
    grants: [],
    audit: [],
  };
}

async function loadStore() {
  await mkdir(dataDir, { recursive: true });
  if (!existsSync(storePath)) {
    const initial = defaultStore();
    await persist(initial);
    return initial;
  }
  try {
    const parsed = JSON.parse(await readFile(storePath, 'utf8'));
    return validateStore(parsed);
  } catch (error) {
    throw new Error(`Cannot load Control Plane store: ${error.message}`);
  }
}

function validateStore(candidate) {
  if (!candidate || candidate.schemaVersion !== 1 || !Array.isArray(candidate.admins) ||
      !Array.isArray(candidate.badgeTemplates) || !Array.isArray(candidate.grants) ||
      !Array.isArray(candidate.audit)) {
    throw new Error('Unsupported or corrupt store schema');
  }
  return candidate;
}

async function persist(nextStore) {
  const tempPath = `${storePath}.${process.pid}.${randomBytes(4).toString('hex')}.tmp`;
  await writeFile(tempPath, `${JSON.stringify(nextStore, null, 2)}\n`, { encoding: 'utf8', mode: 0o600 });
  await rename(tempPath, storePath);
}

async function mutate(mutator) {
  const candidate = structuredClone(store);
  const result = await mutator(candidate);
  validateStore(candidate);
  await persist(candidate);
  store = candidate;
  return result;
}

function publicTemplate(template) {
  return {
    id: template.id,
    slug: template.slug,
    label: template.label,
    background: template.background,
    text: template.text,
    scopes: template.scopes,
    enabled: template.enabled,
    createdAt: template.createdAt,
  };
}

function audit(candidate, admin, action, target, details = {}) {
  candidate.audit.unshift({
    id: randomUUID(),
    at: now(),
    adminId: admin.id,
    adminName: admin.username,
    action,
    target,
    details,
  });
  candidate.audit = candidate.audit.slice(0, 2_000);
}

function passwordRecord(password) {
  const salt = randomBytes(16).toString('base64url');
  return { salt, hash: scryptSync(password, salt, 64).toString('base64url') };
}

function passwordMatches(password, record) {
  const actual = Buffer.from(scryptSync(password, record.salt, 64).toString('base64url'));
  const expected = Buffer.from(record.hash);
  return actual.length === expected.length && timingSafeEqual(actual, expected);
}

function validPassword(password) {
  return typeof password === 'string' && password.length >= 12 && password.length <= 256;
}

function validUsername(username) {
  return typeof username === 'string' && /^[a-zA-Z0-9._-]{3,32}$/.test(username);
}

function parseCookies(header = '') {
  return Object.fromEntries(header.split(';').map((part) => {
    const index = part.indexOf('=');
    if (index < 0) return ['', ''];
    return [part.slice(0, index).trim(), decodeURIComponent(part.slice(index + 1).trim())];
  }).filter(([key]) => key));
}

function sessionFromRequest(request) {
  const cookies = parseCookies(request.headers.cookie);
  const id = cookies.vsvd_admin_session;
  if (!id) return null;
  const session = sessions.get(id);
  if (!session || session.expiresAt <= Date.now()) {
    sessions.delete(id);
    return null;
  }
  const admin = store.admins.find((item) => item.id === session.adminId);
  return admin ? { id, ...session, admin } : null;
}

function createSession(admin) {
  const id = randomBytes(32).toString('base64url');
  const session = {
    adminId: admin.id,
    csrfToken: randomBytes(32).toString('base64url'),
    expiresAt: Date.now() + SESSION_TTL_MS,
  };
  sessions.set(id, session);
  return { id, ...session };
}

function setSessionCookie(response, sessionId) {
  const flags = [
    `vsvd_admin_session=${encodeURIComponent(sessionId)}`,
    'Path=/',
    'HttpOnly',
    'SameSite=Strict',
    `Max-Age=${Math.floor(SESSION_TTL_MS / 1000)}`,
  ];
  if (secureCookie) flags.push('Secure');
  response.setHeader('Set-Cookie', flags.join('; '));
}

function clearSessionCookie(response) {
  const flags = ['vsvd_admin_session=', 'Path=/', 'HttpOnly', 'SameSite=Strict', 'Max-Age=0'];
  if (secureCookie) flags.push('Secure');
  response.setHeader('Set-Cookie', flags.join('; '));
}

function requestIp(request) {
  const forwarded = request.headers['x-forwarded-for'];
  return typeof forwarded === 'string' ? forwarded.split(',')[0].trim() : request.socket.remoteAddress || 'unknown';
}

function tooManyLoginAttempts(request) {
  const key = requestIp(request);
  const record = loginAttempts.get(key);
  if (!record || record.expiresAt < Date.now()) return false;
  return record.count >= 5;
}

function registerFailedLogin(request) {
  const key = requestIp(request);
  const previous = loginAttempts.get(key);
  const expiresAt = Date.now() + 15 * 60 * 1000;
  loginAttempts.set(key, { count: (previous?.expiresAt > Date.now() ? previous.count : 0) + 1, expiresAt });
}

function clearLoginAttempts(request) {
  loginAttempts.delete(requestIp(request));
}

function cleanSessions() {
  const timestamp = Date.now();
  for (const [id, session] of sessions) {
    if (session.expiresAt <= timestamp) sessions.delete(id);
  }
}
setInterval(cleanSessions, 15 * 60 * 1000).unref();

function sendJson(response, status, body, headers = {}) {
  const serialized = JSON.stringify(body);
  response.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Content-Length': Buffer.byteLength(serialized),
    'Cache-Control': 'no-store',
    'X-Content-Type-Options': 'nosniff',
    ...headers,
  });
  response.end(serialized);
}

function sendError(response, status, code, message) {
  sendJson(response, status, { error: { code, message } });
}

async function readJson(request) {
  const chunks = [];
  let total = 0;
  for await (const chunk of request) {
    total += chunk.length;
    if (total > MAX_BODY_BYTES) {
      throw new HttpError(413, 'body_too_large', 'Request body is too large');
    }
    chunks.push(chunk);
  }
  try {
    return JSON.parse(Buffer.concat(chunks).toString('utf8') || '{}');
  } catch {
    throw new HttpError(400, 'invalid_json', 'Request body must be valid JSON');
  }
}

class HttpError extends Error {
  constructor(status, code, message) {
    super(message);
    this.status = status;
    this.code = code;
  }
}

function requireAdmin(request, response, { mutate = false } = {}) {
  const session = sessionFromRequest(request);
  if (!session) {
    sendError(response, 401, 'authentication_required', 'Sign in to the VSVD admin panel');
    return null;
  }
  if (mutate && request.headers['x-csrf-token'] !== session.csrfToken) {
    sendError(response, 403, 'csrf_failed', 'Invalid CSRF token');
    return null;
  }
  return session;
}

function normalizeTelegramUserId(value) {
  const id = String(value ?? '').trim();
  if (!/^[1-9][0-9]{0,18}$/.test(id) || BigInt(id) > 9223372036854775807n) {
    throw new HttpError(400, 'invalid_telegram_user_id', 'Telegram user ID must be a positive signed 64-bit integer');
  }
  return id;
}

function normalizeColor(value, field) {
  const color = String(value ?? '').trim();
  if (!/^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(color)) {
    throw new HttpError(400, 'invalid_color', `${field} must be #RRGGBB or #AARRGGBB`);
  }
  return color.length === 7 ? `#FF${color.slice(1).toUpperCase()}` : color.toUpperCase();
}

function normalizeScopes(value) {
  const scopes = Array.isArray(value) ? value.filter((scope) => ALLOWED_SCOPES.has(scope)) : [];
  if (!scopes.length) {
    throw new HttpError(400, 'invalid_scopes', 'Select at least one display scope');
  }
  return [...new Set(scopes)];
}

function normalizeExpiry(value) {
  if (value === null || value === undefined || value === '') return null;
  const parsed = new Date(value);
  if (Number.isNaN(parsed.valueOf()) || parsed.valueOf() <= Date.now()) {
    throw new HttpError(400, 'invalid_expiry', 'Expiry must be a future ISO date');
  }
  return parsed.toISOString();
}

function templateById(id) {
  return store.badgeTemplates.find((item) => item.id === id);
}

function activeBadgesForUser(telegramUserId) {
  const timestamp = Date.now();
  return store.grants
    .filter((grant) => grant.telegramUserId === telegramUserId && !grant.revokedAt && (!grant.expiresAt || Date.parse(grant.expiresAt) > timestamp))
    .map((grant) => ({ grant, template: templateById(grant.badgeId) }))
    .filter(({ template }) => template?.enabled)
    .map(({ grant, template }) => ({
      id: template.slug,
      label: template.label,
      background: template.background,
      text: template.text,
      scopes: template.scopes.join(','),
      expiresAt: grant.expiresAt ? Date.parse(grant.expiresAt) : 0,
    }));
}

async function route(request, response) {
  const url = new URL(request.url, `http://${request.headers.host || 'localhost'}`);
  const path = url.pathname;

  if (path === '/api/v1/health' && request.method === 'GET') {
    return sendJson(response, 200, { status: 'ok', service: 'vsvd-control-plane', time: now() });
  }

  const publicBadgeMatch = path.match(/^\/api\/v1\/badges\/users\/([0-9]+)$/);
  if (publicBadgeMatch && request.method === 'GET') {
    const telegramUserId = normalizeTelegramUserId(publicBadgeMatch[1]);
    return sendJson(response, 200, {
      schemaVersion: 1,
      telegramUserId,
      issuedAt: now(),
      badges: activeBadgesForUser(telegramUserId),
    }, { 'Cache-Control': 'public, max-age=300' });
  }

  if (path === '/api/admin/bootstrap' && request.method === 'GET') {
    const firstAdminRequired = store.admins.length === 0;
    return sendJson(response, 200, {
      initialized: !firstAdminRequired,
      setupAllowed: firstAdminRequired && (allowInsecureFirstAdmin || Boolean(bootstrapToken)),
      production: isProduction,
    });
  }

  if (path === '/api/admin/bootstrap' && request.method === 'POST') {
    if (store.admins.length) throw new HttpError(409, 'already_initialized', 'An administrator already exists');
    const body = await readJson(request);
    if (!allowInsecureFirstAdmin && (!bootstrapToken || body.bootstrapToken !== bootstrapToken)) {
      throw new HttpError(403, 'bootstrap_forbidden', 'A valid bootstrap token is required');
    }
    if (!validUsername(body.username) || !validPassword(body.password)) {
      throw new HttpError(400, 'invalid_admin', 'Username must be 3–32 safe characters and password at least 12 characters');
    }
    const admin = await mutate((candidate) => {
      const created = { id: randomUUID(), username: body.username, password: passwordRecord(body.password), createdAt: now() };
      candidate.admins.push(created);
      audit(candidate, created, 'admin.bootstrap', created.id, {});
      return created;
    });
    const session = createSession(admin);
    setSessionCookie(response, session.id);
    return sendJson(response, 201, { admin: { id: admin.id, username: admin.username }, csrfToken: session.csrfToken });
  }

  if (path === '/api/admin/login' && request.method === 'POST') {
    if (tooManyLoginAttempts(request)) throw new HttpError(429, 'rate_limited', 'Too many sign-in attempts; try again later');
    const body = await readJson(request);
    const admin = store.admins.find((item) => item.username === body.username);
    if (!admin || !passwordMatches(String(body.password || ''), admin.password)) {
      registerFailedLogin(request);
      throw new HttpError(401, 'invalid_credentials', 'Invalid username or password');
    }
    clearLoginAttempts(request);
    const session = createSession(admin);
    setSessionCookie(response, session.id);
    return sendJson(response, 200, { admin: { id: admin.id, username: admin.username }, csrfToken: session.csrfToken });
  }

  if (path === '/api/admin/logout' && request.method === 'POST') {
    const session = requireAdmin(request, response, { mutate: true });
    if (!session) return;
    sessions.delete(session.id);
    clearSessionCookie(response);
    return sendJson(response, 200, { ok: true });
  }

  if (path === '/api/admin/me' && request.method === 'GET') {
    const session = requireAdmin(request, response);
    if (!session) return;
    return sendJson(response, 200, { admin: { id: session.admin.id, username: session.admin.username }, csrfToken: session.csrfToken });
  }

  if (path === '/api/admin/badges' && request.method === 'GET') {
    const session = requireAdmin(request, response);
    if (!session) return;
    return sendJson(response, 200, { badges: store.badgeTemplates.map(publicTemplate) });
  }

  if (path === '/api/admin/badges' && request.method === 'POST') {
    const session = requireAdmin(request, response, { mutate: true });
    if (!session) return;
    const body = await readJson(request);
    const slug = String(body.slug ?? '').trim().toLowerCase();
    if (!/^[a-z][a-z0-9.-]{1,63}$/.test(slug)) {
      throw new HttpError(400, 'invalid_badge_slug', 'Badge slug must use lowercase letters, digits, dots or hyphens');
    }
    const label = String(body.label ?? '').trim();
    if (!label || label.length > 20) throw new HttpError(400, 'invalid_badge_label', 'Badge label must be 1–20 characters');
    const template = await mutate((candidate) => {
      if (candidate.badgeTemplates.some((item) => item.slug === slug)) {
        throw new HttpError(409, 'badge_slug_exists', 'A badge with this slug already exists');
      }
      const created = {
        id: randomUUID(), slug, label,
        background: normalizeColor(body.background, 'Background'),
        text: normalizeColor(body.text, 'Text'),
        scopes: normalizeScopes(body.scopes),
        enabled: true,
        createdAt: now(),
      };
      candidate.badgeTemplates.push(created);
      audit(candidate, session.admin, 'badge_template.create', created.id, { slug });
      return created;
    });
    return sendJson(response, 201, { badge: publicTemplate(template) });
  }

  const badgeMatch = path.match(/^\/api\/admin\/badges\/([\w-]+)$/);
  if (badgeMatch && request.method === 'PATCH') {
    const session = requireAdmin(request, response, { mutate: true });
    if (!session) return;
    const body = await readJson(request);
    const template = await mutate((candidate) => {
      const found = candidate.badgeTemplates.find((item) => item.id === badgeMatch[1]);
      if (!found) throw new HttpError(404, 'badge_not_found', 'Badge template not found');
      if (typeof body.enabled === 'boolean') found.enabled = body.enabled;
      audit(candidate, session.admin, 'badge_template.update', found.id, { enabled: found.enabled });
      return found;
    });
    return sendJson(response, 200, { badge: publicTemplate(template) });
  }

  if (path === '/api/admin/grants' && request.method === 'GET') {
    const session = requireAdmin(request, response);
    if (!session) return;
    const telegramUserId = normalizeTelegramUserId(url.searchParams.get('telegramUserId'));
    const grants = store.grants
      .filter((grant) => grant.telegramUserId === telegramUserId)
      .map((grant) => ({ ...grant, badge: publicTemplate(templateById(grant.badgeId) || { id: grant.badgeId, slug: 'deleted', label: 'Deleted', background: '#FF555555', text: '#FFFFFFFF', scopes: [], enabled: false, createdAt: '' }) }));
    return sendJson(response, 200, { telegramUserId, grants });
  }

  if (path === '/api/admin/grants' && request.method === 'POST') {
    const session = requireAdmin(request, response, { mutate: true });
    if (!session) return;
    const body = await readJson(request);
    const telegramUserId = normalizeTelegramUserId(body.telegramUserId);
    const reason = String(body.reason ?? '').trim();
    if (reason.length > 240) throw new HttpError(400, 'invalid_reason', 'Reason must be at most 240 characters');
    const grant = await mutate((candidate) => {
      const badge = candidate.badgeTemplates.find((item) => item.id === body.badgeId && item.enabled);
      if (!badge) throw new HttpError(400, 'badge_not_available', 'Choose an enabled badge template');
      const activeDuplicate = candidate.grants.find((item) => item.telegramUserId === telegramUserId && item.badgeId === badge.id && !item.revokedAt);
      if (activeDuplicate) throw new HttpError(409, 'grant_exists', 'This active badge is already granted to the user');
      const created = {
        id: randomUUID(), telegramUserId, badgeId: badge.id, reason,
        issuedAt: now(), issuedBy: session.admin.id,
        expiresAt: normalizeExpiry(body.expiresAt), revokedAt: null, revokedBy: null,
      };
      candidate.grants.push(created);
      audit(candidate, session.admin, 'badge_grant.create', created.id, { telegramUserId, badgeSlug: badge.slug, expiresAt: created.expiresAt });
      return created;
    });
    return sendJson(response, 201, { grant });
  }

  const grantMatch = path.match(/^\/api\/admin\/grants\/([\w-]+)$/);
  if (grantMatch && request.method === 'DELETE') {
    const session = requireAdmin(request, response, { mutate: true });
    if (!session) return;
    const grant = await mutate((candidate) => {
      const found = candidate.grants.find((item) => item.id === grantMatch[1]);
      if (!found) throw new HttpError(404, 'grant_not_found', 'Badge grant not found');
      if (!found.revokedAt) {
        found.revokedAt = now();
        found.revokedBy = session.admin.id;
        audit(candidate, session.admin, 'badge_grant.revoke', found.id, { telegramUserId: found.telegramUserId });
      }
      return found;
    });
    return sendJson(response, 200, { grant });
  }

  if (path === '/api/admin/audit' && request.method === 'GET') {
    const session = requireAdmin(request, response);
    if (!session) return;
    return sendJson(response, 200, { entries: store.audit.slice(0, 100) });
  }

  if (path.startsWith('/api/')) return sendError(response, 404, 'not_found', 'API route not found');
  return serveStatic(path, response);
}

async function serveStatic(pathname, response) {
  const requestPath = pathname === '/' ? '/index.html' : pathname;
  const safePath = normalize(requestPath).replace(/^[/\\]+/, '');
  const filePath = resolve(publicDir, safePath);
  if (!filePath.startsWith(`${publicDir}/`) && filePath !== publicDir) {
    return sendError(response, 403, 'forbidden', 'Forbidden');
  }
  try {
    const content = await readFile(filePath);
    response.writeHead(200, {
      'Content-Type': MIME_TYPES[extname(filePath)] || 'application/octet-stream',
      'Content-Length': content.length,
      'Cache-Control': 'no-cache',
      'Content-Security-Policy': "default-src 'self'; base-uri 'none'; form-action 'self'; frame-ancestors 'none'; object-src 'none'; style-src 'self'; script-src 'self'",
      'Referrer-Policy': 'no-referrer',
      'X-Content-Type-Options': 'nosniff',
      'X-Frame-Options': 'DENY',
    });
    response.end(content);
  } catch {
    sendError(response, 404, 'not_found', 'Page not found');
  }
}

const server = createServer(async (request, response) => {
  try {
    await route(request, response);
  } catch (error) {
    if (error instanceof HttpError) {
      sendError(response, error.status, error.code, error.message);
      return;
    }
    console.error(`[${now()}] request failed`, error);
    sendError(response, 500, 'internal_error', 'Unexpected server error');
  }
});

server.listen(port, host, () => {
  console.log(`VSVD Control Plane listening on http://${host}:${port}`);
  console.log(`Data store: ${storePath}`);
  if (!store.admins.length) {
    if (allowInsecureFirstAdmin) console.warn('Development mode: first-admin setup is enabled without a bootstrap token.');
    else console.warn('No administrator exists. Set VSVD_BOOTSTRAP_TOKEN before production setup.');
  }
});
