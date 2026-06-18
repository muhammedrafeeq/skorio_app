# Skorio — Complete Development Plan

**Domain**: skorio.in  
**Stack**: Next.js 14 (App Router) · TypeScript · PostgreSQL (Supabase) · Tailwind CSS · JWT auth · pg (raw queries)  
**Current status**: Part 1 (Fan mode — World Cup 2026 football predictions) is live  
**Goal**: Full sports prediction + contest + tournament + social platform  

---

## Table of contents

1. [What is already built](#1-what-is-already-built)
2. [App architecture — two modes](#2-app-architecture--two-modes)
3. [Phase 1 — Complete current app (World Cup 2026)](#3-phase-1--complete-current-app-world-cup-2026)
4. [Phase 2 — Fan mode expansion](#4-phase-2--fan-mode-expansion)
5. [Phase 3 — Tournament mode](#5-phase-3--tournament-mode)
6. [Phase 4 — Social & fan communities](#6-phase-4--social--fan-communities)
7. [Phase 5 — Sports expansion](#7-phase-5--sports-expansion)
8. [Phase 6 — Scale & monetization](#8-phase-6--scale--monetization)
9. [Complete page list](#9-complete-page-list)
10. [Complete database schema](#10-complete-database-schema)
11. [Navigation architecture](#11-navigation-architecture)
12. [Ad & monetization setup](#12-ad--monetization-setup)
13. [Build priority order](#13-build-priority-order)
14. [Tech decisions](#14-tech-decisions)

---

## 1. What is already built

### Live on skorio.in (Part 1 — Fan mode, World Cup 2026)

| Feature | Status |
|---------|--------|
| User login — phone + 4-digit PIN (admin creates accounts) | ✅ Done |
| Super admin creates matches + sets schedules | ✅ Done |
| Match predictions — winner, top scorer, exact scoreline | ✅ Done |
| Points system — 2pts / 2pts / 4pts / bonus 3pts (max 11pts) | ✅ Done |
| Admin enters results → auto-calculate points | ✅ Done |
| Global leaderboard | ✅ Done |
| Prediction history | ✅ Done |
| Adsterra ads — Social Bar + Native Banner integrated | ✅ Done |
| skorio.in domain on Vercel | ✅ Done |

### Not yet built (remaining for World Cup)

| Feature | Priority |
|---------|---------|
| Login streak + daily card drops | 🔴 High |
| Player card collection system | 🔴 High |
| Daily spin wheel | 🔴 High |
| 7 mini games (penalty, formation, trivia etc) | 🔴 High |
| Flag quiz | 🔴 High |
| User-created contests | 🟡 Medium |
| Fan clubs + chat | 🟡 Medium |
| Sportle daily puzzle | 🟡 Medium |
| Push notifications (PWA) | 🟡 Medium |
| Shareable prediction cards | 🟡 Medium |
| Tournament mode (Part 2) | 🟢 Post-WC |

---

## 2. App architecture — two modes

The app has two distinct experiences accessed via a **top-bar mode toggle**:

```
┌─────────────────────────────────────────┐
│  Skorio    [ Fan | Tournament ]   🔔     │  ← Top bar with mode toggle
├─────────────────────────────────────────┤
│                                         │
│            Screen content               │
│         (changes per mode + tab)        │
│                                         │
├─────────────────────────────────────────┤
│  🏠 Home  🏆 Contests  🎮 Games         │  ← Fan mode tabs (blue)
│  👥 Social  👤 Profile                  │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│  Skorio    [ Fan | Tournament ]   🔔     │
├─────────────────────────────────────────┤
│                                         │
│            Screen content               │
│                                         │
├─────────────────────────────────────────┤
│  📊 Dashboard  🏟️ Tournaments           │  ← Tournament mode tabs (green)
│  📋 Standings  👤 Profile               │
└─────────────────────────────────────────┘
```

### Mode switcher rules
- Toggle sits in top bar — always visible, one tap to switch
- Bottom tab bar swaps completely between modes
- Color system changes: Fan = blue accent, Tournament = green accent
- App remembers last active tab in each mode
- Profile tab is shared between both modes
- Mode stored in Zustand global store or React context

---

## 3. Phase 1 — Complete current app (World Cup 2026)

**Timeline**: Before June 11, 2026 (World Cup start)  
**Priority**: Everything in this phase ships before the tournament begins

### 3.1 Login streak + daily rewards

**How it works**: Users earn cards for logging in daily. Missing a day resets the streak.

| Day | Reward |
|-----|--------|
| Day 1 | 2 cards |
| Day 3 | 2 cards + 5 pts |
| Day 7 | 2 cards + 10 pts + 1 guaranteed Rare+ |
| Day 30 | 1 Legendary card |

**DB table**: `daily_login_streaks` (user_id, current_streak, longest_streak, last_login_date)

**Implementation**:
- Check last_login_date on every login
- If date = yesterday → increment streak
- If date = today → no change (already logged in)
- If date < yesterday → reset streak to 1
- Trigger card drop after updating streak

**Effort**: 1 day

---

### 3.2 Player card collection system

#### Card tiers

| Rarity | Drop rate | Border | Players |
|--------|----------|--------|---------|
| Common | 60% | Gray | Backup GKs, squad fillers |
| Rare | 28% | Blue | Regular starters |
| Epic | 10% | Purple | Star players |
| Legendary | 2% | Gold | Captain, team icon (Messi, Ronaldo, Mbappé) |

#### Squad split per team
```
14 Common + 8 Rare + 3 Epic + 1 Legendary = 26 cards per team
48 teams × 26 = 1,248 total cards
```

#### Card earn triggers

| Trigger | Cards | Rarity boost |
|---------|-------|-------------|
| Daily login | 2 cards always | Day 7 → Rare+ |
| Trivia — 5 correct | 1 card | Perfect 5/5 → Epic chance |
| Any correct match prediction | 1 card per correct answer | All 3 → Legendary chance |
| Perfect prediction (11/11) | 1 guaranteed | Epic 70% / Legendary 30% |
| Leaderboard #1 end of matchday | 3 card pack | Normal rates |
| Hot streak (3 correct in a row) | 1 bonus card | Normal rates |

#### Drop probability

| Trigger | Common | Rare | Epic | Legendary |
|---------|--------|------|------|-----------|
| Daily login | 70% | 25% | 5% | — |
| Trivia | 60% | 30% | 9% | 1% |
| Match prediction | 65% | 28% | 6% | 1% |
| Perfect 11/11 | — | — | 70% | 30% |

#### Card design elements
- Jersey number (top left)
- Position badge: GK / DEF / MID / FWD (top right)
- Player initials avatar (center)
- Player name + team
- 4 stat bars: PAC · SHO · PAS · DEF
- Overall rating 1–99
- Rarity border color

#### Card reveal animation sequence
1. Card slides in face-down
2. Border glows in rarity color
3. Flips 180°
4. Name fades in, stats count up one by one
5. Legendary → 3-second extended reveal with pulsing border

#### Trading system rules
- Can trade: duplicate cards (qty > 1) OR non-favourite team cards
- Cannot trade: only copy of a fav team card
- Cannot trade: Legendary cards
- Trade requests expire after 48 hours
- Counter-offers allowed
- Smart suggestions: "This user needs your card"

#### Completion reward
Collect all 26 cards for favourite team → **200 bonus pts** + "Complete Squad" badge

**Effort**: 9 days

---

### 3.3 Daily spin wheel

- One free spin per 24 hours — resets at midnight
- Prizes: bonus pts, extra card, prediction lifeline, try again
- Animated wheel with satisfying stop
- Shown on Games tab with countdown to next spin
- Card drop has same rarity probabilities as daily login

**Effort**: 1 day

---

### 3.4 Mini games (7 games)

#### Game 1 — Penalty shootout
- 9-corner grid (3×3)
- Pick corner for each of 5 kicks
- Ball animates to chosen corner
- 2pts per correct corner, max 10pts
- Correct corners: set by admin per match

#### Game 2 — Formation predictor
- Pick starting formation for each team (4-3-3, 4-4-2 etc)
- Live pitch canvas updates as formation selected
- 5pts per correct team formation
- Admin enters actual formations after match

#### Game 3 — First goal timer
- Slider input: pick minute 1–90 (or "no goal")
- Clock ring animation shows selected minute
- Exact → 11pts, within 5min → 8pts, within 10 → 5pts, within 20 → 2pts
- "No goal" correct → 10pts

#### Game 4 — Football trivia quiz
- 5 questions per session, 30-second timer
- 3pts per correct answer, max 15pts
- Speed bonus: answer in 5s → +1pt
- Earns card drop on 5 correct answers
- 5 free sessions per day

#### Game 5 — Who am I?
- 5 progressive clues revealed one at a time
- Blurred player silhouette sharpens with each clue
- Clue 1 → 10pts, Clue 2 → 8pts ... Clue 5 → 2pts
- Text input for player name
- New player every match day

#### Game 6 — Tournament bracket
- Fill entire WC bracket before tournament
- Points: Group 1pt, R16 2pts, QF 4pts, SF 8pts, Final 16pts
- Correct champion → bonus 20pts
- Locked at tournament kick-off

#### Game 7 — Last team standing (survivor)
- Pick one team to win each match day
- Wrong pick = eliminated
- Last survivor wins 50 bonus pts
- Cannot pick same team twice in a row

**Effort**: 7 days (1 day per game)

---

### 3.5 Flag quiz (standalone game)

- World Cup 48 teams' flags only (football focus)
- Show flag → 4 options → pick correct country
- 10-second countdown per flag, 5 rounds per session
- Speed scoring: answer in 3s → 3pts, 6s → 2pts, 10s → 1pt
- Perfect round (5/5) → bonus 5pts
- Earns card drop on correct answers (40–70% chance based on speed)
- 5 free sessions per day

**Effort**: 2 days

---

### 3.6 Sportle — daily puzzle

- Wordle-style: guess mystery player in 6 attempts
- Each guess reveals stat clues: age, nationality, position, club, rating
- One puzzle per day, same for all users — resets at midnight
- Shareable result grid (like Wordle)
- 10pts for correct guess, fewer attempts = more pts
- Attempt 1 → 10pts, Attempt 6 → 5pts

**Effort**: 2 days

---

### 3.7 Shareable prediction cards

- After submitting prediction → auto-generate a share image
- Shows: user name, picks (Brazil 2-1 France), Skorio branding
- After result → updated image shows points earned
- One-tap share to WhatsApp / Telegram
- Generated server-side using `@vercel/og` or `html-to-image`

**Effort**: 1 day

---

### 3.8 Push notifications (PWA)

Setup: Firebase Cloud Messaging (FCM) via PWA service worker

| Notification | Trigger | Priority |
|-------------|---------|---------|
| Deadline reminder (30 min) | 30min before kick-off, unsubmitted users only | Critical |
| Streak at risk | 9 PM if not logged in | Critical |
| Result published | Admin publishes results | High |
| Card drop | Any card earned | High |
| Fan war starting | 30min before fan war match | High |
| Daily spin ready | 9 AM every day | Medium |
| Trade request | Incoming trade offer | Medium |
| Leaderboard moved up | User enters top 3 | Medium |
| Cold user re-engagement | 3 days no login | Low |

**Rules**:
- Max 3 notifications per day per user
- Never send between 11 PM and 7 AM
- User can customise which types they receive

**Effort**: 2 days

---

### 3.9 Adsterra ad placements (remaining)

Already done: Social Bar (layout.tsx), Native Banner (/matches in-feed)

Remaining to integrate:

| Unit | Placement | Code needed |
|------|-----------|-------------|
| 300x250_1 | /matches/[id]/result — after points card | Paste GET CODE |
| 728x90_1 | /leaderboard — below podium (desktop) | Paste GET CODE |
| 320x50_1 | /matches — in-feed after card 6 (mobile) | Paste GET CODE |
| 468x60_1 | /history — between history cards | Paste GET CODE |
| 160x600_1 | /leaderboard — right sidebar (desktop) | Paste GET CODE |
| 160x300_1 | /matches/[id]/result — below breakdown | Paste GET CODE |
| Popunder_1 | /matches/[id]/result — on load | Paste GET CODE |

**Rule**: No ads on /admin/* or /matches/[id]/predict

---

### Phase 1 total effort

| Task | Effort |
|------|--------|
| Login streak + rewards | 1 day |
| Player card collection | 9 days |
| Daily spin wheel | 1 day |
| 7 mini games | 7 days |
| Flag quiz | 2 days |
| Sportle daily puzzle | 2 days |
| Shareable prediction cards | 1 day |
| Push notifications | 2 days |
| Remaining ad placements | 0.5 days |
| **Total** | **~25.5 days** |

---

## 4. Phase 2 — Fan mode expansion

**Timeline**: August–October 2026 (post World Cup)

### 4.1 User-created contests

Any logged-in user can create a contest — public (discoverable) or private (invite via 6-digit code).

#### 20 contest types

**Match-based** (needs a match):
1. Match predictor — winner, scorer, scoreline (all sports)
2. Formation predictor — pick starting XI formation (football)
3. Playing XI — pick full 11-player lineup (cricket)
4. Timeline predictor — predict event minute/over (any sport)
5. Stat range predictor — total goals/runs in ranges (any sport)
6. Player performance pick — rate each player Excellent/Good/Average/Poor
7. Live event buzzer — buzz to predict next event during match
8. Man of the match pick — pick MOTM before kick-off
9. Exact stat predictor — corners, sixes, wickets exact number

**Tournament-based** (across multiple matches):
10. Bracket predictor — fill full tournament bracket
11. Tournament awards predictor — golden boot, best player etc
12. Survivor contest — pick one team per day, wrong = eliminated
13. Season top picks — predict top 4, top scorer, relegation

**Knowledge-based** (no match needed):
14. Quiz contest — custom questions from question bank
15. Who am I? contest — creator picks mystery players
16. Flag / jersey quiz contest — creator picks which flags
17. Stadium guesser — show stadium photo, guess the club
18. Which year? contest — guess the year of famous sports moments
19. Higher or lower — is this stat higher or lower than X?

**Opinion-based**:
20. Fan poll — opinion votes, most popular answer wins
21. Head to head debate — vote + one-line reason (Messi vs Ronaldo etc)
22. Rate the match — rate 1–10 after match, closest to creator's rating wins

#### Contest structure
- Creator names contest, sets visibility (public/private), max participants, join deadline
- 6-digit join code for private contests
- Shareable link auto-generated
- Creator can pick real matches (from super admin schedule) OR create virtual matches
- Leaderboard auto-calculated after results
- Creator manages: view entries, remove participants, close early

#### Points per type

| Contest type | Scoring |
|-------------|---------|
| Match predictor (football) | Winner 2pts, scorer 2pts, scoreline 4pts, bonus 3pts = max 11pts |
| Match predictor (cricket) | Toss 1pt, winner 2pts, top bat 2pts, top bowl 2pts, score range 3pts, bonus 4pts = max 14pts |
| Playing XI | Each correct player 2pts, captain +5pts, VC +3pts = max 62pts |
| Quiz | Correct 3pts, speed <5s +1pt, perfect round +5pts |
| Bracket | Group 1pt, R16 2pts, QF 4pts, SF 8pts, Final 16pts, champion +20pts |
| Timeline | Exact 11pts, within 5 → 8pts, within 10 → 5pts, within 20 → 2pts |
| Higher or lower | Correct 3pts, streak of 3 +3pts, streak of 5 +5pts |

**Effort**: 17 days

---

### 4.2 XP & level system

- XP earned for every action (never resets between tournaments)
- Login +5, predict +10, correct answer +20, quiz correct +5, trade +10
- Levels 1–50 with unlocks at each milestone
- Unlocks: card borders, profile themes, special badges, league access

**Effort**: 2 days

---

### 4.3 Achievements & badges (30+)

| Badge | How to earn |
|-------|------------|
| Perfect Predictor | Score 11/11 pts on a match |
| Hat-trick | 3 perfect predictions in a row |
| Legendary Collector | Own 5 Legendary cards |
| Complete Squad | Collect all 26 fav team cards |
| Hot Streak | 5 correct predictions in a row |
| Underdog Hunter | 5 upset predictions correct |
| Night Owl | Submit prediction after midnight |
| Early Bird | Predict 24hrs before deadline |
| War Hero | Win 5 fan wars as MVP |
| Club Captain | Win weekly captain 3 times |
| Sportle Master | Solve Sportle in 1 attempt |
| 7-Day Streak | Log in 7 days in a row |
| 30-Day Streak | Log in 30 days in a row |
| Card Hoarder | Own 100 cards |
| Survivor | Win last team standing |
| Bracket Master | 10+ correct bracket picks |
| Top Fan | Earn top fan badge for any player |
| Tournament Champion | Fan club wins most fan wars |

**Effort**: 2 days

---

### 4.4 Points shop

Users spend accumulated pts on:
- Extra spin (+1 spin today)
- Card pack (5 cards, guaranteed Rare+)
- Prediction lifeline (see most popular answer)
- Profile border (cosmetic unlock)
- Badge boost (XP multiplier for 24hrs)

**Effort**: 1 day

---

### Phase 2 total effort

| Task | Effort |
|------|--------|
| User-created contests (20 types) | 17 days |
| XP + level system | 2 days |
| Achievements + badges | 2 days |
| Points shop | 1 day |
| **Total** | **~22 days** |

---

## 5. Phase 3 — Tournament mode

**Timeline**: October–December 2026

Tournament mode is the second half of the app — for managing real local tournaments (football, cricket, PES, any sport). Accessed via the **Tournament** toggle in the top bar.

### 5.1 Tournament formats

| Format | Description | Best for |
|--------|-------------|---------|
| League only | Round robin — everyone plays everyone | 6–10 teams, long duration |
| Knockout only | Single elimination — lose and you're out | 8/16/32 teams, weekend cup |
| League + Knockout | Groups feed into knockout rounds | 8–32 teams, World Cup mirror |
| Double elimination | Lose once = losers bracket, lose twice = out | PES/FIFA online tournaments |
| Swiss system | Each round paired by current standing | 20+ teams, no full round robin |
| League + Playoff | Full season then top teams play off | IPL/NBA style |
| Custom combination | Admin chains up to 4 phases | Any unique local format |

### 5.2 Sports supported

Any sport — admin picks type and scoring config:
- Football / PES / FIFA (W3 D1 L0, GD tiebreaker)
- Cricket (W2 NR1 L0, NRR tiebreaker)
- Basketball (W2 L0, point difference tiebreaker)
- Badminton / Table tennis (sets tracked)
- Kabaddi, Volleyball, Hockey
- Esports: BGMI, Valorant, Chess online
- Custom sport (admin defines win/draw/loss pts + up to 5 stat fields)

### 5.3 Points table format

Live standings showing:
- Rank, Team name
- Played, Won, Drawn, Lost
- Goals/Runs For, Goals/Runs Against
- Goal difference / NRR
- Total points
- Form dots (last 5: W/D/L colored circles)

### 5.4 Match management

- Admin schedules matches: date, time, venue
- Enter result: score + scorers + cards + MOTM (football) / runs + wickets + top bat/bowl (cricket)
- Screenshot proof upload for PES/FIFA online (dispute system)
- Two-leg ties: aggregate score tracked, away goals rule configurable
- Extra time + penalties result entry

**After each result entered**:
1. Points table updates instantly
2. Knockout bracket advances winner
3. Group qualification auto-checked
4. Player stats recalculated
5. Push notification sent to all tournament followers

### 5.5 Team + player management

- Admin creates teams: name, badge color, logo (optional), kit color
- Add player roster per team: name, position, jersey number
- Players do NOT need Skorio accounts — just names
- Player stats tracked across tournament: goals, assists, cards, MOTM count, custom stats

### 5.6 Tournament creation flow (8 steps)

1. Pick format (league/knockout/league+KO/double elim/swiss/playoff/custom)
2. Basic info (name, sport, description, location, banner image)
3. Configure scoring (win/draw/loss pts, tiebreaker order, stat fields)
4. Add teams (name, color, logo, player roster)
5. Group draw if applicable (random or manual)
6. Generate fixtures (auto-schedule or manual)
7. Set prizes (champion, runner-up, top scorer, custom awards)
8. Publish + share (link + WhatsApp share button)

### 5.7 Tournament mode tabs

**Dashboard**: My tournaments, quick actions (enter result, schedule match), create button

**Tournaments**: Active, upcoming, completed list — tap to view tournament home

**Standings**: Live points table for selected tournament — group tabs if group stage

**Profile**: Shared with Fan mode

**Effort**: 23 days

---

## 6. Phase 4 — Social & fan communities

**Timeline**: November 2026 – February 2027

### 6.1 Fan club system

- Every team (48 WC teams + major clubs: Real Madrid, Barcelona, Liverpool, Man City, Man United, PSG, Bayern, Juventus, Arsenal etc) has a fan club
- Auto-join on favourite team selection
- Second team slot unlockable for 100pts

**Fan club features**:
- Member count, club badge, team colors
- Weekly captain: highest scorer in club that week (crown badge)
- Club leaderboard: members ranked by pts within club
- Club stats: avg prediction accuracy, club win/loss record in fan wars
- All-time war record vs other clubs

### 6.2 Fan wars

- Auto-triggered when two clubs' teams play each other
- Whichever club's members have better collective prediction accuracy wins
- Winning club members earn +5pts each
- War MVP: highest individual accuracy from winning club gets badge
- Derby wars: traditional rivalry matches (Brazil vs Argentina, El Clasico) → 2× stakes
- Tournament war champion: most war wins = permanent badge for all members

### 6.3 WhatsApp-style group chat

**3 chat room types**:
1. Fan club chat (always open)
2. Match day chat (opens 2hrs before kick-off, read-only at full time, archived 24hrs later)
3. Global Skorio chat (all users)

**Features**:
- 8 emoji reactions per message (🔥😂💀🙏😤💯😭🎉)
- Share prediction card to chat (one tap)
- Pinned match info at top of match chat
- Report message button
- Auto-filter spam
- Admin/captain can mute users

**Realtime**: Supabase subscriptions — no separate WebSocket server needed

### 6.4 Player fan pages

- Every player from all 48 squads has a fan page
- Follow up to 5 players
- Fan count displayed publicly (Messi vs Ronaldo rivalry drives organic growth)
- Player tournament stats: goals, assists, cards, rating per match
- Card owners shown: "842 users own this card"
- Weekly "Top Fan" badge for most engaged follower
- Push alert when followed player scores

### 6.5 Social activity feed

- Personalised feed: clubs, friends, players you follow
- Activity types: card drops, leaderboard moves, war results, fan milestones, badge unlocks
- Fan opinion polls (admin or captain posts)
- Match verdict posts: 100-char post-match opinion
- Hot moments spotlight: most reacted chat message, biggest upset call
- Weekly community awards: best predictor, hottest club, biggest upset caller

### 6.6 Shareable moment cards

Auto-generated shareable image for:
- Legendary card drop
- #1 leaderboard position
- Perfect 11/11 prediction
- Fan war MVP
- Badge unlock
- Complete squad collection

One-tap share to WhatsApp/Telegram with Skorio branding → free viral marketing

**Effort**: 14 days

---

## 7. Phase 5 — Sports expansion

**Timeline**: March–August 2027

### 7.1 Cricket (highest priority for India)

**Prediction format per match**:
- Toss winner → 1pt
- Match winner → 2pts
- Top batsman → 2pts
- Top bowler → 2pts
- Score range → 3pts
- All correct → bonus 4pts = max 14pts

**Cricket-specific mini games**:
- Over predictor: predict runs scored in next over
- Wicket timer: predict over of next wicket
- Powerplay score guess: predict runs in powerplay
- DRS challenge predictor: will review overturn the decision?

**Tournaments to cover**: IPL, T20 World Cup, ODI series, Test matches

**Cricket fan clubs**: All IPL teams (CSK, MI, RCB, KKR, SRH, DC, GT, LSG, PBKS, RR)

### 7.2 Basketball (NBA + FIBA)

Predict: quarter winner, total points bracket, top scorer, match winner

### 7.3 Tennis (Grand Slams)

Predict: match winner, sets played, first set winner, upset picks

### 7.4 F1

Predict: qualifying position, race winner, fastest lap, pit stop count, safety car (yes/no)

### 7.5 Kabaddi (Pro Kabaddi League)

### 7.6 Esports (BGMI, Valorant)

### 7.7 Sport switcher navigation

Top nav gets sport filter pills: ⚽ Football · 🏏 Cricket · 🏀 Basketball etc
Each sport has own match feed, leaderboard, card collection

**Effort**: 15 days for cricket (first), then ~7 days per additional sport

---

## 8. Phase 6 — Scale & monetization

**Timeline**: Ongoing

### 8.1 Ad networks progression

| Phase | Network | Monthly revenue est. |
|-------|---------|---------------------|
| Now | Adsterra (9 units live) | ₹200–800 |
| World Cup (June) | Adsterra + traffic spike | ₹2,000–8,000 |
| 10k sessions/month | Switch to Ezoic | 3× RPM vs Adsterra |
| Scale | Ezoic + Dream11 affiliate | ₹10,000–40,000 |

**Dream11 affiliate**: Referral links on leaderboard + result pages → ₹100–300 per depositing user

### 8.2 Revenue streams

| Stream | When | Est. revenue |
|--------|------|-------------|
| Adsterra ads | Now | ₹200–800/month |
| Entry fee per tournament (₹50–200) | World Cup | ₹1,000–5,000/tournament |
| Razorpay payment integration | Phase 2 | Needed for paid contests |
| Skorio Pro (₹49–99/month) | Phase 2 | Ad-free + all games + exclusive cards |
| Private league creation (₹299/tournament) | Phase 2 | Unlimited members + CSV export |
| Premium card packs (₹29 for 5 cards) | Phase 3 | High volume potential |
| Sponsored matches (₹500–5,000/match) | World Cup | Local businesses |
| White-label platform (₹5,000 setup + ₹999/month) | Phase 4 | Communities, offices |

### 8.3 PWA → Android app

Convert skorio.in to PWA immediately (manifest.json + service worker):

```json
// public/manifest.json
{
  "name": "Skorio",
  "short_name": "Skorio",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#0A0A0F",
  "theme_color": "#7C6FF7",
  "icons": [
    { "src": "/icon-192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "/icon-512.png", "sizes": "512x512", "type": "image/png" }
  ]
}
```

Flutter Android app (for AdMob): Submit to Play Store 2 weeks before World Cup

**AdMob stack for Android**:
- AdMob (primary) — all formats
- AppLovin MAX (mediation layer) — connects all networks, +30% revenue
- Unity Ads — rewarded video before mini-games
- App Open Ad on launch

---

## 9. Complete page list

### Fan mode — user pages (50+ pages)

```
/                           Home feed (matches, leaderboard, card alerts)
/login                      Phone + 4-digit PIN
/onboarding/team            Favourite team picker (shown once)

/matches                    All matches with countdown + status
/matches/[id]/predict       Prediction form
/matches/[id]/result        Result reveal + points breakdown
/matches/[id]/chat          Match day chat room
/matches/[id]/closed        Deadline passed page

/leaderboard                Global leaderboard + podium
/history                    Prediction history + accuracy stats
/feed                       Personalised social activity feed

/contests                   Public contest discovery
/contests/create            Multi-step contest creator
/contests/join/[code]       Join via 6-digit code
/contests/[id]              Contest home + leaderboard
/contests/[id]/play         Play screen (varies by contest type)
/contests/[id]/leaderboard  Live contest leaderboard
/contests/[id]/results      Final standings + correct answers
/my-contests                Contests I created + joined

/games                      All mini games hub
/games/spin                 Daily spin wheel
/games/sportle              Daily Sportle puzzle
/games/penalty              Penalty shootout
/games/formation            Formation predictor
/games/firstgoal            First goal timer
/games/trivia               Football trivia quiz
/games/whoami               Who am I?
/games/bracket              Tournament bracket
/games/survivor             Last team standing
/games/flags                Flag quiz
/games/crossbar             Crossbar challenge

/collection                 My player card collection grid
/collection/[cardId]        Card detail + trade option
/collection/reveal          Card flip reveal animation

/trades                     Incoming + outgoing trade requests
/users/[id]                 Public user profile
/users/[id]/collection      Public collection view

/fanclubs                   Browse all fan clubs
/fanclubs/[teamId]          Fan club home (members, stats, war record)
/fanclubs/[teamId]/chat     Fan club WhatsApp-style chat
/fanclubs/[teamId]/leaderboard Fan club leaderboard
/fanclubs/wars              Fan war board + history

/players                    Browse all players
/players/[playerId]         Player fan page + stats + followers

/profile                    My profile + badges + XP
/profile/edit               Edit profile settings
/settings                   Notifications, language, account, Pro
/unauthorized               Access denied
```

### Tournament mode — user pages

```
/tournaments                Tournament discovery (public + joined)
/tournaments/[id]           Tournament home (overview, teams, upcoming matches)
/tournaments/[id]/table     Live points table (auto-updates on results)
/tournaments/[id]/bracket   Visual knockout bracket (all rounds)
/tournaments/[id]/schedule  Full fixture list with date/time/venue
/tournaments/[id]/matches/[matchId] Match detail + stats
/tournaments/[id]/teams     All teams list
/tournaments/[id]/teams/[teamId] Team profile + roster + match history
/tournaments/[id]/stats     Top scorers, cards, MOTM, NRR
```

### Admin pages

```
/admin                      Dashboard (stats, recent activity)
/admin/matches              Match list + create
/admin/matches/[id]/questions Question config
/admin/matches/[id]/entries All user submissions
/admin/matches/[id]/results Enter results + calculate + publish
/admin/users                User list + create (phone + PIN)
/admin/cards                Player card management
/admin/cards/bulk           Bulk JSON import (48-team squads)
/admin/fanclubs             Fan club moderation
/admin/leaderboard          Leaderboard + override + reset
/admin/notifications        Send custom push notification
/admin/events               Create special events (double pts, bonus cards)
/admin/contests             All user-created contests moderation
/admin/tournaments          Tournament management
/admin/tournaments/create   Multi-step tournament creator
/admin/tournaments/[id]     Manage tournament (results, schedule, teams)
/admin/tournaments/[id]/matches/[matchId]/result Result entry form
```

---

## 10. Complete database schema

### Existing tables (already built)

```sql
users (id, name, phone, pin_hash, role, is_active)
matches (id, team_home, team_away, match_time, deadline, status)
questions (id, match_id, type, label, points)
predictions (id, user_id, match_id, question_id, answer, submitted_at)
results (id, match_id, question_id, correct_answer)
scores (id, user_id, match_id, points)
```

### Phase 1 — Card collection tables

```sql
player_cards (id, team_id, player_name, position, jersey_number, rarity, overall_rating, stats jsonb, is_active)
user_cards (id, user_id, card_id, quantity, earned_via, first_earned_at)
card_drops (id, user_id, card_id, trigger, trigger_ref_id, dropped_at)
card_trades (id, from_user_id, to_user_id, offered_card_id, requested_card_id, status, counter_card_id, expires_at)
user_favourite_teams (user_id, team_id, slot)
daily_login_streaks (user_id, current_streak, longest_streak, last_login_date)
quiz_sessions (id, user_id, score, correct_count, cards_earned uuid[], difficulty, played_at)
sportle_puzzles (id, player_id, clues jsonb, date)
sportle_attempts (id, user_id, puzzle_id, guesses jsonb, solved, attempts_count, played_at)
```

### Phase 2 — Contest tables

```sql
user_contests (id, creator_id, name, type, sport, visibility, join_code char(6), status, max_participants, join_deadline, config jsonb, created_at)
user_contest_matches (id, contest_id, match_id, is_virtual, virtual_team_a, virtual_team_b, virtual_match_time, predict_deadline)
user_contest_participants (id, contest_id, user_id, joined_at, total_pts, rank, status)
user_contest_entries (id, contest_id, user_id, question_key, answer jsonb, pts_earned, submitted_at)
user_contest_questions (id, contest_id, question, type, options jsonb, correct_answer, points, timer_seconds, order)
xp_log (id, user_id, amount, action, created_at)
achievements (id, key, name, description, icon)
user_achievements (id, user_id, achievement_id, earned_at)
```

### Phase 3 — Tournament tables

```sql
tournaments (id, name, sport, format, status, visibility, scoring_config jsonb, stat_fields jsonb, phases jsonb, group_count, teams_per_group, teams_advance, location, start_date, end_date, created_by, prize_config jsonb, banner_url)
tournament_teams (id, tournament_id, name, badge_color, logo_url, group_id, seed)
tournament_players (id, team_id, name, position, jersey_number)
tournament_groups (id, tournament_id, name, phase)
tournament_matches (id, tournament_id, team_a_id, team_b_id, phase, round_number, leg, match_date, venue, status, score_a, score_b, stats jsonb, winner_id, screenshot_url, motm_player_id)
tournament_standings (id, tournament_id, team_id, group_id, played, won, drawn, lost, score_for, score_against, points, nrr, form text[])
tournament_player_stats (id, tournament_id, player_id, goals, assists, yellow_cards, red_cards, motm_count, custom_stats jsonb)
knockout_brackets (id, tournament_id, phase, match_id, team_a_id, team_b_id, winner_id, bracket_type)
```

### Phase 4 — Social tables

```sql
fan_clubs (id, team_id, name, member_count, war_wins, war_losses)
fan_club_members (id, user_id, club_id, joined_at, is_captain)
fan_wars (id, club_a_id, club_b_id, match_id, status, winner_club_id, is_derby)
chat_rooms (id, type, reference_id, status)
chat_messages (id, room_id, user_id, content, created_at)
chat_reactions (id, message_id, user_id, emoji)
player_pages (id, player_card_id, follower_count)
player_follows (id, user_id, player_page_id, followed_at)
feed_items (id, user_id, type, content jsonb, created_at)
polls (id, creator_id, question, options jsonb, closes_at)
poll_votes (id, poll_id, user_id, option_index)
match_verdicts (id, match_id, user_id, text, created_at)
```

---

## 11. Navigation architecture

### Mode switcher implementation

```tsx
// store/modeStore.ts
import { create } from 'zustand'
import { persist } from 'zustand/middleware'

type Mode = 'fan' | 'tournament'

interface ModeStore {
  mode: Mode
  fanTab: string
  tournamentTab: string
  setMode: (mode: Mode) => void
  setFanTab: (tab: string) => void
  setTournamentTab: (tab: string) => void
}

export const useModeStore = create<ModeStore>()(
  persist(
    (set) => ({
      mode: 'fan',
      fanTab: 'home',
      tournamentTab: 'dashboard',
      setMode: (mode) => set({ mode }),
      setFanTab: (tab) => set({ fanTab: tab }),
      setTournamentTab: (tab) => set({ tournamentTab: tab }),
    }),
    { name: 'skorio-mode' }
  )
)
```

### Fan mode tabs (5 tabs)

| Tab | Icon | Route |
|-----|------|-------|
| Home | ti-home | / |
| Contests | ti-trophy | /contests |
| Games | ti-device-gamepad-2 | /games |
| Social | ti-users-group | /fanclubs |
| Profile | ti-user | /profile |

### Tournament mode tabs (4 tabs)

| Tab | Icon | Route |
|-----|------|-------|
| Dashboard | ti-layout-dashboard | /tournaments/dashboard |
| Tournaments | ti-tournament | /tournaments |
| Standings | ti-table | /tournaments/standings |
| Profile | ti-user | /profile |

### Color system per mode

```css
/* Fan mode — blue accent */
--mode-primary: var(--color-background-info);
--mode-text: var(--color-text-info);
--mode-border: var(--color-border-info);

/* Tournament mode — green accent */
--mode-primary: var(--color-background-success);
--mode-text: var(--color-text-success);
--mode-border: var(--color-border-success);
```

---

## 12. Ad & monetization setup

### Adsterra units (predikto-sage.vercel.app → update to skorio.in)

| ID | Unit | Format | Status |
|----|------|--------|--------|
| 29533411 | SocialBar_1 | Social Bar | ✅ Live in layout.tsx |
| 29533340 | NativeBanner_1 | Native Banner | ✅ Live in /matches |
| 29533344 | 300x250_1 | Banner 300×250 | ⏳ Need GET CODE |
| 29533346 | 728x90_1 | Banner 728×90 | ⏳ Need GET CODE |
| 29533345 | 320x50_1 | Banner 320×50 | ⏳ Need GET CODE |
| 29533343 | 468x60_1 | Banner 468×60 | ⏳ Need GET CODE |
| 29533341 | 160x600_1 | Banner 160×600 | ⏳ Need GET CODE |
| 29533342 | 160x300_1 | Banner 160×300 | ⏳ Need GET CODE |
| 29533339 | Popunder_1 | Popunder | ⏳ Need GET CODE |

### Ad placement map

```
/matches                → Native banner after card 3 (✅ done)
                        → 320x50 after card 6 (mobile)
/leaderboard            → 728x90 below podium (desktop)
                        → 160x600 right sidebar (desktop)
/matches/[id]/result    → 300x250 after points card ← highest CTR
                        → 160x300 below breakdown
                        → Popunder on page load
/history                → 468x60 between history cards
/admin/*                → NO ADS (excluded in layout.tsx)
/matches/[id]/predict   → NO ADS (policy + UX)
```

### Adsterra update checklist

- [ ] Update site URL in Adsterra from predikto-sage.vercel.app to skorio.in
- [ ] Get code for all remaining 7 units
- [ ] Integrate banner components per placement above
- [ ] Verify popunder fires correctly on result page

---

## 13. Build priority order

### Immediate (before June 11, 2026)

| Priority | Task | Effort | Impact |
|----------|------|--------|--------|
| 1 | Login streak + daily rewards | 1 day | Retention |
| 2 | Player card collection (earn triggers) | 5 days | Engagement |
| 3 | Card reveal animation + collection UI | 4 days | UX |
| 4 | Daily spin wheel | 1 day | Daily habit |
| 5 | Penalty shootout game | 1 day | Fun |
| 6 | Football trivia quiz game | 1 day | Knowledge |
| 7 | Flag quiz game | 2 days | Fun |
| 8 | Sportle daily puzzle | 2 days | Daily habit |
| 9 | Tournament bracket game | 1 day | WC engagement |
| 10 | Who am I? game | 1 day | Knowledge |
| 11 | Last team standing game | 1 day | Social |
| 12 | Formation predictor game | 1 day | Football |
| 13 | First goal timer game | 1 day | Football |
| 14 | Shareable prediction cards | 1 day | Viral |
| 15 | Push notifications | 2 days | Retention |
| 16 | Remaining ad placements | 0.5 days | Revenue |
| 17 | Favourite team picker onboarding | 1 day | Onboarding |

### Post World Cup (August–October 2026)

| Priority | Task | Effort | Impact |
|----------|------|--------|--------|
| 18 | User contest creator (20 types) | 17 days | Core feature |
| 19 | Card trading system | 2 days | Social |
| 20 | XP + level system | 2 days | Progression |
| 21 | Achievements + badges | 2 days | Gamification |
| 22 | Points shop | 1 day | Economy |
| 23 | Mode switcher UI | 1 day | Architecture |

### October–December 2026

| Priority | Task | Effort | Impact |
|----------|------|--------|--------|
| 24 | Tournament mode — engine + DB | 6 days | Core feature |
| 25 | Tournament mode — public pages | 7 days | User-facing |
| 26 | Tournament mode — admin creator | 7 days | Admin |
| 27 | Bracket engine (KO/double elim) | 3 days | Complex feature |

### 2027

| Priority | Task | Effort | Impact |
|----------|------|--------|--------|
| 28 | Fan clubs + chat | 8 days | Social |
| 29 | Fan wars system | 2 days | Viral |
| 30 | Player fan pages | 3 days | Fan |
| 31 | Social activity feed | 3 days | Social |
| 32 | Cricket predictions | 5 days | Expansion |
| 33 | Cricket mini-games | 3 days | Expansion |
| 34 | Android PWA → Flutter app | 7 days | Distribution |
| 35 | Skorio Pro subscription | 2 days | Revenue |
| 36 | Multi-language (Malayalam, Hindi, Tamil) | 3 days | Growth |

---

## 14. Tech decisions

### Stack (confirmed)

| Layer | Choice | Reason |
|-------|--------|--------|
| Framework | Next.js 14 App Router | Already in use |
| Language | TypeScript | Already in use |
| Database | PostgreSQL via Supabase | Already in use |
| ORM | None — raw pg queries | Your preference |
| Auth | Custom JWT + httpOnly cookie | Already built |
| Hosting | Vercel | Already deployed |
| Realtime (chat) | Supabase subscriptions | No extra server needed |
| Push notifications | Firebase FCM (PWA) | Free, reliable |
| Image sharing | @vercel/og or html-to-image | Serverless, free |
| State management | Zustand | Mode switcher + global state |
| Styling | Tailwind CSS | Already in use |

### Key API integrations

| Integration | Purpose | Cost |
|-------------|---------|------|
| Adsterra | Ad revenue | Free (revenue share) |
| Firebase FCM | Push notifications | Free tier sufficient |
| Supabase realtime | Fan club chat | Included in Supabase |
| @vercel/og | Shareable cards | Free |
| Razorpay | Paid contest entry (Phase 2) | 2% per transaction |
| NewsAPI | Sports news feed (Phase 3) | Free tier: 100 req/day |
| CricAPI | Live cricket scores (Phase 5) | Paid |

### Design system

```css
/* Dark theme color tokens */
--bg-base:       #0A0A0F
--bg-surface:    #10101A
--bg-card:       rgba(255,255,255,0.04)
--border-card:   rgba(255,255,255,0.08)
--accent-violet: #7C6FF7   /* Fan mode primary */
--accent-green:  #1DC98A   /* Tournament mode primary */
--accent-amber:  #F5A623
--accent-red:    #F04B4B
--text-primary:  #F0F0F5
--text-secondary:#8888A0
--text-muted:    #44445A
--gold:          #FFD700   /* Legendary card */
--silver:        #C0C0C0   /* Rare card */
--bronze:        #CD7F32   /* Epic card */

/* Animation tokens */
--transition-base:   200ms ease-out
--transition-page:   300ms cubic-bezier(0.25, 0.46, 0.45, 0.94)
--stagger-delay:     60ms
--count-up-duration: 800ms ease-out
```

### Card drop engine (TypeScript)

```typescript
type DropTrigger = 
  | 'daily_login' | 'trivia' | 'prediction' 
  | 'perfect' | 'streak' | 'leaderboard'

const RARITY_WEIGHTS: Record<DropTrigger, Record<string, number>> = {
  daily_login:  { common: 70, rare: 25, epic: 5,  legendary: 0  },
  trivia:       { common: 60, rare: 30, epic: 9,  legendary: 1  },
  prediction:   { common: 65, rare: 28, epic: 6,  legendary: 1  },
  perfect:      { common: 0,  rare: 0,  epic: 70, legendary: 30 },
  streak:       { common: 65, rare: 28, epic: 6,  legendary: 1  },
  leaderboard:  { common: 60, rare: 30, epic: 9,  legendary: 1  },
}

function pickRarity(trigger: DropTrigger): string {
  const weights = RARITY_WEIGHTS[trigger]
  const roll = Math.random() * 100
  let cumulative = 0
  for (const [rarity, weight] of Object.entries(weights)) {
    cumulative += weight
    if (roll < cumulative) return rarity
  }
  return 'common'
}

export async function dropCard(
  userId: string,
  trigger: DropTrigger,
  favTeamId?: string,
  triggerRefId?: string
) {
  const rarity = pickRarity(trigger)
  const card = await getRandomCardByRarity(rarity, favTeamId)
  await upsertUserCard(userId, card.id, trigger)
  await logCardDrop(userId, card.id, trigger, triggerRefId)
  return card
}
```

### Integration checklist (Phase 1)

- [ ] After daily login → `dropCard(userId, 'daily_login')` × 2 + update streak
- [ ] After trivia session 5 correct → `dropCard(userId, 'trivia', favTeamId, quizSessionId)`
- [ ] After match result, per correct answer → `dropCard(userId, 'prediction', favTeamId, matchId)`
- [ ] If all 3 correct (11/11) → `dropCard(userId, 'perfect', favTeamId, matchId)`
- [ ] After 3 correct predictions in a row → `dropCard(userId, 'streak', favTeamId)`
- [ ] After matchday leaderboard, for rank #1 → `dropCard(userId, 'leaderboard')` × 3
- [ ] Add `/collection/reveal` redirect after every drop
- [ ] Add trade expiry cron job (every hour, expire trades past `expires_at`)
- [ ] PWA manifest.json + service worker registered
- [ ] Firebase FCM initialized in service worker
- [ ] Adsterra site URL updated to skorio.in
- [ ] All banner GET CODEs integrated

---

## Revenue projection

| Period | Users | Networks | Est. monthly |
|--------|-------|---------|-------------|
| Now → June 2026 | 20–50 | Adsterra | ₹500–2,000 |
| World Cup (June–July) | 100–500 | Adsterra + traffic spike | ₹5,000–20,000 |
| Post WC Phase 2 | 500–2,000 | Adsterra + Media.net + entry fees | ₹10,000–40,000 |
| Phase 3 (2027) | 2,000–10,000 | Ezoic + Pro + card packs + affiliates | ₹30,000–1,00,000 |
| Scale | 10,000+ | Full stack | ₹1,00,000+ |

---

*Last updated: June 2026*  
*Domain: skorio.in*  
*Stack: Next.js 14 · TypeScript · Supabase · Tailwind CSS*  
*Phases: World Cup 2026 → Post WC → Tournament mode → Social → Cricket → Scale*
