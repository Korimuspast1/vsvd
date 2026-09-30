const $ = (selector) => document.querySelector(selector);
const state = { csrfToken: sessionStorage.getItem('vsvd.csrf') || '', badges: [] };

function showNotice(message, error = false) {
  const element = $('#notice');
  element.textContent = message;
  element.hidden = !message;
  element.classList.toggle('error', error);
}

function setBusy(form, busy) {
  for (const element of form.querySelectorAll('button, input, select')) element.disabled = busy;
}

async function api(path, options = {}) {
  const headers = { Accept: 'application/json', ...(options.headers || {}) };
  if (options.body) headers['Content-Type'] = 'application/json';
  if (state.csrfToken && !['GET', 'HEAD'].includes(options.method || 'GET')) headers['X-CSRF-Token'] = state.csrfToken;
  const response = await fetch(path, { ...options, headers, credentials: 'same-origin' });
  const data = await response.json().catch(() => ({}));
  if (!response.ok) throw new Error(data.error?.message || `HTTP ${response.status}`);
  return data;
}

function cssColor(androidColor) {
  // Android stores #AARRGGBB while CSS uses #RRGGBBAA.
  return /^#[0-9a-f]{8}$/i.test(androidColor)
    ? `#${androidColor.slice(3)}${androidColor.slice(1, 3)}`
    : androidColor;
}

function badgeChip(badge) {
  const chip = document.createElement('span');
  chip.className = 'badge-chip';
  chip.textContent = badge.label;
  chip.style.background = cssColor(badge.background);
  chip.style.color = cssColor(badge.text);
  return chip;
}

function showDashboard(admin) {
  $('#auth-card').hidden = true;
  $('#dashboard').hidden = false;
  $('#admin-name').textContent = admin.username;
  $('#public-endpoint').textContent = `${location.origin}/api/v1/badges/users/{Telegram User ID}`;
}

async function loadDashboard() {
  const [badgesResponse, auditResponse] = await Promise.all([api('/api/admin/badges'), api('/api/admin/audit')]);
  state.badges = badgesResponse.badges;
  renderBadges();
  renderAudit(auditResponse.entries);
}

function renderBadges() {
  const list = $('#badge-list');
  const select = $('#grant-badge');
  list.replaceChildren();
  select.replaceChildren();
  const first = new Option(state.badges.length ? 'Выбери шаблон' : 'Сначала создай бейдж', '');
  first.disabled = true;
  first.selected = true;
  select.append(first);
  if (!state.badges.length) {
    const empty = document.createElement('p');
    empty.className = 'grant-list empty';
    empty.textContent = 'Шаблонов ещё нет.';
    list.append(empty);
  }
  for (const badge of state.badges) {
    const row = document.createElement('div');
    row.className = 'badge-row';
    row.append(badgeChip(badge));
    const details = document.createElement('div');
    const name = document.createElement('b');
    name.textContent = badge.slug;
    const meta = document.createElement('small');
    meta.textContent = `${badge.scopes.join(' · ')}${badge.enabled ? '' : ' · выключен'}`;
    details.append(name, meta);
    row.append(details);
    const toggle = document.createElement('button');
    toggle.className = 'secondary';
    toggle.textContent = badge.enabled ? 'Выключить' : 'Включить';
    toggle.addEventListener('click', async () => {
      try {
        await api(`/api/admin/badges/${badge.id}`, { method: 'PATCH', body: JSON.stringify({ enabled: !badge.enabled }) });
        showNotice('Статус шаблона обновлён.');
        await refresh();
      } catch (error) { showNotice(error.message, true); }
    });
    row.append(toggle);
    list.append(row);
    if (badge.enabled) select.append(new Option(`${badge.label} (${badge.slug})`, badge.id));
  }
}

function renderAudit(entries) {
  const list = $('#audit-list');
  list.replaceChildren();
  if (!entries.length) {
    list.textContent = 'Действий пока нет.';
    return;
  }
  for (const entry of entries) {
    const row = document.createElement('div');
    row.className = 'audit-row';
    const details = document.createElement('div');
    const action = document.createElement('b');
    action.textContent = entry.action;
    const meta = document.createElement('small');
    meta.textContent = `${entry.adminName} · ${entry.target}`;
    details.append(action, meta);
    const time = document.createElement('time');
    time.dateTime = entry.at;
    time.textContent = new Date(entry.at).toLocaleString();
    row.append(details, time);
    list.append(row);
  }
}

