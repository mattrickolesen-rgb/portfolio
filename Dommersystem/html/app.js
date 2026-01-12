const app = document.getElementById('app');
const closeBtn = document.getElementById('close');
const queryInput = document.getElementById('query');
const searchBtn = document.getElementById('doSearch');
const statusEl = document.getElementById('status');
const listEl = document.getElementById('list');
const countEl = document.getElementById('count');
const modeNameBtn = document.getElementById('modeName');
const modeIdBtn = document.getElementById('modeId');
const queueListEl = document.getElementById('queueList');
const queueCountEl = document.getElementById('queueCount');
const activeCaseEl = document.getElementById('activeCase');
const verdictSelect = document.getElementById('verdict');
const caseNotesInput = document.getElementById('caseNotes');
const reasonInput = document.getElementById('reason');
const jailMinutesInput = document.getElementById('jailMinutes');
const fineAmountInput = document.getElementById('fineAmount');
const jailBtn = document.getElementById('jailBtn');
const fineBtn = document.getElementById('fineBtn');
const closeCaseBtn = document.getElementById('closeCaseBtn');
const tabButtons = Array.from(document.querySelectorAll('.tabs__btn'));
const tabPanels = Array.from(document.querySelectorAll('[data-tab-panel]'));
const quickTargetIdInput = document.getElementById('quickTargetId');
const quickTargetNameInput = document.getElementById('quickTargetName');
const quickAmountInput = document.getElementById('quickAmount');
const quickMessageInput = document.getElementById('quickMessage');
const quickFineBtn = document.getElementById('quickFineBtn');
const quickSmsBtn = document.getElementById('quickSmsBtn');

let mode = 'name';
let activeCase = null;

function setStatus(text, tone) {
  statusEl.textContent = text;
  statusEl.style.color = tone === 'error' ? '#eb5757' : '';
}

function setMode(next) {
  mode = next;
  modeNameBtn.classList.toggle('is-active', mode === 'name');
  modeIdBtn.classList.toggle('is-active', mode === 'id');
  queryInput.placeholder = mode === 'id' ? 'Indtast borger ID' : 'Indtast navn eller reg/telefon';
}

function setTab(tabId) {
  tabButtons.forEach((btn) => {
    btn.classList.toggle('is-active', btn.dataset.tab === tabId);
  });
  tabPanels.forEach((panel) => {
    panel.classList.toggle('tab--active', panel.dataset.tabPanel === tabId);
  });
}

function renderResults(results) {
  listEl.innerHTML = '';
  countEl.textContent = results.length;

  if (!results.length) {
    listEl.innerHTML = '<div class="empty">Ingen resultater</div>';
    return;
  }

  results.forEach((row) => {
    const item = document.createElement('div');
    item.className = 'result';

    const displayName = `${row.firstname ?? '-'} ${row.name ?? ''}`.trim();

    item.innerHTML = `
      <div>
        <div class="result__label">ID</div>
        <div class="result__value">${row.user_id ?? row.id ?? '-'}</div>
      </div>
      <div>
        <div class="result__label">Navn</div>
        <div class="result__value">${displayName}</div>
      </div>
      <div>
        <div class="result__label">Reg.</div>
        <div class="result__value">${row.registration ?? '-'}</div>
      </div>
      <div>
        <div class="result__label">Telefon</div>
        <div class="result__value">${row.phone ?? '-'}</div>
      </div>
      <div>
        <button class="btn btn--primary btn--small" data-action="add" data-id="${row.user_id ?? row.id ?? ''}" data-name="${displayName}">Tilføj</button>
        <button class="btn btn--ghost btn--small" data-action="quick" data-id="${row.user_id ?? row.id ?? ''}" data-name="${displayName}">Hurtig</button>
      </div>
    `;

    listEl.appendChild(item);
  });
}

const hasNui = typeof GetParentResourceName === 'function';

