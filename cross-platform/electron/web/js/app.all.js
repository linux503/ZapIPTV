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

/** Realistic category icons (SVG flags / glyphs) — mirrors Mac LiveGroupIcons. */

function groupTitle(group) {
  const i = group.indexOf(' ');
  return i > 0 ? group.slice(i + 1) : group;
}

function groupIconHTML(group) {
  const svg = ICONS[group] || fallbackIcon(group);
  return `<span class="g-icon" aria-hidden="true">${svg}</span>`;
}

function fallbackIcon(group) {
  const flag = group.split(' ')[0] || '📡';
  return `<span class="g-emoji">${flag}</span>`;
}

const ICONS = {
  '🇨🇳 中国大陆': china(),
  '🎬 华语影视': cinema(),
  '🎆 春晚': chunwan(),
  '🇹🇼 台湾': taiwan(),
  '🇭🇰 香港': hongkong(),
  '🇯🇵 日本': japan(),
  '🇰🇷 韩国': korea(),
  '🇹🇭 泰国': thailand(),
  '🇻🇳 越南': vietnam(),
  '🇮🇩 印尼': indonesia(),
  '🇲🇾 马来西亚': malaysia(),
  '🇸🇬 新加坡': singapore(),
  '🇵🇭 菲律宾': philippines(),
  '🇮🇳 印度': india(),
  '⚽ 体育': sports(),
  '📺 新闻': news(),
  '🎵 音乐': music(),
  '🎮 娱乐': entertainment(),
  '📖 纪录片': docs(),
  '🧒 儿童/动画': kids(),
};

function china() {
  return `<svg viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg">
    <rect width="40" height="40" rx="8" fill="#DE2910"/>
    <path fill="#FFDE00" d="M10 8.5l1.2 3.6H15l-3 2.2 1.1 3.6L10 15.7 6.9 17.9l1.1-3.6-3-2.2h3.8z"/>
    <g fill="#FFDE00" transform="translate(18,7) scale(.55)">
      <path d="M6 1l.7 2.1H9L7.1 4.4l.7 2.1L6 5.3 4.2 6.5l.7-2.1L3 3.1h2.3z"/>
    </g>
    <g fill="#FFDE00" transform="translate(22,11) scale(.5)"><path d="M6 1l.7 2.1H9L7.1 4.4l.7 2.1L6 5.3 4.2 6.5l.7-2.1L3 3.1h2.3z"/></g>
    <g fill="#FFDE00" transform="translate(22.5,16.5) scale(.5)"><path d="M6 1l.7 2.1H9L7.1 4.4l.7 2.1L6 5.3 4.2 6.5l.7-2.1L3 3.1h2.3z"/></g>
    <g fill="#FFDE00" transform="translate(18.5,20) scale(.5)"><path d="M6 1l.7 2.1H9L7.1 4.4l.7 2.1L6 5.3 4.2 6.5l.7-2.1L3 3.1h2.3z"/></g>
  </svg>`;
}

function taiwan() {
  return `<svg viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg">
    <rect width="40" height="40" rx="8" fill="#FE0000"/>
    <rect width="20" height="20" rx="0" fill="#000095"/>
    <circle cx="10" cy="10" r="5.2" fill="#fff"/>
    <circle cx="10" cy="10" r="3.2" fill="#000095"/>
    <g fill="#fff" transform="translate(10,10)">
      ${[0,45,90,135,180,225,270,315].map((a) =>
        `<rect x="-0.7" y="-7.4" width="1.4" height="2.6" transform="rotate(${a})" rx=".4"/>`
      ).join('')}
    </g>
  </svg>`;
}

function hongkong() {
  return `<svg viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg">
    <rect width="40" height="40" rx="8" fill="#DE2910"/>
    <g fill="#fff" transform="translate(20,20)">
      ${[0,72,144,216,288].map((a) => `
        <g transform="rotate(${a}) translate(0,-7.5)">
          <ellipse cx="0" cy="0" rx="3.2" ry="5.2"/>
          <circle cx="1.2" cy="-1.5" r=".7" fill="#DE2910"/>
        </g>`).join('')}
    </g>
  </svg>`;
}