function renderGrants(response) {
  const list = $('#grant-list');
  list.classList.remove('empty');
  list.replaceChildren();
  if (!response.grants.length) {
    list.classList.add('empty');
    list.textContent = 'У этого User ID нет выдач.';
    return;
  }
  for (const grant of response.grants) {
    const row = document.createElement('div');
    row.className = `grant-row${grant.revokedAt ? ' revoked' : ''}`;
    row.append(badgeChip(grant.badge));
    const details = document.createElement('div');
    const name = document.createElement('b');
    name.textContent = grant.badge.label;
    const meta = document.createElement('small');
    const expiry = grant.expiresAt ? `до ${new Date(grant.expiresAt).toLocaleString()}` : 'без срока';
    meta.textContent = `${expiry}${grant.reason ? ` · ${grant.reason}` : ''}${grant.revokedAt ? ' · отозван' : ''}`;
    details.append(name, meta);
    row.append(details);
    if (!grant.revokedAt) {
      const revoke = document.createElement('button');
      revoke.className = 'secondary';
      revoke.textContent = 'Отозвать';
      revoke.addEventListener('click', async () => {
        if (!confirm(`Отозвать «${grant.badge.label}»?`)) return;
        try {
          await api(`/api/admin/grants/${grant.id}`, { method: 'DELETE' });
          showNotice('Бейдж отозван.');
          await lookupGrants();
          await refresh();
        } catch (error) { showNotice(error.message, true); }
      });
      row.append(revoke);
    }
    list.append(row);
  }
}

async function lookupGrants() {
  const userId = $('#lookup-user-id').value.trim();
  if (!/^[1-9][0-9]{0,18}$/.test(userId)) {
    showNotice('Введи корректный положительный Telegram User ID.', true);
    return;
  }
  const response = await api(`/api/admin/grants?telegramUserId=${encodeURIComponent(userId)}`);
  renderGrants(response);
}

async function refresh() {
  await loadDashboard();
  const id = $('#lookup-user-id').value.trim();
  if (/^[1-9][0-9]{0,18}$/.test(id)) await lookupGrants();
}

async function establishSession(response) {
  state.csrfToken = response.csrfToken;
  sessionStorage.setItem('vsvd.csrf', state.csrfToken);
  showDashboard(response.admin);
  await loadDashboard();
}

$('#bootstrap-form').addEventListener('submit', async (event) => {
  event.preventDefault();
  const form = event.currentTarget;
  setBusy(form, true);
  try {
    const values = new FormData(form);
    await establishSession(await api('/api/admin/bootstrap', { method: 'POST', body: JSON.stringify(Object.fromEntries(values)) }));
    showNotice('Первый администратор создан.');
  } catch (error) { showNotice(error.message, true); }
  finally { setBusy(form, false); }
});

$('#login-form').addEventListener('submit', async (event) => {
  event.preventDefault();
  const form = event.currentTarget;
  setBusy(form, true);
  try {
    const values = new FormData(form);
    await establishSession(await api('/api/admin/login', { method: 'POST', body: JSON.stringify(Object.fromEntries(values)) }));
  } catch (error) { showNotice(error.message, true); }
  finally { setBusy(form, false); }
});

$('#badge-form').addEventListener('submit', async (event) => {
  event.preventDefault();
  const form = event.currentTarget;
  const values = new FormData(form);
  const scopes = [...form.querySelectorAll('input[name="scope"]:checked')].map((input) => input.value);
  setBusy(form, true);
  try {
    await api('/api/admin/badges', { method: 'POST', body: JSON.stringify({
      label: values.get('label'), slug: values.get('slug'), background: values.get('background'), text: values.get('text'), scopes,
    }) });
    form.reset();
    form.querySelector('input[value="PROFILE"]').checked = true;
    form.querySelector('input[value="USER_LIST"]').checked = true;
    showNotice('Шаблон бейджа создан.');
    await refresh();
  } catch (error) { showNotice(error.message, true); }
  finally { setBusy(form, false); }
});

$('#grant-form').addEventListener('submit', async (event) => {
  event.preventDefault();
  const form = event.currentTarget;
  const values = Object.fromEntries(new FormData(form));
  setBusy(form, true);
  try {
    await api('/api/admin/grants', { method: 'POST', body: JSON.stringify(values) });
    $('#lookup-user-id').value = values.telegramUserId;
    showNotice('Бейдж выдан. Клиент пользователя увидит его после синхронизации.');
    await refresh();
  } catch (error) { showNotice(error.message, true); }
  finally { setBusy(form, false); }
});

$('#lookup-grants').addEventListener('click', () => lookupGrants().catch((error) => showNotice(error.message, true)));
$('#logout').addEventListener('click', async () => {
  try { await api('/api/admin/logout', { method: 'POST' }); } catch (_) { /* session is cleared locally regardless */ }
  state.csrfToken = '';
  sessionStorage.removeItem('vsvd.csrf');
  $('#dashboard').hidden = true;
  $('#auth-card').hidden = false;
  $('#login-view').hidden = false;
  showNotice('Сессия завершена.');
});

async function initialize() {
  try {
    await api('/api/v1/health');
    $('#server-status').textContent = 'API подключён';
    $('.dot').classList.add('online');
    try {
      const me = await api('/api/admin/me');
      await establishSession(me);
      return;
    } catch (_) { /* no existing session */ }
    const bootstrap = await api('/api/admin/bootstrap');
    if (bootstrap.initialized) $('#login-view').hidden = false;
    else if (bootstrap.setupAllowed) $('#bootstrap-view').hidden = false;
    else $('#bootstrap-disabled').hidden = false;
  } catch (error) {
    $('#server-status').textContent = 'API недоступен';
    showNotice(`Не удалось подключиться к серверу: ${error.message}`, true);
  }
}

initialize();
