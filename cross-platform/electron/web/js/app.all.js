(function () {
'use strict';
const CDN = 'https://cdn.jsdelivr.net/gh/iptv-org/iptv@gh-pages';

const DEFAULT_SOURCES = [
  { name: '🇨🇳 中国大陆', url: `${CDN}/countries/cn.m3u`, overrideGroup: '🇨🇳 中国大陆' },
  { name: '🇨🇳 国内直播', url: 'https://cdn.jsdelivr.net/gh/vbskycn/iptv@master/tv/iptv4.m3u', overrideGroup: null },
  { name: '🇹🇼 台湾', url: `${CDN}/countries/tw.m3u`, overrideGroup: '🇹🇼 台湾' },
  { name: '🇹🇼🇭🇰 港澳台精选', url: 'https://cdn.jsdelivr.net/gh/suxuang/myIPTV@main/ipv4.m3u', overrideGroup: null },
  { name: '🇹🇼🇭🇰 港澳台备用', url: 'https://raw.githubusercontent.com/Guovin/iptv-api/gd/output/result.m3u', overrideGroup: null },
  { name: '🇭🇰 香港', url: `${CDN}/countries/hk.m3u`, overrideGroup: '🇭🇰 香港' },
  { name: '🇭🇰 香港直播', url: 'https://cdn.jsdelivr.net/gh/sammy0101/hk-iptv-auto@main/hk_live.m3u', overrideGroup: '🇭🇰 香港' },
  { name: '🇭🇰 粤语频道', url: `${CDN}/languages/yue.m3u`, overrideGroup: null },
  { name: '🇯🇵 日本', url: `${CDN}/countries/jp.m3u`, overrideGroup: '🇯🇵 日本' },
  { name: '🇰🇷 韩国', url: `${CDN}/countries/kr.m3u`, overrideGroup: '🇰🇷 韩国' },
  { name: '🇰🇷 韩语剧场', url: `${CDN}/languages/kor.m3u`, overrideGroup: null },
  { name: '🎬 亚洲电影', url: `${CDN}/categories/movies.m3u`, overrideGroup: null },
  { name: '📺 亚洲剧集', url: `${CDN}/categories/series.m3u`, overrideGroup: null },
  { name: '🎮 亚洲娱乐', url: `${CDN}/categories/entertainment.m3u`, overrideGroup: null },
  { name: '🇹🇭 泰国', url: `${CDN}/countries/th.m3u`, overrideGroup: '🇹🇭 泰国' },
  { name: '🇻🇳 越南', url: `${CDN}/countries/vn.m3u`, overrideGroup: '🇻🇳 越南' },
  { name: '🇮🇩 印尼', url: `${CDN}/countries/id.m3u`, overrideGroup: '🇮🇩 印尼' },
  { name: '🇲🇾 马来西亚', url: `${CDN}/countries/my.m3u`, overrideGroup: '🇲🇾 马来西亚' },
  { name: '🇸🇬 新加坡', url: `${CDN}/countries/sg.m3u`, overrideGroup: '🇸🇬 新加坡' },
  { name: '🇵🇭 菲律宾', url: `${CDN}/countries/ph.m3u`, overrideGroup: '🇵🇭 菲律宾' },
  { name: '🇮🇳 印度', url: `${CDN}/countries/in.m3u`, overrideGroup: '🇮🇳 印度' },
];

const GROUP_ORDER = [
  '🇨🇳 中国大陆', '🎬 华语影视', '🎆 春晚', '🇹🇼 台湾', '🇭🇰 香港',
  '🇯🇵 日本', '🇰🇷 韩国', '🇹🇭 泰国', '🇻🇳 越南',
  '🇮🇩 印尼', '🇲🇾 马来西亚', '🇸🇬 新加坡', '🇵🇭 菲律宾', '🇮🇳 印度',
];

function normaliseGroup(raw) {
  const s = (raw || '').toLowerCase();
  if (s.includes('china') || s.includes('中国') || s.includes('大陆')) return '🇨🇳 中国大陆';
  if (s.includes('taiwan') || s.includes('台湾') || s.includes('台灣')) return '🇹🇼 台湾';
  if (s.includes('hong') || s.includes('香港')) return '🇭🇰 香港';
  if (s.includes('japan') || s.includes('日本')) return '🇯🇵 日本';
  if (s.includes('korea') || s.includes('韩国') || s.includes('韓國')) return '🇰🇷 韩国';
  if (s.includes('thai') || s.includes('泰国') || s.includes('泰國')) return '🇹🇭 泰国';
  if (s.includes('viet') || s.includes('越南')) return '🇻🇳 越南';
  if (s.includes('indo') || s.includes('印尼')) return '🇮🇩 印尼';
  if (s.includes('malay') || s.includes('马来')) return '🇲🇾 马来西亚';
  if (s.includes('singapore') || s.includes('新加坡')) return '🇸🇬 新加坡';
  if (s.includes('phil') || s.includes('菲律宾')) return '🇵🇭 菲律宾';
  if (s.includes('india') || s.includes('印度')) return '🇮🇳 印度';
  if (s.includes('movie') || s.includes('film') || s.includes('电影') || s.includes('電影')) return '🎬 华语影视';
  if (s.includes('春晚')) return '🎆 春晚';
  return raw || '📡 综合';
}

const DRAMA_KEYS = [
  'drama', 'series', 'theater', 'theatre', 'movie', 'movies', 'film', 'cinema',
  'entertain', 'variety', 'showbiz', 'music', 'bollywood', 'zee', 'star', 'colors', 'sony',
  '戲劇', '戏剧', '劇', '剧', '劇場', '剧场', '影', '電影', '电影', '影院', '娛樂', '娱乐', '綜藝', '综艺',
  '音樂', '音乐', '偶像', '八大', '東森', '东森', '中天', 'TVBS', 'TVB', 'Viu', 'HOY', 'KBS', 'MBC', 'SBS',
  'GEM', 'AXN', 'Celestial', 'Cinema One', 'Viva Cinema', 'Tap Movies', '星河', '靖天', '纬来', '緯來',
  '龙华', '龍華', '美亚', '美亞',
];

const INDIA_NEWS_KEYS = [
  'news', 'समाचार', 'खबर', 'bharat', 'indiatv', 'speed news', 'aaj tak', 'republic',
  'times now', 'et now', 'mirror now', 'cnn-news18', 'cnbc', 'dd news', 'abp', 'lokshahi',
];

const KOREA_DROP = [
  'shopping', 'onstyle', 'homeshopping', 'home & shopping', 'kshopping', 'cj onstyle',
  'lotte home', 'hyundai home', 'gongyoung', 'gs my shop', 'buddhist', 'radio',
];

const TW_TOKENS = ['tvbs', 'cts', 'ftv', 'ttv', 'ctv', 'ebc', 'cti'];
const TW_TEXT = [
  'taiwan', '三立', '東森', '东森', '中天', '八大', '緯來', '纬来', '民視', '民视',
  '台视', '台視', '中视', '中視', '华视', '華視', '靖天', '龙华', '龍華', '公视', '公視',
  '影剧', '影劇', '戏剧', '戲劇', '都会', '都會', '欢乐', '歡樂', '超视', '超視',
  '洋片', '映画', '精采', '亚洲台', '亞洲台',
];
const HK_TOKENS = ['tvb', 'viu', 'hoy', 'rthk', 'nowtv'];
const HK_TEXT = [
  'hong kong', 'jade', 'pearl', 'celestial', '翡翠', '明珠', '港台', '無線', '无线',
  '有線', '有线', '鳳凰', '凤凰', '耀才', '星河', '华丽', '華麗', '美亚', '美亞',
];
const KOREA_KEYS = [
  'korea', 'korean', 'kbs', 'mbc', 'sbs', 'tvn', 'jtbc', 'arirang', 'ebs',
  'channel a', 'kpop',
];

function isDramaLike(name) {
  const s = name.toLowerCase();
  return DRAMA_KEYS.some((k) => s.includes(k.toLowerCase()));
}

function containsToken(haystack, token) {
  const s = haystack.toLowerCase();
  const t = token.toLowerCase();
  let start = 0;
  while (true) {
    const i = s.indexOf(t, start);
    if (i < 0) return false;
    const before = i === 0 || !/[a-z0-9]/i.test(s[i - 1]);
    const after = i + t.length >= s.length || !/[a-z0-9]/i.test(s[i + t.length]);
    if (before && after) return true;
    start = i + t.length;
  }
}

function isMainlandNoise(name) {
  const s = name.toLowerCase();
  if (s.includes('cctv') || s.includes('cntv') || s.includes('央视') || s.includes('央視')) return true;
  return false;
}

function isGeoBlocked(name) {
  const s = name.toLowerCase();
  return s.includes('geo-blocked') || s.includes('[geo');
}

function looksTaiwan(name) {
  if (isMainlandNoise(name)) return false;
  const s = name.toLowerCase();
  if (TW_TEXT.some((k) => s.includes(k.toLowerCase()))) return true;
  return TW_TOKENS.some((k) => containsToken(s, k));
}

function looksHongKong(name) {
  if (isMainlandNoise(name)) return false;
  const s = name.toLowerCase();
  if (HK_TEXT.some((k) => s.includes(k.toLowerCase()))) return true;
  return HK_TOKENS.some((k) => containsToken(s, k));
}

function keepIndiaChannel(name) {
  const s = name.toLowerCase();
  if (isDramaLike(s)) return true;
  return !INDIA_NEWS_KEYS.some((k) => s.includes(k));
}

function isKoreaNoise(name) {
  const s = name.toLowerCase();
  return KOREA_DROP.some((k) => s.includes(k));
}

function mapGreaterChina(name) {
  if (isMainlandNoise(name)) return null;
  if (looksHongKong(name)) return '🇭🇰 香港';
  if (looksTaiwan(name)) return '🇹🇼 台湾';
  return null;
}

function mapAsiaCategory(name) {
  if (looksHongKong(name)) return '🇭🇰 香港';
  if (looksTaiwan(name) || name.toLowerCase().includes('axn asia taiwan')) return '🇹🇼 台湾';
  const s = name.toLowerCase();
  if (KOREA_KEYS.some((k) => s.includes(k.toLowerCase())) || s.includes('persiana korea') || s.includes('mbc drama') || s.includes('mbc+')) {
    return '🇰🇷 韩国';
  }
  if (s.includes('gem drama') || s.includes('gem series') || s.includes('gem film')) return '🇹🇼 台湾';
  if (s.includes('cinema one') || s.includes('viva cinema') || s.includes('tap movies')) return '🇵🇭 菲律宾';
  if (s.includes('on movies') || s.includes('on vie') || s.includes('tvb vietnam')) return '🇻🇳 越南';
  if (s.includes('zee nung')) return '🇹🇭 泰国';
  return null;
}

function regionScore(name, group) {
  const s = name.toLowerCase();
  let score = 0;
  if (isDramaLike(s)) score += 140;
  if (s.includes('hd') || s.includes('1080') || s.includes('4k')) score += 12;
  if (s.includes('backup')) score -= 5;

  if (group === '🇹🇼 台湾') {
    if (looksTaiwan(name)) score += 50;
    if (['戏剧', '戲劇', '电影', '電影', '综艺', '綜藝', '综合', '綜合', '都会', '都會', '超视', '洋片', '精采'].some((k) => s.includes(k.toLowerCase()))) score += 35;
    if (s.includes('新闻') || s.includes('新聞')) score -= 40;
  }
  if (group === '🇭🇰 香港') {
    if (looksHongKong(name)) score += 50;
    if (['翡翠', '明珠', '星河', 'viu', 'hoy', '电影', '電影', '凤凰', '鳳凰'].some((k) => s.includes(k.toLowerCase()))) score += 35;
    if (s.includes('新闻') || s.includes('新聞')) score -= 25;
  }
  if (group === '🇰🇷 韩国') {
    if (KOREA_KEYS.some((k) => s.includes(k.toLowerCase()))) score += 40;
    if (['drama', 'movie', 'film', 'kbs', 'mbc', 'sbs', 'tvn'].some((k) => s.includes(k))) score += 30;
  }
  if (group === '🇮🇳 印度') {
    if (['movies', 'cinema', 'bollywood', 'entertainment', 'colors', 'sony', 'star', 'zee', 'music'].some((k) => s.includes(k))) score += 40;
    if (INDIA_NEWS_KEYS.some((k) => s.includes(k))) score -= 200;
  }
  return score;
}

function refineRegionalExtra(channels, sourceURL) {
  const u = (sourceURL || '').toLowerCase();

  if (u.includes('guovin/iptv-api') || u.includes('suxuang/myiptv')) {
    return channels.flatMap((ch) => {
      if (isMainlandNoise(ch.name) || isGeoBlocked(ch.name)) return [];
      const g = `${ch.group || ''} ${ch.name}`.toLowerCase();
      const fromHKGroup = g.includes('港') || g.includes('澳') || g.includes('台') || g.includes('港澳');
      if (!(fromHKGroup || looksHongKong(ch.name) || looksTaiwan(ch.name))) return [];
      const mapped = mapGreaterChina(ch.name);
      return mapped ? [{ ...ch, group: mapped }] : [];
    });
  }

  if (u.includes('/languages/zho.m3u')) {
    return channels.flatMap((ch) => {
      if (isMainlandNoise(ch.name) || isGeoBlocked(ch.name)) return [];
      const group = mapGreaterChina(ch.name);
      return group ? [{ ...ch, group }] : [];
    });
  }
  if (u.includes('/languages/yue.m3u')) {
    return channels
      .filter((ch) => !isMainlandNoise(ch.name) && !isGeoBlocked(ch.name))
      .map((ch) => ({ ...ch, group: '🇭🇰 香港' }));
  }
  if (u.includes('/languages/kor.m3u')) {
    return channels
      .filter((ch) => !isKoreaNoise(ch.name) && !isGeoBlocked(ch.name))
      .map((ch) => ({ ...ch, group: '🇰🇷 韩国' }));
  }
  if (u.includes('/categories/movies.m3u') || u.includes('/categories/series.m3u') || u.includes('/categories/entertainment.m3u')) {
    return channels.flatMap((ch) => {
      if (isMainlandNoise(ch.name) || isGeoBlocked(ch.name)) return [];
      const group = mapAsiaCategory(ch.name);
      return group ? [{ ...ch, group }] : [];
    });
  }
  return channels;
}

function curateRegionalChannels(channels, group) {
  if (!['🇹🇼 台湾', '🇭🇰 香港', '🇰🇷 韩国', '🇸🇬 新加坡', '🇻🇳 越南', '🇹🇭 泰国', '🇵🇭 菲律宾', '🇮🇳 印度'].includes(group)) {
    return channels;
  }
  let list = channels.filter((ch) => !isGeoBlocked(ch.name));
  if (group === '🇮🇳 印度') list = list.filter((ch) => keepIndiaChannel(ch.name));
  if (group === '🇰🇷 韩国') list = list.filter((ch) => !isKoreaNoise(ch.name));
  if (group === '🇹🇼 台湾') {
    list = list.filter((ch) => !isMainlandNoise(ch.name) && (looksTaiwan(ch.name) || isDramaLike(ch.name.toLowerCase())));
    list = list.filter((ch) => !isMainlandNoise(ch.name));
  }
  if (group === '🇭🇰 香港') list = list.filter((ch) => !isMainlandNoise(ch.name));
  return [...list].sort((a, b) => regionScore(b.name, group) - regionScore(a.name, group));
}

function parseM3U(content, sourceId) {
  const lines = content.split(/\r?\n/);
  const channels = [];
  let i = 0;
  while (i < lines.length) {
    const line = lines[i].trim();
    if (line.startsWith('#EXTINF:')) {
      const meta = parseExtInf(line);
      i++;
      while (i < lines.length) {
        const next = lines[i].trim();
        if (next && !next.startsWith('#')) {
          try {
            const url = new URL(next);
            channels.push({
              id: `${sourceId}-${hashStr(next)}`,
              name: (meta['tvg-name'] || meta.name || 'Unknown').trim(),
              url: url.href,
              logo: meta['tvg-logo'] || '',
              group: meta['group-title'] || 'Uncategorized',
            });
          } catch { /* skip bad url */ }
          break;
        }
        i++;
      }
    }
    i++;
  }
  return channels;
}

function parseExtInf(line) {
  const meta = {};
  const comma = line.lastIndexOf(',');
  if (comma >= 0) meta.name = line.slice(comma + 1).trim();
  const re = /([\w-]+)="([^"]*?)"/g;
  let m;
  while ((m = re.exec(line))) meta[m[1].toLowerCase()] = m[2];
  return meta;
}

