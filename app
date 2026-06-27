/* ================================================================
   app.js  –  Moksh  (fully self-contained, no ES-module imports)
   Works with both  file://  and  http://  without a bundler.
   ================================================================ */

/* ── State helpers ─────────────────────────────────────────────── */
function ls(key, def) {
  try { return JSON.parse(localStorage.getItem(key)) ?? def; }
  catch { return def; }
}
function lsSet(key, val) { localStorage.setItem(key, JSON.stringify(val)); }

/* ── XP / Gamification ─────────────────────────────────────────── */
const XP_RULES = { journal: 15, mood: 10, mindfulness: 25, quest: 40 };

function getXP()  { return ls('xp', 0); }
function addXP(type) {
  const pts = XP_RULES[type] || 0;
  const newXP = getXP() + pts;
  lsSet('xp', newXP);
  updateNavXP();
  showToast(`+${pts} XP earned! 🌟`, 'hype');
  checkBadges();
  return newXP;
}
function updateNavXP() {
  const el = document.getElementById('navXp');
  if (el) el.textContent = `⭐ ${getXP()} XP`;
}

/* ── Badges ─────────────────────────────────────────────────────── */
const BADGE_DEFS = [
  { id: 'first_journal',   emoji: '📓', label: 'First Entry',      condition: () => ls('journal', []).length >= 1 },
  { id: 'journal_5',       emoji: '✍️', label: '5 Journal Entries', condition: () => ls('journal', []).length >= 5 },
  { id: 'first_mood',      emoji: '😊', label: 'Mood Logged',       condition: () => ls('moodLogs', []).length >= 1 },
  { id: 'streak_3',        emoji: '🔥', label: '3-Day Streak',      condition: () => getStreak() >= 3 },
  { id: 'first_breath',    emoji: '🧘', label: 'First Breath',      condition: () => ls('breathCount', 0) >= 1 },
  { id: 'zen_master',      emoji: '🌸', label: 'Zen Master',        condition: () => ls('breathCount', 0) >= 5 },
  { id: 'xp_100',          emoji: '⭐', label: '100 XP Club',       condition: () => getXP() >= 100 },
  { id: 'xp_500',          emoji: '💫', label: '500 XP Legend',     condition: () => getXP() >= 500 },
];

function checkBadges() {
  const earned = ls('badges', []);
  let newBadge = false;
  BADGE_DEFS.forEach(b => {
    if (!earned.includes(b.id) && b.condition()) {
      earned.push(b.id);
      lsSet('badges', earned);
      showToast(`🏅 Badge unlocked: ${b.label}!`, 'hype');
      newBadge = true;
    }
  });
  return newBadge;
}

/* ── Streak ─────────────────────────────────────────────────────── */
function getStreak() {
  const logs = ls('moodLogs', []);
  if (!logs.length) return 0;
  const days = [...new Set(logs.map(l => l.ts.slice(0, 10)))].sort().reverse();
  let streak = 1;
  for (let i = 0; i < days.length - 1; i++) {
    const a = new Date(days[i]), b = new Date(days[i + 1]);
    if ((a - b) / 86400000 === 1) streak++;
    else break;
  }
  return streak;
}

/* ── Toast ──────────────────────────────────────────────────────── */
function showToast(msg, type = 'success') {
  const container = document.getElementById('toast-container');
  if (!container) return;
  const toast = document.createElement('div');
  toast.className = `toast ${type}`;
  toast.textContent = msg;
  container.appendChild(toast);
  setTimeout(() => { toast.style.opacity = '0'; toast.style.transition = '0.4s'; setTimeout(() => toast.remove(), 400); }, 3000);
}

/* ── Motivator messages ──────────────────────────────────────────── */
const HYPE_MSGS = [
  "You've got this! Every step counts 🚀",
  "Breathe. You're doing better than you think 💪",
  "Keep going — the hardest part is starting ✨",
  "You are capable of incredible things 🌟",
  "Small progress is still progress. Own it! 🎯",
  "Your brain is working overtime and it's amazing 🧠",
  "Rest is productive too. You're doing great 🌿",
];
function randomHype() { return HYPE_MSGS[Math.floor(Math.random() * HYPE_MSGS.length)]; }

