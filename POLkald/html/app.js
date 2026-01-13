const app = document.getElementById('app');
const userBadge = document.getElementById('userBadge');
const staffTab = document.getElementById('staffTab');
const adminTab = document.getElementById('adminTab');
const adminDepartment = document.getElementById('adminDepartment');
const staffList = document.getElementById('staffList');
const toast = document.getElementById('toast');
const messageLog = document.getElementById('messageLog');
const incomingCallCard = document.getElementById('incomingCall');
const callTitle = document.getElementById('callTitle');
const callMeta = document.getElementById('callMeta');
const departmentsListEl = document.getElementById('departmentsList');

let currentState = null;
let activeCallId = null;

const isFiveM = typeof GetParentResourceName === 'function';
const send = (action, data = {}) => {
  if (!isFiveM) {
    console.log('[demo] send', action, data);
    return;
  }
  fetch(`https://${GetParentResourceName()}/${action}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data)
  });
};

const showToast = (text) => {
  toast.textContent = text;
  toast.classList.add('show');
  setTimeout(() => toast.classList.remove('show'), 2500);
};

const setDepartments = (list) => {
  adminDepartment.innerHTML = '';
  list.forEach((dept) => {
    const adminOption = document.createElement('option');
    adminOption.value = dept;
    adminOption.textContent = dept;
    adminDepartment.appendChild(adminOption);
  });
};

const setStaffList = (staff) => {
  staffList.innerHTML = '';

  staff.forEach((member) => {
    const card = document.createElement('div');
    card.className = 'staff-card';

    const meta = document.createElement('div');
    meta.className = 'staff-meta';
    meta.innerHTML = `<strong>${member.name} (#${member.user_id})</strong>`;

    const button = document.createElement('button');
    button.className = 'secondary';
    button.textContent = 'Ring';
    button.onclick = () => send('startCall', { kind: 'individual', user_id: member.user_id });

    card.appendChild(meta);
    card.appendChild(button);
    staffList.appendChild(card);
  });
};

const renderDepartments = (departments, staff) => {
  departmentsListEl.innerHTML = '';
  const staffByDept = {};

  staff.forEach((member) => {
    (member.departments || []).forEach((dept) => {
      if (!staffByDept[dept]) {
        staffByDept[dept] = [];
      }
      staffByDept[dept].push(member);
    });
  });

  departments.forEach((dept) => {
    const card = document.createElement('div');
    card.className = 'department-card';

    const header = document.createElement('div');
    header.className = 'department-header';
    header.innerHTML = `<strong>${dept}</strong><span>${(staffByDept[dept] || []).length} online</span>`;

    const callBtn = document.createElement('button');
    callBtn.className = 'secondary';
    callBtn.textContent = 'Ring afdeling';
    callBtn.onclick = () => send('startCall', { kind: 'department', department: dept });
    header.appendChild(callBtn);

    const members = document.createElement('div');
    members.className = 'department-members';
    const membersList = staffByDept[dept] || [];
    if (membersList.length === 0) {
      const empty = document.createElement('div');
      empty.className = 'department-member';
      empty.textContent = 'Ingen online lige nu';
      members.appendChild(empty);
    } else {
      membersList.forEach((member) => {
        const row = document.createElement('div');
        row.className = 'department-member';
        row.innerHTML = `<span>${member.name} (#${member.user_id})</span>`;
        const ring = document.createElement('button');
        ring.className = 'ghost';
        ring.textContent = 'Ring';
        ring.onclick = () => send('startCall', { kind: 'individual', user_id: member.user_id });
        row.appendChild(ring);
        members.appendChild(row);
      });
    }

    card.appendChild(header);
    card.appendChild(members);
    departmentsListEl.appendChild(card);
  });
};

const addMessage = (message) => {
  const entry = document.createElement('div');
  entry.className = 'log-item';
  const from = message.fromName ? `${message.fromName} (#${message.from})` : 'System';
  entry.textContent = `[${new Date().toLocaleTimeString()}] ${from}: ${message.text}`;
  messageLog.prepend(entry);
};

const showIncomingCall = (call) => {
  activeCallId = call.id;
  callTitle.textContent = call.emergency ? 'AKUT 112 OPKALD' : 'Indkommende opkald';
  callMeta.textContent = `${call.callerName} (#${call.caller}) | ${call.targetLabel}`;
  incomingCallCard.classList.remove('hidden');
};

const hideIncomingCall = () => {
  activeCallId = null;
  incomingCallCard.classList.add('hidden');
};

