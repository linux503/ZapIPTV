import { DEFAULT_SOURCES, GROUP_ORDER, normaliseGroup, refineRegionalExtra, curateRegionalChannels } from './catalog.js';
import { parseM3U } from './m3u.js';
import { refineChinese } from './chinese.js';
import { t } from './i18n.js';
import { groupIconHTML, groupTitle } from './group-icons.js';

const state = {
  lang: localStorage.getItem('zap-lang') || 'hant',
  theme: localStorage.getItem('zap-theme') || 'dark',
  channels: [],
  selectedGroup: '🇨🇳 中国大陆',
  current: null,
  hls: null,
};

const $ = (s) => document.querySelector(s);
const $$ = (s) => [...document.querySelectorAll(s)];

function applyI18n() {
  const L = state.lang;
  $('#tagline').textContent = t('tagline', L);
  $('#nav-home').textContent = t('home', L);
  $('#nav-live').textContent = t('live', L);
  $('#nav-settings').textContent = t('settings', L);
  $('#cat-label').textContent = t('categories', L);
  $('#search').placeholder = t('search', L);
  $('#now-label').textContent = t('nowPlaying', L);
  $('#empty-player').textContent = t('select', L);
  $('#settings-title').textContent = t('settings', L);
  $('#lang-label').textContent = t('language', L);
  $('#theme-label').textContent = t('theme', L);
  $('#ver-label').textContent = t('version', L);
  $('#opt-hant').textContent = t('langHant', L);
  $('#opt-hans').textContent = t('langHans', L);
  const optEn = $('#opt-en');
  if (optEn) optEn.textContent = t('langEn', L);
  $('#opt-dark').textContent = t('themeDark', L);
  $('#opt-light').textContent = t('themeLight', L);
  $('#btn-refresh').textContent = t('refresh', L);
  $('#load-msg').textContent = t('loading', L);
}

function applyTheme() {
  document.body.dataset.theme = state.theme;
  $$('[data-theme]').forEach((el) => {
    if (el.dataset.theme === 'dark' || el.dataset.theme === 'light') {
      el.classList.toggle('active', el.dataset.theme === state.theme);
    }
  });
}

function groups() {
  const set = new Set(state.channels.map((c) => c.group));
  return GROUP_ORDER.filter((g) => set.has(g));
}

function channelsInGroup(g) {
  return state.channels.filter((c) => c.group === g);
}

async function loadCatalog() {
  $('#loader').classList.remove('hidden');
  const all = [];
  for (const src of DEFAULT_SOURCES) {
    try {
      const res = await fetch(src.url, { cache: 'no-store' });
      if (!res.ok) continue;
      const text = await res.text();
      let list = parseM3U(text, src.url);
      list = refineChinese(list, src.url);
      list = refineRegionalExtra(list, src.url);
      list = list.map((ch) => ({
        ...ch,
        group: src.overrideGroup || ch.group,
      }));
      if (src.overrideGroup) {
        list = curateRegionalChannels(list, src.overrideGroup);
      } else {
        const byGroup = {};
        for (const ch of list) {
          (byGroup[ch.group] ||= []).push(ch);
        }
        list = Object.entries(byGroup).flatMap(([g, arr]) => curateRegionalChannels(arr, g));
      }
      all.push(...list);
    } catch { /* skip failed source */ }
  }
  state.channels = all;
  if (!groups().includes(state.selectedGroup)) {
    state.selectedGroup = groups()[0] || '🇨🇳 中国大陆';
  }
  $('#loader').classList.add('hidden');
  renderHome();
  renderGroups();
  renderChannelList();
}

function letterFor(name) {
  const s = String(name || '').trim();
  return (s[0] || '?').toUpperCase();
}

function thumbHTML(ch, kind) {
  const letter = esc(letterFor(ch.name));
  if (ch.logo) {
    return `<div class="${kind}"><img src="${esc(ch.logo)}" alt="" loading="lazy" decoding="async" /></div>`;
  }
  return `<div class="${kind}"><span class="letter">${letter}</span></div>`;
}

function renderHome() {
  const root = $('#home-sections');
  root.innerHTML = '';
  const frag = document.createDocumentFragment();
  for (const g of groups().slice(0, 8)) {
    const list = channelsInGroup(g).slice(0, 16);
    if (!list.length) continue;
    const sec = document.createElement('div');
    sec.className = 'section';
    sec.innerHTML = `<h3>${groupIconHTML(g)}<span>${esc(groupTitle(g))}</span></h3>`;
    const row = document.createElement('div');
    row.className = 'row';
    for (const ch of list) {
      const el = document.createElement('button');
      el.type = 'button';
      el.className = 'chip';
      el.innerHTML = `${thumbHTML(ch, 'thumb')}<span>${esc(ch.name)}</span>`;
      el.onclick = () => {
        switchTab('live');
        play(ch);
        state.selectedGroup = ch.group;
        renderGroups();
        renderChannelList();
      };
      row.appendChild(el);
    }
    sec.appendChild(row);
    frag.appendChild(sec);
  }
  root.appendChild(frag);
}