function hashStr(s) {
  let h = 0;
  for (let i = 0; i < s.length; i++) h = ((h << 5) - h + s.charCodeAt(i)) | 0;
  return Math.abs(h);
}

const MOVIE_THEMED = [
  '美亚', '美亞', '贺岁', '賀歲', '八点档', '八點檔', '合集', '专场', '專場',
  '武侠', '武俠', '科幻', '嫣然', 'HBO',
];

function isLinearMovieChannel(name) {
  const n = name.trim();
  const u = n.toUpperCase();
  if (u.includes('CHC')) return true;
  if (u.includes('CCTV') && (u.includes('6') || u.includes('8') || n.includes('剧场'))) return true;
  if (['影视', '影視', '影院', '剧场', '劇場'].some((k) => n.includes(k))) return true;
  if (n.startsWith('电影')) {
    const themed = ['八点', '贺岁', '賀歲', '喜剧', '嫣然', '高分', '动作', '動作',
      '战争', '犯罪', '谍战', '諜戰', '丧尸', '功夫', '搞笑', '专场', '專場', '影厅', '片'];
    return themed.some((k) => n.slice(2).includes(k));
  }
  if (MOVIE_THEMED.some((k) => n.includes(k))) return true;
  if (n.endsWith('电影') || n.endsWith('電影')) return false;
  return false;
}