/* ── Router ─────────────────────────────────────────────────────── */
const app = () => document.getElementById('app');

function setActive(route) {
  document.querySelectorAll('.nav-btn').forEach(btn => {
    btn.classList.toggle('active', btn.getAttribute('href') === '#' + route);
  });
}

function router() {
  const route = location.hash.replace('#', '') || 'dashboard';
  setActive(route);
  const container = app();
  switch (route) {
    case 'journal':     renderJournal(container);     break;
    case 'mood':        renderMoodLog(container);     break;
    case 'mindfulness': renderMindfulness(container); break;
    case 'quests':      renderQuests(container);      break;
    default:            renderDashboard(container);
  }
}

/* ══════════════════════════════════════════════════════════════════
   VIEWS
   ══════════════════════════════════════════════════════════════════ */

/* ── Dashboard ──────────────────────────────────────────────────── */
function renderDashboard(container) {
  const journals = ls('journal', []);
  const moods    = ls('moodLogs', []);
  const badges   = ls('badges', []);
  const xp       = getXP();
  const streak   = getStreak();
  const level    = Math.floor(xp / 100) + 1;
  const xpInLevel = xp % 100;

  container.innerHTML = `
    <div class="card slide-up">
      <h2>👋 Welcome back to Moksh</h2>
      <p>Your gamified exam wellbeing companion. Track your journey, earn XP, and stay calm.</p>

      <div class="stats-grid mt-2">
        <div class="stat-box">
          <span class="stat-value">${journals.length}</span>
          <span class="stat-label">Journals</span>
        </div>
        <div class="stat-box">
          <span class="stat-value">${moods.length}</span>
          <span class="stat-label">Mood Logs</span>
        </div>
        <div class="stat-box">
          <span class="stat-value">${streak}</span>
          <span class="stat-label">Day Streak 🔥</span>
        </div>
      </div>

      <div class="xp-bar-wrap mt-2">
        <p>Level ${level} &nbsp;·&nbsp; ${xpInLevel}/100 XP to next level</p>
        <div class="xp-bar"><div class="xp-fill" style="width:${xpInLevel}%"></div></div>
      </div>
    </div>

    <div class="card slide-up">
      <h2>🏅 Badges Earned (${badges.length}/${BADGE_DEFS.length})</h2>
      <div class="badge-row">
        ${BADGE_DEFS.map(b => `
          <span class="badge ${badges.includes(b.id) ? 'unlocked' : 'locked'}"
                title="${b.label}">${b.emoji}</span>
        `).join('')}
      </div>
    </div>

    <div class="card slide-up">
      <h2>💬 Motivator</h2>
      <p id="motivatorMsg">${randomHype()}</p>
      <button class="mt-2" onclick="document.getElementById('motivatorMsg').textContent = randomHype()">New Message</button>
    </div>
  `;
}

/* ── Journal ────────────────────────────────────────────────────── */
function renderJournal(container) {
  container.innerHTML = `
    <div class="card slide-up">
      <h2>📓 Journal</h2>
      <p class="text-muted">Write anything. Your thoughts are safe here.</p>
      <div class="form-group mt-2">
        <label for="journalText">Today's thoughts</label>
        <textarea id="journalText" rows="5" placeholder="What's on your mind?"></textarea>
      </div>
      <div class="flex-row mt-2">
        <button id="saveEntry">Save Entry (+${XP_RULES.journal} XP)</button>
      </div>
    </div>
    <div class="card slide-up">
      <h2>📚 Past Entries</h2>
      <div id="entries" class="entry-list"></div>
    </div>
  `;

  renderJournalEntries();

  document.getElementById('saveEntry').onclick = () => {
    const txt = document.getElementById('journalText').value.trim();
    if (!txt) { showToast('Write something first!', 'success'); return; }
    const journals = ls('journal', []);
    journals.push({ ts: new Date().toISOString(), text: txt });
    lsSet('journal', journals);
    document.getElementById('journalText').value = '';
    addXP('journal');
    checkBadges();
    renderJournalEntries();
    showToast('Journal saved! 📓', 'success');
  };
}

