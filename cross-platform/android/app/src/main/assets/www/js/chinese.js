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