function japan() {
  return `<svg viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg">
    <rect width="40" height="40" rx="8" fill="#fff"/>
    <circle cx="20" cy="20" r="8.5" fill="#BC002D"/>
  </svg>`;
}

function korea() {
  return `<svg viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg">
    <rect width="40" height="40" rx="8" fill="#fff"/>
    <path d="M12 20a8 8 0 0 1 8-8 8 8 0 0 1 0 16 8 8 0 0 0-8-8z" fill="#C60C30"/>
    <path d="M28 20a8 8 0 0 1-8 8 8 8 0 0 1 0-16 8 8 0 0 0 8 8z" fill="#003478"/>
    <g stroke="#111" stroke-width="1.6" stroke-linecap="round">
      <path d="M8 10l4-3M9.5 12.2l4-3M11 14.4l4-3"/>
      <path d="M28 10l4 3M29.5 12.2l4 3M31 14.4l4 3"/>
      <path d="M8 30l4 3M9.5 27.8l4 3M11 25.6l4 3"/>
      <path d="M28 30l4-3M29.5 27.8l4-3M31 25.6l4-3"/>
    </g>
  </svg>`;
}

function thailand() {
  return `<svg viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg">
    <rect width="40" height="40" rx="8" fill="#A51931"/>
    <rect y="7" width="40" height="26" fill="#F4F5F8"/>
    <rect y="13" width="40" height="14" fill="#2D2A4A"/>
  </svg>`;
}

function vietnam() {
  return `<svg viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg">
    <rect width="40" height="40" rx="8" fill="#DA251D"/>
    <path fill="#FF0" d="M20 10l2.4 7.4H30l-6 4.4 2.3 7.2L20 24.6l-6.3 4.4 2.3-7.2-6-4.4h7.6z"/>
  </svg>`;
}

function indonesia() {
  return `<svg viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg">
    <rect width="40" height="40" rx="8" fill="#fff"/>
    <path d="M0 8h40v12H0z" fill="#E70011"/>
  </svg>`;
}

function malaysia() {
  return `<svg viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg">
    <rect width="40" height="40" rx="8" fill="#C00"/>
    <path fill="#fff" d="M0 11h40v3H0zm0 6h40v3H0zm0 6h40v3H0z"/>
    <rect width="20" height="20" fill="#010066"/>
    <circle cx="11" cy="10" r="5" fill="#FC0"/>
    <circle cx="12.5" cy="10" r="4" fill="#010066"/>
    <path fill="#FC0" d="M16 10l2.2.7-2.2.7-.7 2.2-.7-2.2-2.2-.7 2.2-.7.7-2.2z"/>
  </svg>`;
}

function singapore() {
  return `<svg viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg">
    <rect width="40" height="40" rx="8" fill="#fff"/>
    <path d="M0 8h40v12H0z" fill="#ED2939"/>
    <circle cx="10" cy="14" r="5" fill="#fff"/>
    <circle cx="12" cy="14" r="4.2" fill="#ED2939"/>
    <g fill="#fff">${[[16,11],[18.5,12.5],[18.5,15.5],[16,17],[13.5,15.5]].map(([x,y]) =>
      `<circle cx="${x}" cy="${y}" r=".9"/>`).join('')}</g>
  </svg>`;
}

function philippines() {
  return `<svg viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg">
    <path d="M8 8h32v12H18z" fill="#0038A8"/>
    <path d="M8 20h32v12H18z" fill="#CE1126"/>
    <path d="M8 8l14 12L8 32z" fill="#fff"/>
    <circle cx="13" cy="20" r="3.2" fill="#FCD116"/>
  </svg>`;
}

function india() {
  return `<svg viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg">
    <rect width="40" height="40" rx="8" fill="#fff"/>
    <path d="M0 8h40v8H0z" fill="#FF9933"/>
    <path d="M0 24h40v8H0z" fill="#138808"/>
    <circle cx="20" cy="20" r="4.2" fill="none" stroke="#000080" stroke-width="1.2"/>
    <circle cx="20" cy="20" r="1" fill="#000080"/>
  </svg>`;
}