function renderJournalEntries() {
  const el = document.getElementById('entries');
  if (!el) return;
  const journals = ls('journal', []);
  if (!journals.length) { el.innerHTML = '<p class="text-muted">No entries yet. Start writing!</p>'; return; }
  el.innerHTML = journals.slice().reverse().map(e => `
    <div class="entry-item">
      <small>${new Date(e.ts).toLocaleString()}</small>
      <p>${escapeHtml(e.text)}</p>
    </div>
  `).join('');
}

/* ── Mood Log ───────────────────────────────────────────────────── */
const MOODS = [
  { key: 'great',   emoji: '😄', label: 'Great' },
  { key: 'good',    emoji: '🙂', label: 'Good' },
  { key: 'neutral', emoji: '😐', label: 'Neutral' },
  { key: 'stressed',emoji: '😣', label: 'Stressed' },
  { key: 'anxious', emoji: '😰', label: 'Anxious' },
  { key: 'down',    emoji: '😞', label: 'Down' },
];

function renderMoodLog(container) {
  container.innerHTML = `
    <div class="card slide-up">
      <h2>😊 Mood Log</h2>
      <p class="text-muted">How are you feeling right now?</p>
      <div class="mood-picker" id="moodPicker">
        ${MOODS.map(m => `
          <span class="mood-option" data-mood="${m.key}" title="${m.label}" role="button" tabindex="0">${m.emoji}</span>
        `).join('')}
      </div>
      <div class="form-group">
        <label for="moodNote">Add a note (optional)</label>
        <textarea id="moodNote" rows="2" placeholder="What's making you feel this way?"></textarea>
      </div>
      <button id="saveMood" class="mt-1">Log Mood (+${XP_RULES.mood} XP)</button>
    </div>
    <div class="card slide-up">
      <h2>📈 Mood History</h2>
      <div id="moodLog" class="entry-list"></div>
    </div>
  `;

  let selected = null;

  document.querySelectorAll('.mood-option').forEach(el => {
    el.onclick = () => {
      selected = el.dataset.mood;
      document.querySelectorAll('.mood-option').forEach(o => o.classList.remove('selected'));
      el.classList.add('selected');
    };
  });

  renderMoodEntries();

  document.getElementById('saveMood').onclick = () => {
    if (!selected) { showToast('Please pick a mood first!', 'success'); return; }
    const note  = document.getElementById('moodNote').value.trim();
    const logs  = ls('moodLogs', []);
    logs.push({ ts: new Date().toISOString(), mood: selected, note });
    lsSet('moodLogs', logs);
    document.getElementById('moodNote').value = '';
    selected = null;
    document.querySelectorAll('.mood-option').forEach(o => o.classList.remove('selected'));
    addXP('mood');
    checkBadges();
    renderMoodEntries();
    showToast('Mood logged! ' + (MOODS.find(m=>m.key===selected)?.emoji||''), 'success');
  };
}

function renderMoodEntries() {
  const el = document.getElementById('moodLog');
  if (!el) return;
  const logs = ls('moodLogs', []);
  if (!logs.length) { el.innerHTML = '<p class="text-muted">No mood logs yet.</p>'; return; }
  el.innerHTML = logs.slice().reverse().map(l => {
    const m = MOODS.find(x => x.key === l.mood) || { emoji: '❓', label: l.mood };
    return `
      <div class="entry-item">
        <small>${new Date(l.ts).toLocaleString()}</small>
        <span class="entry-mood-badge">${m.emoji} ${m.label}</span>
        ${l.note ? `<p>${escapeHtml(l.note)}</p>` : ''}
      </div>`;
  }).join('');
}

