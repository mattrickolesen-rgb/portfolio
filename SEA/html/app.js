const app = document.getElementById('app');
const profileEl = document.getElementById('profile');
const samplesEl = document.getElementById('samples');
const compareResultEl = document.getElementById('compareResult');
const bloodTypeEl = document.getElementById('bloodType');

let selectedSampleId = null;

function post(name, data = {}) {
  return fetch(`https://${GetParentResourceName()}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data)
  });
}

function setProfile(profile, targetName) {
  if (!profile) {
    profileEl.innerHTML = '<div class="muted">Ingen person scannet.</div>';
    return;
  }

  profileEl.innerHTML = `
    <div><strong>Navn:</strong> ${targetName || 'Ukendt'}</div>
    <div><strong>ID:</strong> ${profile.identifier}</div>
    <div><strong>Blodtype:</strong> ${profile.blood_type || 'Ukendt'}</div>
    <div><strong>DNA:</strong> ${profile.dna_hash || 'Ukendt'}</div>
    <div><strong>Fingeraftryk:</strong> ${profile.fingerprint_hash || 'Ukendt'}</div>
  `;
  bloodTypeEl.value = profile.blood_type || '';
}

function setSamples(samples) {
  samplesEl.innerHTML = '';
  selectedSampleId = null;
  compareResultEl.textContent = 'Ingen match endnu.';
  compareResultEl.classList.add('muted');

  if (!samples || samples.length === 0) {
    samplesEl.innerHTML = '<div class="muted">Ingen prøver.</div>';
    return;
  }

  samples.forEach((sample) => {
    const el = document.createElement('div');
    el.className = 'sample';
    el.dataset.id = sample.id;
    el.innerHTML = `
      <div><strong>#${sample.id}</strong> ${sample.sample_type}</div>
      <div>${sample.dna_hash || sample.fingerprint_hash || ''}</div>
      <div>${sample.blood_type ? `Blodtype: ${sample.blood_type}` : ''}</div>
      <div class="muted">${sample.collected_at || ''}</div>
    `;
    el.addEventListener('click', () => {
      document.querySelectorAll('.sample').forEach((node) => node.classList.remove('selected'));
      el.classList.add('selected');
      selectedSampleId = sample.id;
    });
    samplesEl.appendChild(el);
  });
}

window.addEventListener('message', (event) => {
  const data = event.data;
  if (data.action === 'open') {
    app.classList.remove('hidden');
  }
  if (data.action === 'close') {
    app.classList.add('hidden');
  }
  if (data.action === 'profile') {
    setProfile(data.profile, data.targetName);
  }
  if (data.action === 'samples') {
    setSamples(data.samples);
  }
  if (data.action === 'compareResult') {
    compareResultEl.classList.remove('muted');
    compareResultEl.textContent = data.match ? 'Match: JA' : 'Match: NEJ';
  }
});

document.getElementById('closeBtn').addEventListener('click', () => post('close'));
document.getElementById('scanBtn').addEventListener('click', () => post('scanNearest'));
document.getElementById('fingerBtn').addEventListener('click', () => post('collectFingerprint'));
document.getElementById('salivaBtn').addEventListener('click', () => post('collectSaliva'));
document.getElementById('bloodBtn').addEventListener('click', () => post('collectBlood'));
document.getElementById('setBloodBtn').addEventListener('click', () => {
  const bloodType = bloodTypeEl.value;
  if (!bloodType) return;
  post('setBloodType', { bloodType });
});
document.getElementById('compareBtn').addEventListener('click', () => {
  if (!selectedSampleId) return;
  post('compareSample', { sampleId: selectedSampleId });
});
