const app = document.getElementById('app');
const imageEl = document.getElementById('image');
const counterEl = document.getElementById('counter');
const titleEl = document.getElementById('cameraTitle');
const closeBtn = document.getElementById('closeBtn');
const prevBtn = document.getElementById('prevBtn');
const nextBtn = document.getElementById('nextBtn');

let images = [];
let index = 0;

const update = () => {
  if (!images.length) {
    imageEl.src = '';
    counterEl.textContent = '0 / 0';
    return;
  }
  if (index < 0) index = images.length - 1;
  if (index > images.length - 1) index = 0;
  imageEl.src = images[index];
  counterEl.textContent = `${index + 1} / ${images.length}`;
};

const open = (payload) => {
  images = payload.images || [];
  index = 0;
  titleEl.textContent = payload.camera || 'CCTV';
  update();
  app.classList.remove('hidden');
};

const close = () => {
  app.classList.add('hidden');
  fetch(`https://${GetParentResourceName()}/close`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({})
  });
};

prevBtn.addEventListener('click', () => {
  index -= 1;
  update();
});

nextBtn.addEventListener('click', () => {
  index += 1;
  update();
});

closeBtn.addEventListener('click', close);

window.addEventListener('message', (event) => {
  const data = event.data || {};
  if (data.action === 'open') {
    open(data);
  }
  if (data.action === 'close') {
    app.classList.add('hidden');
  }
});

window.addEventListener('keydown', (event) => {
  if (app.classList.contains('hidden')) return;

  if (event.key === 'Escape') {
    close();
  } else if (event.key === 'ArrowLeft') {
    index -= 1;
    update();
  } else if (event.key === 'ArrowRight') {
    index += 1;
    update();
  }
});
