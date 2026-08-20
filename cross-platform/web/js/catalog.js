const CDN = 'https://cdn.jsdelivr.net/gh/iptv-org/iptv@gh-pages';

export const DEFAULT_SOURCES = [
  { name: '🇨🇳 中国大陆', url: `${CDN}/countries/cn.m3u`, overrideGroup: '🇨🇳 中国大陆' },
  { name: '🇨🇳 国内直播', url: 'https://cdn.jsdelivr.net/gh/vbskycn/iptv@master/tv/iptv4.m3u', overrideGroup: null },
  { name: '🇹🇼 台湾', url: `${CDN}/countries/tw.m3u`, overrideGroup: '🇹🇼 台湾' },
  { name: '🇭🇰 香港', url: `${CDN}/countries/hk.m3u`, overrideGroup: '🇭🇰 香港' },
  { name: '🇭🇰 香港直播', url: 'https://cdn.jsdelivr.net/gh/sammy0101/hk-iptv-auto@main/hk_live.m3u', overrideGroup: '🇭🇰 香港' },
  { name: '🇯🇵 日本', url: `${CDN}/countries/jp.m3u`, overrideGroup: '🇯🇵 日本' },
  { name: '🇰🇷 韩国', url: `${CDN}/countries/kr.m3u`, overrideGroup: '🇰🇷 韩国' },
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