function isMovieLoop(name) {
  return isLinearMovieChannel(name) || name.includes('电影') || name.includes('電影');
}

function refineChinese(channels, sourceURL) {
  if (!sourceURL.includes('vbskycn/iptv')) return channels;
  const gala = [];
  const rest = [];
  for (const ch of channels) {
    const name = ch.name.trim();
    const group = ch.group || '';
    if (group.includes('更新') || group.includes('解说') || !name) continue;
    if (group.includes('春晚') || name.includes('春晚')) {
      gala.push({ ...ch, group: '🎆 春晚' });
      continue;
    }
    if (group === '电影频道' && !isLinearMovieChannel(name)) continue;
    let mapped = mapGroup(group, name);
    rest.push({ ...ch, group: mapped });
  }
  gala.sort((a, b) => galaYear(b.name) - galaYear(a.name));
  return [...gala, ...rest];
}

function mapGroup(group, name) {
  const n = name.toUpperCase();
  if (group.includes('春晚') || name.includes('春晚')) return '🎆 春晚';
  if (group === '电影频道' || isMovieLoop(name) ||
      n.includes('CCTV6') || n.includes('CCTV-6') || n.includes('CCTV8')) {
    return '🎬 华语影视';
  }
  if (group.includes('纪录')) return '📖 纪录片';
  if (group.includes('儿童')) return '🧒 儿童/动画';
  if (group.includes('体育')) return '⚽ 体育';
  if (group.includes('音乐')) return '🎵 音乐';
  return '🇨🇳 中国大陆';
}

