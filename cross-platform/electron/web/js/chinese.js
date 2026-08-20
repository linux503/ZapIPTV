const MOVIE_KEYS = [
  'CHC', '剧场', '影視', '影视', '影院', '电影', '電影', '贺岁', '賀歲',
  '美亚', '美亞', '合集', '专场', '專場', '武侠', '武俠', '科幻', '八点档', '八點檔', '嫣然',
];

export function refineChinese(channels, sourceURL) {
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
    if (group === '电影频道' && !isMovieLoop(name)) continue;
    let mapped = mapGroup(group, name);
    rest.push({ ...ch, group: mapped });
  }
  gala.sort((a, b) => galaYear(b.name) - galaYear(a.name));
  return [...gala, ...rest];
}

function isMovieLoop(name) {
  return MOVIE_KEYS.some((k) => name.includes(k));
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