/* ── Mindfulness ────────────────────────────────────────────────── */
function renderMindfulness(container) {
  let timerId = null;
  let phase   = 'idle'; // idle | inhale | exhale | done

  container.innerHTML = `
    <div class="card slide-up text-center">
      <h2>🧘 Mindfulness — Breathing Session</h2>
      <p class="text-muted">A 2-minute guided breathing exercise to reset your mind.</p>

      <div class="breathe-circle" id="breatheCircle">🌬️</div>
      <div id="breath-label">Press Start to begin</div>
      <div id="breath-timer" class="mt-1" style="display:none">2:00</div>

      <div class="flex-row mt-2" style="justify-content:center">
        <button id="startBtn">Start (+${XP_RULES.mindfulness} XP)</button>
        <button id="stopBtn" class="btn-ghost" style="display:none">Stop</button>
      </div>

      <div class="divider"></div>
      <p class="text-muted" style="font-size:0.82rem">
        Sessions completed: <strong id="breathCount">${ls('breathCount', 0)}</strong>
      </p>
    </div>
    <div class="card slide-up">
      <h2>💡 Mindfulness Tips</h2>
      <ul style="padding-left:1.2rem;color:var(--muted);display:flex;flex-direction:column;gap:0.5rem;font-size:0.9rem">
        <li>Inhale slowly through your nose for 4 seconds.</li>
        <li>Hold gently for 2 seconds.</li>
        <li>Exhale through your mouth for 6 seconds.</li>
        <li>Repeat. Let each breath release tension.</li>
      </ul>
    </div>
  `;

  const circle  = document.getElementById('breatheCircle');
  const label   = document.getElementById('breath-label');
  const timerEl = document.getElementById('breath-timer');
  const startBtn= document.getElementById('startBtn');
  const stopBtn = document.getElementById('stopBtn');

  function phaseLoop(remaining, cyclePos) {
    // cyclePos: 0=inhale(4s), 1=hold(2s), 2=exhale(6s)
    if (remaining <= 0) {
      clearInterval(timerId);
      circle.classList.remove('inhale','exhale');
      label.textContent = 'Session complete! Well done 🌸';
      timerEl.style.display = 'none';
      startBtn.style.display = 'inline-flex';
      stopBtn.style.display  = 'none';
      const count = ls('breathCount', 0) + 1;
      lsSet('breathCount', count);
      document.getElementById('breathCount').textContent = count;
      addXP('mindfulness');
      checkBadges();
      showToast('Mindfulness session done! 🧘', 'success');
      return;
    }
    // breathing visual phase
    const phases = [
      { dur: 4, cls: 'inhale', txt: 'Inhale… 🌬️' },
      { dur: 2, cls: '',       txt: 'Hold…' },
      { dur: 6, cls: 'exhale', txt: 'Exhale… 💨' },
    ];
    // we determine phase from total elapsed
    const totalDur = 120 - remaining;
    const cycleLen = 12; // 4+2+6
    const posInCycle = totalDur % cycleLen;
    let ph;
    if      (posInCycle < 4)  ph = phases[0];
    else if (posInCycle < 6)  ph = phases[1];
    else                      ph = phases[2];
    circle.classList.remove('inhale','exhale');
    if (ph.cls) circle.classList.add(ph.cls);
    label.textContent = ph.txt;
  }

  function startSession() {
    let remaining = 120;
    timerEl.style.display = 'block';
    startBtn.style.display = 'none';
    stopBtn.style.display  = 'inline-flex';
    label.textContent = 'Inhale… 🌬️';
    circle.classList.add('inhale');

    function fmt(s) { return `${Math.floor(s/60)}:${String(s%60).padStart(2,'0')}`; }
    timerEl.textContent = fmt(remaining);

    timerId = setInterval(() => {
      remaining--;
      timerEl.textContent = fmt(remaining);
      phaseLoop(remaining, 0);
    }, 1000);
  }

  function stopSession() {
    clearInterval(timerId);
    circle.classList.remove('inhale','exhale');
    label.textContent = 'Press Start to begin';
    timerEl.style.display = 'none';
    startBtn.style.display = 'inline-flex';
    stopBtn.style.display  = 'none';
  }

  startBtn.onclick = startSession;
  stopBtn.onclick  = stopSession;
}