function galaYear(name) {
  const m = name.match(/^(\d{4})/);
  return m ? parseInt(m[1], 10) : 0;
}

const STRINGS = {
  hant: {
    tagline: '亞洲影視與直播應用',
    home: '首頁', live: '直播', settings: '設定',
    loading: '正在載入頻道…', search: '搜尋頻道',
    categories: '分類', nowPlaying: '正在播放', locate: '定位到當前頻道',
    select: '選擇一個頻道開始觀看', language: '語言', theme: '外觀',
    themeDark: '深色', themeLight: '淺色',
    langHant: '繁體', langHans: '簡體', langEn: 'English',
    version: '版本', refresh: '重新整理片源',
  },
  hans: {
    tagline: '亚洲影视与直播应用',
    home: '首页', live: '直播', settings: '设置',
    loading: '正在加载频道…', search: '搜索频道',
    categories: '分类', nowPlaying: '正在播放', locate: '定位到当前频道',
    select: '选择一个频道开始观看', language: '语言', theme: '外观',
    themeDark: '深色', themeLight: '浅色',
    langHant: '繁体', langHans: '简体', langEn: 'English',
    version: '版本', refresh: '重新整理片源',
  },
  en: {
    tagline: 'Asian TV & streaming app',
    home: 'Home', live: 'Live', settings: 'Settings',
    loading: 'Loading channels…', search: 'Search channels',
    categories: 'Categories', nowPlaying: 'Now playing', locate: 'Jump to current channel',
    select: 'Pick a channel to start watching', language: 'Language', theme: 'Appearance',
    themeDark: 'Dark', themeLight: 'Light',
    langHant: '繁體', langHans: '简体', langEn: 'English',
    version: 'Version', refresh: 'Refresh sources',
  },
};

