---
tags: [learning, dashboard, quiz, interactive]
category: resource
created: 2026-03-23
---

# 📊 학습 현황 대시보드

> 브라우저에서 퀴즈를 완료하면 자동으로 결과가 여기에 반영됩니다.
> localStorage 기반이므로 같은 브라우저에서만 동작합니다.

<style>
.dash-container {
  font-family: inherit;
  max-width: 680px;
  margin: 0 auto;
  padding: 0.5rem 0;
}
.dash-empty {
  color: var(--color-base-05, #aaa);
  font-size: 0.9rem;
  padding: 1.5rem;
  text-align: center;
  background: var(--color-base-25, #2e2e2e);
  border-radius: 8px;
  border: 1px dashed var(--color-base-30, #444);
}
.dash-topic-row {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.6rem 0;
  border-bottom: 1px solid var(--color-base-30, #333);
}
.dash-topic-name {
  width: 160px;
  flex-shrink: 0;
  font-size: 0.88rem;
  font-weight: 600;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.dash-bar-wrap {
  flex: 1;
  height: 10px;
  background: var(--color-base-30, #3a3a3a);
  border-radius: 5px;
  overflow: hidden;
}
.dash-bar-fill {
  height: 100%;
  border-radius: 5px;
  transition: width 0.4s ease;
}
.dash-score-label {
  width: 80px;
  text-align: right;
  font-size: 0.82rem;
  color: var(--color-base-05, #bbb);
  flex-shrink: 0;
}
.dash-weak-section {
  margin-top: 1.25rem;
  background: var(--color-base-25, #2e2e2e);
  border: 1px solid var(--color-base-30, #444);
  border-radius: 8px;
  padding: 0.75rem 1rem;
}
.dash-weak-title {
  font-size: 0.9rem;
  font-weight: 700;
  color: #f87171;
  margin-bottom: 0.5rem;
}
.dash-weak-list {
  list-style: none;
  padding: 0;
  margin: 0;
  font-size: 0.85rem;
  line-height: 1.7;
  color: var(--color-base-05, #ccc);
}
.dash-weak-list li::before { content: '→ '; color: #f87171; }
.dash-footer {
  display: flex;
  justify-content: flex-end;
  margin-top: 1rem;
}
.dash-reset-btn {
  padding: 0.35rem 0.85rem;
  border-radius: 6px;
  border: 1px solid var(--color-base-30, #555);
  background: transparent;
  color: var(--color-base-05, #aaa);
  font-size: 0.8rem;
  cursor: pointer;
  transition: border-color 0.2s;
}
.dash-reset-btn:hover { border-color: #f87171; color: #f87171; }
.dash-date-label {
  font-size: 0.75rem;
  color: var(--color-base-05, #888);
  margin-left: auto;
}
</style>

<div class="dash-container">
  <div id="dash-content">
    <div class="dash-empty" id="dash-empty">
      퀴즈 결과가 없습니다.<br>
      <code>resource/topics/</code> 의 퀴즈를 풀고 "Obsidian에 저장"을 누르면 여기에 반영됩니다.
    </div>
  </div>
  <div class="dash-footer">
    <button class="dash-reset-btn" onclick="dashReset()">🗑 데이터 초기화</button>
  </div>
</div>

<script>
(function () {
  const THRESHOLD_WEAK = 60;  // 복습 필요 기준 (%)

  function getAllResults() {
    const results = [];
    for (let i = 0; i < localStorage.length; i++) {
      const key = localStorage.key(i);
      if (!key || !key.startsWith('iq_')) continue;
      try {
        const val = JSON.parse(localStorage.getItem(key));
        if (val && val.quizId) results.push(val);
      } catch (e) {}
    }
    return results;
  }

  function getLatestByTopic(results) {
    const map = {};
    results.forEach(r => {
      const key = r.topic + ':' + r.topicTitle;
      if (!map[key] || r.date > map[key].date) map[key] = r;
    });
    return Object.values(map).sort((a, b) => b.date.localeCompare(a.date));
  }

  function barColor(pct) {
    if (pct >= 80) return '#4ade80';
    if (pct >= 60) return '#facc15';
    return '#f87171';
  }

  function render() {
    const all    = getAllResults();
    const latest = getLatestByTopic(all);
    const content = document.getElementById('dash-content');
    const empty  = document.getElementById('dash-empty');

    if (latest.length === 0) {
      if (empty) empty.style.display = 'block';
      return;
    }
    if (empty) empty.style.display = 'none';

    // 토픽 막대그래프
    const rows = latest.map(r => {
      const pct = r.pct !== undefined ? r.pct : Math.round((r.score / r.total) * 100);
      const color = barColor(pct);
      return `<div class="dash-topic-row">
        <div class="dash-topic-name" title="${r.topicTitle}">${r.topicTitle}</div>
        <div class="dash-bar-wrap">
          <div class="dash-bar-fill" style="width:${pct}%;background:${color}"></div>
        </div>
        <div class="dash-score-label">${r.score}/${r.total} (${pct}%)</div>
        <div class="dash-date-label">${r.date}</div>
      </div>`;
    }).join('');

    // 복습 필요 항목
    const weak = latest.filter(r => {
      const pct = r.pct !== undefined ? r.pct : Math.round((r.score / r.total) * 100);
      return pct < THRESHOLD_WEAK;
    });

    let weakSection = '';
    if (weak.length > 0) {
      const items = weak.flatMap(r => (r.wrong || []).map(w => `<li>${r.topicTitle}: ${w}</li>`)).join('');
      weakSection = `<div class="dash-weak-section">
        <div class="dash-weak-title">⚠️ 복습 필요 (${THRESHOLD_WEAK}% 미만)</div>
        <ul class="dash-weak-list">${items}</ul>
      </div>`;
    }

    content.innerHTML = rows + weakSection;
  }

  window.dashReset = function () {
    if (!confirm('모든 퀴즈 결과를 삭제하시겠습니까?')) return;
    const keys = [];
    for (let i = 0; i < localStorage.length; i++) {
      const key = localStorage.key(i);
      if (key && key.startsWith('iq_')) keys.push(key);
    }
    keys.forEach(k => localStorage.removeItem(k));
    render();
  };

  render();
})();
</script>