/* ── Quests ─────────────────────────────────────────────────────── */
const QUEST_DEFS = [
  {
    id: 'dawn_warrior',
    title: '🌅 The Dawn Warrior',
    story: 'The warrior wakes before the storm. Begin your day with a journal entry before noon.',
    check: () => {
      const j = ls('journal', []);
      return j.some(e => { const h = new Date(e.ts).getHours(); return h < 12; });
    },
    xpReward: 40,
    tip: 'Go to Journal and write an early morning entry.',
  },
  {
    id: 'mood_tracker_week',
    title: '📅 The Steady Compass',
    story: 'Track your mood for 3 or more days. Emotional awareness is your superpower.',
    check: () => {
      const logs = ls('moodLogs', []);
      const days = new Set(logs.map(l => l.ts.slice(0, 10)));
      return days.size >= 3;
    },
    xpReward: 40,
    tip: 'Log your mood for 3 different days.',
  },
  {
    id: 'zen_path',
    title: '🧘 The Zen Path',
    story: 'Complete 3 mindfulness breathing sessions. Stillness is strength.',
    check: () => ls('breathCount', 0) >= 3,
    xpReward: 40,
    tip: 'Finish 3 breathing sessions in Mindfulness.',
  },
  {
    id: 'journal_streak',
    title: '✍️ The Chronicler',
    story: 'Write 5 journal entries. Every word is a step towards clarity.',
    check: () => ls('journal', []).length >= 5,
    xpReward: 40,
    tip: 'Write 5 journal entries.',
  },
  {
    id: 'mood_warrior',
    title: '⚔️ Mood Warrior',
    story: 'Log all 6 mood types at least once. Know yourself fully.',
    check: () => {
      const moods = new Set(ls('moodLogs', []).map(l => l.mood));
      return MOODS.every(m => moods.has(m.key));
    },
    xpReward: 40,
    tip: 'Try logging each of the 6 moods at least once.',
  },
];

function renderQuests(container) {
  const completedQuests = ls('completedQuests', []);

  // award XP for newly completed quests
  QUEST_DEFS.forEach(q => {
    if (!completedQuests.includes(q.id) && q.check()) {
      completedQuests.push(q.id);
      lsSet('completedQuests', completedQuests);
      addXP('quest');
      showToast(`Quest complete: ${q.title}! 🎉`, 'hype');
    }
  });

  const done    = QUEST_DEFS.filter(q => completedQuests.includes(q.id));
  const pending = QUEST_DEFS.filter(q => !completedQuests.includes(q.id));

  container.innerHTML = `
    <div class="card slide-up">
      <h2>⚔️ Narrative Quests</h2>
      <p class="text-muted">Complete quests to earn XP and unlock your story. 
        ${done.length}/${QUEST_DEFS.length} quests completed.</p>
      <div class="xp-bar-wrap mt-1">
        <div class="xp-bar">
          <div class="xp-fill" style="width:${Math.round(done.length/QUEST_DEFS.length*100)}%"></div>
        </div>
      </div>
    </div>

    ${pending.length ? `
    <div class="card slide-up">
      <h2>🗺️ Active Quests</h2>
      ${pending.map(q => `
        <div class="quest-card">
          <h3>${q.title}</h3>
          <p>${q.story}</p>
          <p class="mt-1" style="font-size:0.8rem;color:var(--primary)">💡 ${q.tip}</p>
        </div>
      `).join('<div class="divider"></div>')}
    </div>` : ''}

    ${done.length ? `
    <div class="card slide-up">
      <h2>✅ Completed Quests</h2>
      ${done.map(q => `
        <div class="quest-card" style="border-color:var(--green);opacity:0.75">
          <h3 style="color:var(--green)">${q.title} ✓</h3>
          <p>${q.story}</p>
        </div>
      `).join('<div class="divider"></div>')}
    </div>` : ''}
  `;
}

/* ── Utility ────────────────────────────────────────────────────── */
function escapeHtml(str) {
  return str.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

/* ── Bootstrap ──────────────────────────────────────────────────── */
function init() {
  updateNavXP();
  window.addEventListener('hashchange', router);
  router();

  // expose randomHype globally for inline onclick
  window.randomHype = randomHype;
}

// Make sure DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', init);
} else {
  init();
}