function t(key, lang = 'hant') {
  return STRINGS[lang]?.[key] || STRINGS.en[key] || STRINGS.hant[key] || key;
}


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

function renderHome() {
  const root = $('#home-sections');
  root.innerHTML = '';
  for (const g of groups().slice(0, 8)) {
    const list = channelsInGroup(g).slice(0, 16);
    if (!list.length) continue;
    const sec = document.createElement('div');
    sec.className = 'section';
    sec.innerHTML = `<h3>${g}</h3>`;
    const row = document.createElement('div');
    row.className = 'row';
    for (const ch of list) {
      const el = document.createElement('div');
      el.className = 'chip';
      el.innerHTML = `${ch.logo ? `<img src="${ch.logo}" alt="" loading="lazy" />` : ''}<span>${esc(ch.name)}</span>`;
      el.onclick = () => { switchTab('live'); play(ch); state.selectedGroup = ch.group; renderGroups(); renderChannelList(); };
      row.appendChild(el);
    }
    sec.appendChild(row);
    root.appendChild(sec);
  }
}

function renderGroups() {
  const root = $('#group-list');
  root.innerHTML = '';
  for (const g of groups()) {
    const btn = document.createElement('button');
    btn.className = 'group-btn' + (g === state.selectedGroup ? ' active' : '');
    btn.textContent = g;
    btn.onclick = () => { state.selectedGroup = g; renderGroups(); renderChannelList(); };
    root.appendChild(btn);
  }
}

