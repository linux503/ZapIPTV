/** Realistic category icons (SVG flags / glyphs) — mirrors Mac LiveGroupIcons. */

export function groupTitle(group) {
  const i = group.indexOf(' ');
  return i > 0 ? group.slice(i + 1) : group;
}

export function groupIconHTML(group) {
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
