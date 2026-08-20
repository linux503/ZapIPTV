export function parseM3U(content, sourceId) {
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
