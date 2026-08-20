const CDN = 'https://cdn.jsdelivr.net/gh/iptv-org/iptv@gh-pages';

export const DEFAULT_SOURCES = [
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

export const GROUP_ORDER = [
  '🇨🇳 中国大陆', '🎬 华语影视', '🎆 春晚', '🇹🇼 台湾', '🇭🇰 香港',
  '🇯🇵 日本', '🇰🇷 韩国', '🇹🇭 泰国', '🇻🇳 越南',
  '🇮🇩 印尼', '🇲🇾 马来西亚', '🇸🇬 新加坡', '🇵🇭 菲律宾', '🇮🇳 印度',
];

export function normaliseGroup(raw) {
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

export function refineRegionalExtra(channels, sourceURL) {
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

export function curateRegionalChannels(channels, group) {
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
