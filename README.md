# Class-12 Maths Study App

A **Rails 8** study companion for Class-12 Maths: browse the NCERT textbook and hand-written notes as PDFs, take **timed 10-question practice quizzes** whose difficulty adapts to your recent performance, and keep a **mistake book** of everything you got wrong until you've understood it.

```
  ┌──────────────────────────────────────────────────────────────┐
  │  Browser: Turbo + Stimulus + Tailwind (12 theme presets)     │
  │   Notes · Textbook · Quiz (locked + timer) · Mistakes · Themes│
  └───────────────┬──────────────────────────────────────────────┘
                  │  OmniAuth (Google / Microsoft / Facebook / demo)
  ┌───────────────▼──────────────────────────────────────────────┐
  │  Rails 8.1 · Puma · SQLite3 · importmap (no bundler JS)      │
  │  QuizSession (adaptive) · QuestionAttempt (grading) ·        │
  │  ContentLibrary (PDF catalog) · QuestionImport (CBSE SQP)    │
  └───────────────┬──────────────────────────────────────────────┘
                  │
     data/maths 12th/*.pdf + notes/*.pdf     db/data/questions.json (109 seeded)
```

---

## The Setup — three pillars

| # | Pillar | Why this one |
|---|--------|--------------|
| 1 | **SQLite + 5-table schema** (`users`, `questions`, `quiz_sessions`, `question_attempts`, `todos`) | One file per environment, zero ops on free-tier hosting; CHECK constraints keep difficulty/status/type enums honest at the DB level, not just in Ruby |
| 2 | **OmniAuth (no Devise) + demo bypass** | Google/Microsoft/Facebook sign-in with POST-only CSRF-protected callbacks; `POST /auth/demo` creates `demo@demo.local` so the app is usable with zero OAuth setup |
| 3 | **Turbo + Stimulus via importmap + Tailwind** | No esbuild/webpack/node pipeline; the quiz timer, session lock, theme switcher, and sticky notes are small isolated Stimulus controllers |

### Schema at a glance

| Table | Key columns |
|-------|-------------|
| `users` | `email` (unique), `provider`+`uid` (unique composite) |
| `questions` | `body`, `options` (**JSON** A–D), `answer` ("A".."D"), `difficulty` (easy/medium/hard), `topic`, `source` |
| `quiz_sessions` | `status` (in_progress/submitted), `time_limit_seconds`, `correct_count`, `difficulty_mix` (JSON), `total_questions` |
| `question_attempts` | one row per question per session; `answer`, `correct`, `resolved_at`; unique `[quiz_session_id, question_id]` |
| `todos` | per-user home checklist |

---

## The Story — how three people built it

The project split into **data & content**, **quiz engine**, and **interface & access**. Each person owned one section end-to-end: they designed their tables/files, picked the approach, wrote the code, and knew exactly which routes were theirs.

### Person 1 — Data & Content Engineer (the library)

**Ideation.** The raw material was messy: NCERT chapter PDFs split into parts, plus OCR'd CBSE Sample Paper questions full of broken glyphs (∀, ∫, ≤ came out as Private-Use-Area junk from `pdftotext`). Their idea: treat **content as a catalog, not as routes** — a `ContentLibrary` service parses filenames like `chapter7_part1.pdf` / `chp13.pdf` into a typed `Subject → Chapter` tree, so every PDF route is just three parameters (`kind`, `subject`, `number`, optional `part`). Questions got the same discipline: a real JSON schema with CHECK constraints so `super_hard` or `assertion_reason` can never sneak back in.

**What they designed & implemented:**

| Piece | Job |
|-------|-----|
| `db/schema.rb` + 10 migrations | The 5-table schema; the final `tighten_quiz_schema` migration normalized legacy statuses, folded difficulty values, and converted `options` text→JSON |
| `db/data/questions.json` (109 rows) | Shipped question bank: 73 medium / 20 easy / 16 hard, sources split between a hand-curated 50-question bank and CBSE SQP 2022–25 papers |
| `db/seeds.rb` | `Question.insert_all` on first boot (`db:prepare`) — empty DB becomes a working app |
| `ContentLibrary` (`app/services/content_library.rb`) | `Struct`-based catalog: `subjects`, `find_subject`, `find_chapter`, `max_chapter_number`; filename regex `/ch(?:apter|p)(\d+)(?:_part(\d+))?/i`; NCERT chapter titles 1–13 |
| `StudyContent` (`config/initializers/content.rb`) | `root` / `notes_root` from `STUDY_CONTENT_ROOT` / `STUDY_NOTES_ROOT` env overrides |
| `PdfsController#show` | `send_file … disposition: :inline` — the browser's native PDF renderer is the "viewer", no JS library needed |
| `lib/question_import.rb` | 183-line parser for a local `CBSE_paper_patterns` clone: strips "page N of M" noise, decodes the `PUA_MAP` glyph garbage, tags Q19+ as hard Assertion-Reason items |
| `lib/tasks/questions_json.rake` | `questions:import_json[path]` with `[subject, source, body]` dedup |

### Person 2 — Quiz Engine Engineer (the brain)

