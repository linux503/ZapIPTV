const CDN = 'https://cdn.jsdelivr.net/gh/iptv-org/iptv@gh-pages';

export const DEFAULT_SOURCES = [
  { name: '🇨🇳 中国大陆', url: `${CDN}/countries/cn.m3u`, overrideGroup: '🇨🇳 中国大陆' },
  { name: '🇨🇳 国内直播', url: 'https://cdn.jsdelivr.net/gh/vbskycn/iptv@master/tv/iptv4.m3u', overrideGroup: null },
  { name: '🇹🇼 台湾', url: `${CDN}/countries/tw.m3u`, overrideGroup: '🇹🇼 台湾' },
  { name: '🇹🇼 华语剧场', url: `${CDN}/languages/zho.m3u`, overrideGroup: null },
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
  'GEM', 'AXN', 'Celestial', 'Cinema One', 'Viva Cinema', 'Tap Movies',
];

const INDIA_NEWS_KEYS = [
  'news', 'समाचार', 'खबर', 'bharat', 'indiatv', 'speed news', 'aaj tak', 'republic',
  'times now', 'et now', 'mirror now', 'cnn-news18', 'cnbc', 'dd news', 'abp', 'lokshahi',
];

const KOREA_DROP = [
  'shopping', 'onstyle', 'homeshopping', 'home & shopping', 'kshopping', 'cj onstyle',
  'lotte home', 'hyundai home', 'gongyoung', 'gs my shop', 'buddhist', 'radio',
];

const TAIWAN_KEYS = [
  'taiwan', 'tvbs', 'cts', 'ftv', 'ttv', 'ctv', 'ebc', 'cti', 'set ', '三立',
  '東森', '东森', '中天', '八大', '緯來', '纬来', '民視', '民视', '台视', '台視',
  '中视', '中視', '华视', '華視', '綜藝', '综合台', '綜合台',
];

const HK_KEYS = [
  'hong kong', 'tvb', 'viu', 'hoy', 'jade', 'pearl', 'rthk', 'celestial',
  '翡翠', '明珠', '港台', '無線', '无线', '有線', '有线', '鳳凰', '凤凰', '耀才',
];

const KOREA_KEYS = [
  'korea', 'korean', 'kbs', 'mbc', 'sbs', 'tvn', 'jtbc', 'arirang', 'ebs',
  'channel a', 'kpop',
];

function isDramaLike(name) {
  const s = name.toLowerCase();
  return DRAMA_KEYS.some((k) => s.includes(k.toLowerCase()));
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

function mapChineseLanguage(name) {
  const s = name.toLowerCase();
  if (HK_KEYS.some((k) => s.includes(k.toLowerCase()))) return '🇭🇰 香港';
  if (TAIWAN_KEYS.some((k) => s.includes(k.toLowerCase()))) return '🇹🇼 台湾';
  return null;
}

function mapAsiaCategory(name) {
  const s = name.toLowerCase();
  if (HK_KEYS.some((k) => s.includes(k.toLowerCase())) || s.includes('celestial')) return '🇭🇰 香港';
  if (TAIWAN_KEYS.some((k) => s.includes(k.toLowerCase())) || s.includes('axn asia taiwan')) return '🇹🇼 台湾';
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
  if (s.includes('hd') || s.includes('1080')) score += 12;

  const bonus = {
    '🇹🇼 台湾': TAIWAN_KEYS,
    '🇭🇰 香港': HK_KEYS,
    '🇰🇷 韩国': [...KOREA_KEYS, 'drama', 'movie', 'film'],
    '🇸🇬 新加坡': ['channel 8', 'channel u', 'suria', 'vasantham', 'mewatch'],
    '🇻🇳 越南': ['vie', 'htv', 'vtvcab', 'on movies', 'tvb vietnam'],
    '🇹🇭 泰国': ['one31', 'gmm', 'workpoint', 'mono', 'true', 'zee nung'],
    '🇵🇭 菲律宾': ['cinema one', 'tap movies', 'viva cinema', 'axn', 'kapamilya', 'gma'],
    '🇮🇳 印度': ['movies', 'cinema', 'bollywood', 'entertainment', 'colors', 'sony', 'star', 'zee', 'music'],
  }[group] || [];

  if (bonus.some((k) => s.includes(k.toLowerCase()))) score += 40;
  if (group === '🇮🇳 印度' && INDIA_NEWS_KEYS.some((k) => s.includes(k))) score -= 200;
  return score;
}

export function refineRegionalExtra(channels, sourceURL) {
  const u = (sourceURL || '').toLowerCase();
  if (u.includes('/languages/zho.m3u')) {
    return channels.flatMap((ch) => {
      const group = mapChineseLanguage(ch.name);
      return group ? [{ ...ch, group }] : [];
    });
  }
  if (u.includes('/languages/yue.m3u')) {
    return channels.map((ch) => ({ ...ch, group: '🇭🇰 香港' }));
  }
  if (u.includes('/languages/kor.m3u')) {
    return channels
      .filter((ch) => !isKoreaNoise(ch.name))
      .map((ch) => ({ ...ch, group: '🇰🇷 韩国' }));
  }
  if (u.includes('/categories/movies.m3u') || u.includes('/categories/series.m3u') || u.includes('/categories/entertainment.m3u')) {
    return channels.flatMap((ch) => {
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
  let list = channels;
  if (group === '🇮🇳 印度') list = channels.filter((ch) => keepIndiaChannel(ch.name));
  if (group === '🇰🇷 韩国') list = list.filter((ch) => !isKoreaNoise(ch.name));
  return [...list].sort((a, b) => regionScore(b.name, group) - regionScore(a.name, group));
}