function renderChannelList() {
  const q = ($('#search').value || '').trim().toLowerCase();
  let list = channelsInGroup(state.selectedGroup);
  if (q) list = list.filter((c) => c.name.toLowerCase().includes(q));
  const root = $('#channel-list');
  root.innerHTML = '';
  for (const ch of list.slice(0, 500)) {
    const row = document.createElement('div');
    row.className = 'ch-row' + (state.current?.id === ch.id ? ' playing' : '');
    row.dataset.id = ch.id;
    row.innerHTML = `
      ${ch.logo ? `<img src="${ch.logo}" alt="" loading="lazy" />` : '<div style="width:44px;height:28px;background:var(--surface2);border-radius:4px"></div>'}
      <div class="meta"><div class="name">${esc(ch.name)}</div><div class="grp">${esc(ch.group)}</div></div>`;
    row.onclick = () => play(ch);
    root.appendChild(row);
  }
  updateNowBar();
}

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

function switchTab(name) {
  $$('.nav-btn').forEach((b) => b.classList.toggle('active', b.dataset.tab === name));
  $$('.view').forEach((v) => v.classList.toggle('active', v.id === `view-${name}`));
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

$('#search').oninput = () => renderChannelList();
$('#btn-refresh').onclick = () => loadCatalog();

applyI18n();
applyTheme();
$$('[data-lang]').forEach((b) => b.classList.toggle('active', b.dataset.lang === state.lang));
loadCatalog();
})();