async function postNui(name, data) {
  if (!hasNui) {
    if (name === 'search') {
      const term = (data.term || '').toLowerCase();
      const rows = [
        { user_id: 1, firstname: 'Maja', name: 'Krogh', registration: 'AB12 345', phone: '32445566' },
        { user_id: 12, firstname: 'Ali', name: 'Rahman', registration: 'CD67 890', phone: '99887766' },
        { user_id: 42, firstname: 'Sofie', name: 'Nielsen', registration: 'EF55 220', phone: '22334455' }
      ];

      const filtered = rows.filter((row) => {
        if (data.byId) return String(row.user_id) === String(data.term);
        return (
          row.firstname.toLowerCase().includes(term) ||
          row.name.toLowerCase().includes(term) ||
          row.registration.toLowerCase().includes(term) ||
          row.phone.toLowerCase().includes(term)
        );
      });

      return { ok: true, results: filtered };
    }

    if (name === 'getQueue') {
      const queue = window.__mockQueue || [];
      const active = window.__mockActive || null;
      return { ok: true, queue, active };
    }

    if (name === 'addCase') {
      window.__mockQueue = window.__mockQueue || [];
      const caseId = window.__mockQueue.length + 1;
      const item = {
        id: caseId,
        target_id: data.target_id,
        target_name: data.target_name,
        created_at: new Date().toISOString()
      };
      window.__mockQueue.push(item);
      return { ok: true, case: item };
    }

    if (name === 'takeCase') {
      window.__mockQueue = window.__mockQueue || [];
      const idx = window.__mockQueue.findIndex((c) => c.id === data.case_id);
      if (idx >= 0) {
        const item = window.__mockQueue.splice(idx, 1)[0];
        window.__mockActive = item;
        return { ok: true, active: item };
      }
      return { ok: false, error: 'not_found' };
    }

    if (name === 'punish') {
      window.__mockActive = null;
      return { ok: true };
    }

    if (name === 'closeCase') {
      window.__mockActive = null;
      return { ok: true };
    }

    if (name === 'quickFine') {
      return { ok: true };
    }

    if (name === 'sendSms') {
      return { ok: true };
    }

    return { ok: true };
  }

  const resource = GetParentResourceName();
  const res = await fetch(`https://${resource}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data || {})
  });
  return res.json();
}

function renderQueue(queue) {
  queueListEl.innerHTML = '';
  queueCountEl.textContent = queue.length;

  if (!queue.length) {
    queueListEl.innerHTML = '<div class="empty">Ingen åbne sager</div>';
    return;
  }

  queue.forEach((item) => {
    const row = document.createElement('div');
    row.className = 'queue__item';
    row.innerHTML = `
      <div>
        <div class="result__value">#${item.id} ${item.target_name || 'Ukendt'}</div>
        <div class="queue__meta">Borger ID: ${item.target_id}</div>
      </div>
      <button class="btn btn--ghost btn--small" data-action="take" data-case-id="${item.id}">Tag sag</button>
    `;
    queueListEl.appendChild(row);
  });
}

function renderActiveCase(item) {
  activeCase = item || null;
  if (!activeCase) {
    activeCaseEl.classList.add('empty');
    activeCaseEl.textContent = 'Ingen sag taget';
    jailBtn.disabled = true;
    fineBtn.disabled = true;
    closeCaseBtn.disabled = true;
    verdictSelect.value = 'guilty';
    caseNotesInput.value = '';
    reasonInput.value = '';
    jailMinutesInput.value = '';
    fineAmountInput.value = '';
    return;
  }

  activeCaseEl.classList.remove('empty');
  activeCaseEl.innerHTML = `
    <div><strong>#${activeCase.id}</strong> ${activeCase.target_name || 'Ukendt'}</div>
    <div class="queue__meta">Borger ID: ${activeCase.target_id}</div>
  `;
  const isNotGuilty = verdictSelect.value === 'not_guilty';
  jailBtn.disabled = isNotGuilty;
  fineBtn.disabled = isNotGuilty;
  closeCaseBtn.disabled = false;
}

async function doSearch() {
  const term = queryInput.value.trim();
  if (!term) {
    setStatus('Indtast en søgeværdi', 'error');
    return;
  }

  setStatus('Søger...', 'info');

  try {
    const result = await postNui('search', { term, byId: mode === 'id' });
    if (!result.ok) {
      if (result.error === 'too_short') {
        setStatus('Søgeord er for kort', 'error');
      } else if (result.error === 'no_permission') {
        setStatus('Ingen adgang', 'error');
      } else {
        setStatus('Fejl ved søgning', 'error');
      }
      renderResults([]);
      return;
    }

    renderResults(result.results || []);
    setStatus('Klar');
  } catch (err) {
    setStatus('Fejl ved søgning', 'error');
  }
}

async function refreshQueue() {
  const result = await postNui('getQueue');
  if (result.ok) {
    renderQueue(result.queue || []);
    renderActiveCase(result.active || null);
  }
}

window.addEventListener('message', (event) => {
  const data = event.data;
  if (data.action === 'open') {
    app.classList.remove('hidden');
    queryInput.focus();
    refreshQueue();
  }
  if (data.action === 'close') {
    app.classList.add('hidden');
  }
});

closeBtn.addEventListener('click', () => {
  postNui('close');
});

searchBtn.addEventListener('click', doSearch);
queryInput.addEventListener('keydown', (event) => {
  if (event.key === 'Enter') {
    doSearch();
  }
});

listEl.addEventListener('click', async (event) => {
  const btn = event.target.closest('[data-action="add"]');
  const quickBtn = event.target.closest('[data-action="quick"]');

  if (btn) {
    const targetId = Number(btn.dataset.id);
    if (!targetId) return;
    const targetName = btn.dataset.name || 'Ukendt';
    const result = await postNui('addCase', { target_id: targetId, target_name: targetName });
  if (result.ok) {
    refreshQueue();
    setStatus('Sag tilføjet');
  } else {
    setStatus('Kunne ikke tilføje sag', 'error');
  }
}

  if (quickBtn) {
    quickTargetIdInput.value = quickBtn.dataset.id || '';
    quickTargetNameInput.value = quickBtn.dataset.name || '';
    setTab('quick');
  }
});

queueListEl.addEventListener('click', async (event) => {
  const btn = event.target.closest('[data-action="take"]');
  if (!btn) return;
  const caseId = Number(btn.dataset.caseId);
  if (!caseId) return;
  const result = await postNui('takeCase', { case_id: caseId });
  if (result.ok) {
    renderActiveCase(result.active || null);
    refreshQueue();
  } else {
    setStatus('Kunne ikke tage sag', 'error');
  }
});

jailBtn.addEventListener('click', async () => {
  if (!activeCase) return;
  if (verdictSelect.value === 'not_guilty') {
    setStatus('Kan ikke give straf når sag er ikke skyldig', 'error');
    return;
  }
  const minutes = Number(jailMinutesInput.value);
  if (!minutes || minutes <= 0) {
    setStatus('Indtast fængsel minutter', 'error');
    return;
  }
  const reason = reasonInput.value.trim();
  const result = await postNui('punish', {
    case_id: activeCase.id,
    action: 'jail',
    value: minutes,
    reason,
    verdict: verdictSelect.value,
    notes: caseNotesInput.value.trim()
  });
  if (result.ok) {
    setStatus('Fængsel givet');
    renderActiveCase(null);
    refreshQueue();
  } else {
    setStatus('Kunne ikke give fængsel', 'error');
  }
});

fineBtn.addEventListener('click', async () => {
  if (!activeCase) return;
  if (verdictSelect.value === 'not_guilty') {
    setStatus('Kan ikke give straf når sag er ikke skyldig', 'error');
    return;
  }
  const amount = Number(fineAmountInput.value);
  if (!amount || amount <= 0) {
    setStatus('Indtast bøde beløb', 'error');
    return;
  }
  const reason = reasonInput.value.trim();
  const result = await postNui('punish', {
    case_id: activeCase.id,
    action: 'fine',
    value: amount,
    reason,
    verdict: verdictSelect.value,
    notes: caseNotesInput.value.trim()
  });
  if (result.ok) {
    setStatus('Bøde givet');
    renderActiveCase(null);
    refreshQueue();
  } else {
    setStatus('Kunne ikke give bøde', 'error');
  }
});

closeCaseBtn.addEventListener('click', async () => {
  if (!activeCase) return;
  const result = await postNui('closeCase', {
    case_id: activeCase.id,
    verdict: verdictSelect.value,
    notes: caseNotesInput.value.trim()
  });
  if (result.ok) {
    setStatus('Sag afsluttet');
    renderActiveCase(null);
    refreshQueue();
  } else {
    setStatus('Kunne ikke afslutte sag', 'error');
  }
});

quickFineBtn.addEventListener('click', async () => {
  const targetId = Number(quickTargetIdInput.value);
  if (!targetId) {
    setStatus('Indtast borger ID', 'error');
    return;
  }
  const amount = Number(quickAmountInput.value);
  if (!amount || amount <= 0) {
    setStatus('Indtast bøde beløb', 'error');
    return;
  }
  const message = quickMessageInput.value.trim();
  const result = await postNui('quickFine', {
    target_id: targetId,
    target_name: quickTargetNameInput.value.trim(),
    amount,
    message
  });
  if (result.ok) {
    setStatus('Bøde sendt');
  } else {
    setStatus('Kunne ikke sende bøde', 'error');
  }
});

quickSmsBtn.addEventListener('click', async () => {
  const targetId = Number(quickTargetIdInput.value);
  if (!targetId) {
    setStatus('Indtast borger ID', 'error');
    return;
  }
  const message = quickMessageInput.value.trim();
  if (!message) {
    setStatus('Indtast SMS besked', 'error');
    return;
  }
  const result = await postNui('sendSms', {
    target_id: targetId,
    target_name: quickTargetNameInput.value.trim(),
    message
  });
  if (result.ok) {
    setStatus('SMS sendt');
  } else {
    setStatus('Kunne ikke sende SMS', 'error');
  }
});

verdictSelect.addEventListener('change', () => {
  if (!activeCase) return;
  const isNotGuilty = verdictSelect.value === 'not_guilty';
  jailBtn.disabled = isNotGuilty;
  fineBtn.disabled = isNotGuilty;
});

document.addEventListener('keydown', (event) => {
  if (event.key === 'Escape') {
    postNui('close');
  }
});

modeNameBtn.addEventListener('click', () => setMode('name'));
modeIdBtn.addEventListener('click', () => setMode('id'));
tabButtons.forEach((btn) => {
  btn.addEventListener('click', () => setTab(btn.dataset.tab));
});

setMode('name');
setStatus('Klar');
renderActiveCase(null);
setTab('search');

if (!hasNui) {
  app.classList.remove('hidden');
  refreshQueue();
}