const setTabs = (active) => {
  document.querySelectorAll('.tab').forEach((tab) => {
    tab.classList.toggle('active', tab.dataset.tab === active);
  });
  document.querySelectorAll('.panel').forEach((panel) => {
    panel.classList.toggle('active', panel.id === `panel-${active}`);
  });
};

window.addEventListener('message', (event) => {
  const { type, state, call, message, payload } = event.data || {};

  if (type === 'open') {
    app.classList.remove('hidden');
    send('requestState');
  }

  if (type === 'close') {
    app.classList.add('hidden');
    hideIncomingCall();
  }

  if (type === 'state') {
    currentState = state;
    userBadge.textContent = `#${state.user_id} ${state.name}`;
    staffTab.style.display = state.isStaff ? 'inline-flex' : 'none';
    adminTab.style.display = state.isAdmin ? 'inline-flex' : 'none';
    setDepartments(state.departmentsList || []);
    setStaffList(state.onlineStaff || []);
    renderDepartments(state.departmentsList || [], state.onlineStaff || []);
  }

  if (type === 'incomingCall' && call) {
    showIncomingCall(call);
  }

  if (type === 'incomingMessage' && message) {
    addMessage(message);
  }

  if (type === 'callAnswered' && payload) {
    showToast(`Opkald besvaret af ${payload.byName}`);
  }

  if (type === 'callEnded') {
    hideIncomingCall();
  }

  if (type === 'notify') {
    showToast(event.data.message || 'Besked');
  }
});

document.getElementById('closeBtn').addEventListener('click', () => send('close'));

document.querySelectorAll('.tab').forEach((tab) => {
  tab.addEventListener('click', () => setTabs(tab.dataset.tab));
});

document.getElementById('sendCitizen').addEventListener('click', () => {
  const text = document.getElementById('citizenMessage').value.trim();
  if (!text) return;
  send('sendMessage', { text, scope: 'police' });
  document.getElementById('citizenMessage').value = '';
});

document.getElementById('callEmergency').addEventListener('click', () => {
  send('startCall', { kind: 'police', emergency: true });
});

document.getElementById('callVagthavende').addEventListener('click', () => {
  send('startCall', { kind: 'vagthavende' });
});

document.getElementById('callVagtchef').addEventListener('click', () => {
  send('startCall', { kind: 'vagtchef' });
});

document.getElementById('openDepartments').addEventListener('click', () => {
  setTabs('departments');
});

document.getElementById('backToStaff').addEventListener('click', () => {
  setTabs('staff');
});

document.getElementById('assignRole').addEventListener('click', () => {
  const userId = document.getElementById('adminUserId').value;
  const role = document.getElementById('adminRole').value || null;
  const department = adminDepartment.value || null;
  if (!userId) return;
  send('adminAssign', { user_id: userId, role, department });
});

document.getElementById('removeRole').addEventListener('click', () => {
  const userId = document.getElementById('adminUserId').value;
  const role = document.getElementById('adminRole').value || null;
  const department = adminDepartment.value || null;
  if (!userId) return;
  send('adminRemove', { user_id: userId, role, department });
});

document.getElementById('answerCall').addEventListener('click', () => {
  if (!activeCallId) return;
  send('answerCall', { id: activeCallId });
});

document.getElementById('endCall').addEventListener('click', () => {
  if (!activeCallId) return;
  send('endCall', { id: activeCallId });
});

setTabs('citizen');

if (!isFiveM) {
  document.body.classList.add('phone-preview');
  app.classList.remove('hidden');
  currentState = {
    user_id: 1001,
    name: 'Demo Borger',
    isStaff: true,
    isAdmin: true,
    departmentsList: [
      'Politiskolen',
      'BerdskGroen',
      'BerdskGul',
      'RKS',
      'OperativFaerdsel',
      'SagsAdmin',
      'NaerPolitiet',
      'Vagtcentralen'
    ],
    onlineStaff: [
      { user_id: 2001, name: 'A. Jensen', departments: ['Vagtcentralen', 'RKS'] },
      { user_id: 2002, name: 'M. Holm', departments: ['OperativFaerdsel'] }
    ]
  };
  userBadge.textContent = `#${currentState.user_id} ${currentState.name}`;
  staffTab.style.display = 'inline-flex';
  adminTab.style.display = 'inline-flex';
  setDepartments(currentState.departmentsList);
  setStaffList(currentState.onlineStaff);
  renderDepartments(currentState.departmentsList, currentState.onlineStaff);
  addMessage({ fromName: 'Vagtcentralen', from: 9999, text: 'Demo besked fra politiet.' });
  showIncomingCall({ id: 1, callerName: 'Demo Borger', caller: 1001, targetLabel: 'Vagtcentralen', emergency: false });
}