function renderGroups() {
  const root = $('#group-list');
  root.innerHTML = '';
  const frag = document.createDocumentFragment();
  for (const g of groups()) {
    const btn = document.createElement('button');
    btn.type = 'button';
    btn.className = 'group-btn' + (g === state.selectedGroup ? ' active' : '');
    btn.innerHTML = `${groupIconHTML(g)}<span class="g-label">${esc(groupTitle(g))}</span>`;
    btn.title = g;
    btn.onclick = () => { state.selectedGroup = g; renderGroups(); renderChannelList(); };
    frag.appendChild(btn);
  }
  root.appendChild(frag);
}

function renderChannelList() {
  const q = ($('#search').value || '').trim().toLowerCase();
  let list = channelsInGroup(state.selectedGroup);
  if (q) list = list.filter((c) => c.name.toLowerCase().includes(q));
  const root = $('#channel-list');
  root.innerHTML = '';
  const frag = document.createDocumentFragment();
  for (const ch of list.slice(0, 400)) {
    const row = document.createElement('button');
    row.type = 'button';
    row.className = 'ch-row' + (state.current?.id === ch.id ? ' playing' : '');
    row.dataset.id = ch.id;
    row.innerHTML = `
      ${thumbHTML(ch, 'ch-logo')}
      <div class="meta"><div class="name">${esc(ch.name)}</div><div class="grp">${esc(ch.group)}</div></div>`;
    row.onclick = () => play(ch);
    frag.appendChild(row);
  }
  root.appendChild(frag);
  updateNowBar();
}

function switchTab(name) {
  $$('.nav-btn').forEach((b) => b.classList.toggle('active', b.dataset.tab === name));
  $$('.view').forEach((v) => {
    const on = v.id === `view-${name}`;
    v.classList.toggle('active', on);
  });
  // Keep live player attached; only pause when leaving live if buffering forever
}

let searchTimer = 0;
$('#search').oninput = () => {
  clearTimeout(searchTimer);
  searchTimer = setTimeout(() => renderChannelList(), 120);
};


function updateNowBar() {
  const bar = $('#now-bar');
  if (!state.current) { bar.classList.remove('show'); return; }
  bar.classList.add('show');
  $('#now-name').textContent = state.current.name;
  bar.onclick = () => {
    $('#search').value = '';
    state.selectedGroup = state.current.group;
    renderGroups();
    renderChannelList();
    const el = document.querySelector(`.ch-row[data-id="${state.current.id}"]`);
    el?.scrollIntoView({ block: 'center', behavior: 'smooth' });
  };
}

function play(ch) {
  state.current = ch;
  const video = $('#video');
  const empty = $('#empty-player');
  const bar = $('#player-bar');
  empty.style.display = 'none';
  video.style.display = 'block';
  bar.style.display = 'flex';
  $('#play-title').textContent = ch.name;
  $('#play-group').textContent = ch.group;
  if (state.hls) { state.hls.destroy(); state.hls = null; }
  video.removeAttribute('src');
  video.load();
  const url = ch.url;
  if (window.Hls && Hls.isSupported()) {
    state.hls = new Hls({ maxBufferLength: 30 });
    state.hls.loadSource(url);
    state.hls.attachMedia(video);
    state.hls.on(Hls.Events.MANIFEST_PARSED, () => video.play().catch(() => {}));
  } else if (video.canPlayType('application/vnd.apple.mpegurl')) {
    video.src = url;
    video.play().catch(() => {});
  } else {
    video.src = url;
  }
  renderChannelList();
}

function esc(s) {
  return String(s).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
}

$$('.nav-btn').forEach((btn) => {
  btn.onclick = () => switchTab(btn.dataset.tab);
});

$$('[data-lang]').forEach((btn) => {
  btn.onclick = () => {
    state.lang = btn.dataset.lang;
    localStorage.setItem('zap-lang', state.lang);
    $$('[data-lang]').forEach((b) => b.classList.toggle('active', b.dataset.lang === state.lang));
    applyI18n();
  };
});

$$('[data-theme]').forEach((btn) => {
  if (btn.dataset.theme !== 'dark' && btn.dataset.theme !== 'light') return;
  btn.onclick = () => {
    state.theme = btn.dataset.theme;
    localStorage.setItem('zap-theme', state.theme);
    applyTheme();
  };
});

$('#btn-refresh').onclick = () => loadCatalog();

applyI18n();
applyTheme();
$$('[data-lang]').forEach((b) => b.classList.toggle('active', b.dataset.lang === state.lang));
loadCatalog();