function cinema() {
  return `<svg viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg">
    <defs><linearGradient id="cg" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#7C3AED"/><stop offset="1" stop-color="#EC4899"/></linearGradient></defs>
    <rect width="40" height="40" rx="8" fill="url(#cg)"/>
    <rect x="8" y="12" width="24" height="16" rx="2" fill="#fff" opacity=".95"/>
    <path d="M14 16h4v8h-4zm8 0h4v8h-4z" fill="#7C3AED"/>
    <path d="M8 12l-3-3h6zm24 0l3-3h-6zM8 28l-3 3h6zm24 0l3 3h-6z" fill="#FDE68A"/>
  </svg>`;
}

function chunwan() {
  return `<svg viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg">
    <defs><linearGradient id="cw" x1="0" y1="0" x2="0" y2="1"><stop stop-color="#DC2626"/><stop offset="1" stop-color="#F59E0B"/></linearGradient></defs>
    <rect width="40" height="40" rx="8" fill="url(#cw)"/>
    <path d="M20 8c6 4 9 9 9 14 0 5-4 9-9 9s-9-4-9-9c0-5 3-10 9-14z" fill="#FDE68A"/>
    <path d="M20 12c4 3 6 6.5 6 10a6 6 0 1 1-12 0c0-3.5 2-7 6-10z" fill="#DC2626"/>
    <circle cx="20" cy="21" r="2" fill="#FDE68A"/>
  </svg>`;
}

function sports() {
  return `<svg viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg">
    <defs><linearGradient id="sg" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#059669"/><stop offset="1" stop-color="#10B981"/></linearGradient></defs>
    <rect width="40" height="40" rx="8" fill="url(#sg)"/>
    <circle cx="20" cy="20" r="10" fill="none" stroke="#ECFDF5" stroke-width="2"/>
    <path d="M20 10v20M10 20h20M13 13c4 3 10 3 14 0M13 27c4-3 10-3 14 0" fill="none" stroke="#ECFDF5" stroke-width="1.4"/>
  </svg>`;
}

function news() {
  return glyphBg('gn', '#1D4ED8', '#0EA5E9', `<path d="M11 12h18v16H11z" fill="#fff" opacity=".95"/><path d="M14 16h12v2H14zm0 4h12v2H14zm0 4h8v2h-8z" fill="#1D4ED8"/>`);
}
function music() {
  return glyphBg('gm', '#DB2777', '#F59E0B', `<path d="M16 12v12.5a3.5 3.5 0 1 0 2.2 3.3V18l10-2v8.7a3.5 3.5 0 1 0 2.2 3.3V12.2z" fill="#fff"/>`);
}
function entertainment() {
  return glyphBg('ge', '#7C3AED', '#EC4899', `<path d="M12 14h16v10H12zm3 12h4v3h-4zm6 0h4v3h-4z" fill="#fff"/><circle cx="16" cy="19" r="1.5" fill="#7C3AED"/><circle cx="24" cy="19" r="1.5" fill="#7C3AED"/>`);
}
function docs() {
  return glyphBg('gd', '#0F766E', '#14B8A6', `<path d="M13 11h10l5 5v13H13z" fill="#fff"/><path d="M23 11v5h5" fill="#99F6E4"/><path d="M16 20h10v1.6H16zm0 4h10v1.6H16zm0 4h7v1.6h-7z" fill="#0F766E"/>`);
}
function kids() {
  return glyphBg('gk', '#F59E0B', '#F97316', `<circle cx="20" cy="17" r="6" fill="#fff"/><path d="M12 30c1.5-5 5-7 8-7s6.5 2 8 7" fill="#fff"/>`);
}

function glyphBg(id, c1, c2, inner) {
  return `<svg viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg">
    <defs><linearGradient id="${id}" x1="0" y1="0" x2="1" y2="1"><stop stop-color="${c1}"/><stop offset="1" stop-color="${c2}"/></linearGradient></defs>
    <rect width="40" height="40" rx="8" fill="url(#${id})"/>
    ${inner}
  </svg>`;
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
})();
