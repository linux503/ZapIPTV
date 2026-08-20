export const STRINGS = {
  hant: {
    tagline: '亞洲影視與直播應用',
    home: '首頁', live: '直播', settings: '設定',
    loading: '正在載入頻道…', search: '搜尋頻道',
    categories: '分類', nowPlaying: '正在播放', locate: '定位到當前頻道',
    select: '選擇一個頻道開始觀看', language: '語言', theme: '外觀',
    themeDark: '深色', themeLight: '淺色', langHant: '繁體', langHans: '簡體',
    version: '版本', refresh: '重新整理片源',
  },
  hans: {
    tagline: '亚洲影视与直播应用',
    home: '首页', live: '直播', settings: '设置',
    loading: '正在加载频道…', search: '搜索频道',
    categories: '分类', nowPlaying: '正在播放', locate: '定位到当前频道',
    select: '选择一个频道开始观看', language: '语言', theme: '外观',
    themeDark: '深色', themeLight: '浅色', langHant: '繁体', langHans: '简体',
    version: '版本', refresh: '重新整理片源',
  },
};

export function t(key, lang = 'hant') {
  return STRINGS[lang]?.[key] || STRINGS.hant[key] || key;
}