**Ideation.** The core loop: *practice is timed, adaptive, and sticky*. Always **10 questions**; the **difficulty mix** is chosen from your **last 5 submitted sessions** (<50% accuracy → easy mix, ≥80% → hard mix, else medium). Time budget is **earned per question** — 60 s easy, 90 s medium, 120 s hard, summed into `time_limit_seconds` (a medium session ≈ 18 minutes). Two clocks defend the deadline: a Stimulus client timer auto-submits at zero, and `SessionsController#show` **server-side submits** if you closed the tab. A **session lock** (`enforce_session_lock`) bounces every non-quiz request until you submit — no tab-hopping out of a live quiz. Blanks are *skipped*, not wrong; every miss lands in the **mistake book** with `resolved_at` until you retry it as a 1-question session or mark it understood.

**What they implemented:**

| Piece | Job |
|-------|-----|
| `QuizSession` (`app/models/quiz_session.rb`) | The brain: `build_session` (pick + time + create attempts in one transaction), `build_retry`, `submit!(answers)`, `expired?`, `time_remaining`, `mix_label` |
| `QuizSession.level_for(user)` | The adaptive engine over the last 5 submitted sessions |
| `QuizSession.mix_counts_for(level)` | easy `{4e,4m,2h}` · medium `{4m,6h}` · hard `{2m,8h}` — always sums to 10 |
| `QuestionAttempt#grade!` | Exact-match grading; blank → `correct: false` with `answer` nil = skipped |
| `QuestionAttempt` scopes | `missed`, `missed_by(user)` power the mistake book |
| `SessionsController` | `create` / `show` (server expiry) / `submit` / `result` / `retry_question` |
| `ApplicationController#enforce_session_lock` | Mid-quiz redirect wall: "Finish your practice session before moving on." |
| `MistakesController` | Topic filter chips, `resolve` (bulk `update_all`), `reopen`, miss counts |
| `QuestionsController#show` | Preview panel: level label, question count, minutes, mix, session history table |

### Person 3 — Interface & Access Engineer (the face)

**Ideation.** Two problems: *nobody wants to make an account to study*, and *a quiz you can alt-tab out of isn't timed*. Solution 1: OmniAuth with three real providers **plus a demo bypass**, and a visible-but-honest Apple button that explains it needs an Apple Developer account instead of silently failing. Solution 2: **lock the whole UI during a quiz** — a Stimulus `lock` controller disables sidebar links and intercepts Turbo navigation, while the server-side lock backstops it. Everything else is atmosphere: 12 theme presets in 4 collections with a `prefers-color-scheme` auto-sync, sticky notes, and a Turbo-replaced checklist.

**What they implemented:**

| Piece | Job |
|-------|-----|
| `AuthController` + `config/initializers/omniauth.rb` | Strategies registered only when both ENV keys exist; POST-only callbacks; `User.sign_in_with("demo")` / `User.from_omniauth` (email-link fallback) |
| `app/javascript/controllers/timer_controller.js` | Counts down from `time_remaining`; rose under 60 s; `formTarget.requestSubmit()` at zero |
| `lock_controller.js` | Disables nav, intercepts `turbo:before-visit`, warns on `beforeunload` |
| `theme_controller.js` + `ApplicationHelper#theme_collections` | 12 presets (Paper & Ink / Studio & Academy / Cyber & Terminal / Cinema & Atelier), `data-theme` on `<html>`, localStorage persistence, inline pre-paint script kills the flash |
| `choice_controller.js` | Click a selected radio again to unselect (radios can't natively) |
| `sticky_controller.js` | 3 sticky notes in localStorage (`study-stickies`) |
| `nav_controller.js` | Collapsible sidebar, persisted (`study-nav`) |
| `HomeController` + views | Hero counts, checklist (`todos`, Turbo stream replace), "Recommended for you" book grid from `config/books.yml` keyed to your last quiz's subject |
| Tailwind via `tailwindcss-rails` | Utility CSS, no node_modules |

---

## Files in this repository

| Path | What it is |
|------|------------|
| `app/models/` | `User`, `Question`, `QuizSession`, `QuestionAttempt`, `Todo` — the whole domain |
| `app/controllers/` | Auth, Home, Books, Notes, Questions, Sessions, Mistakes, Themes, Todos, Pdfs |
| `app/services/content_library.rb` | PDF catalog parser |
| `app/javascript/controllers/` | 8 Stimulus controllers (timer, lock, theme, sticky, choice, nav, + leftovers) |
| `lib/question_import.rb` | CBSE SQP markdown → questions (with PUA glyph decoder) |
| `db/data/questions.json` | 109 seeded questions |
| `data/maths 12th/` | Bundled NCERT textbook + notes PDFs |
| `test/` | 4 integration tests (session lock, result, confirmation, todos) + 4 model tests |

## How to run

1. `bin/setup`
2. `bin/rails db:prepare` (seeds the question bank on first run)
3. `bin/dev` — runs Puma + Tailwind watcher (or just `bin/rails server` if CSS is prebuilt)
4. Open `http://localhost:3000` → **Continue with a demo account** (no OAuth keys needed)
5. Read a chapter → start a timed practice → submit → check the mistake book

Tests: `bin/rails db:test:prepare test`

## Quiz rules

- Every session: **10 MCQs** (A–D), mix chosen by your recent accuracy.
- Time per question: **easy 60 s · medium 90 s · hard 120 s**; client auto-submits at zero, server submits abandoned sessions.
- You're **locked in** until you submit — sign-out is the only escape.
- Click a chosen option again to clear it; no solutions shown until you submit.
- Wrong and skipped questions flow to the **mistake book**; retry them as one-question sessions or mark them understood.
