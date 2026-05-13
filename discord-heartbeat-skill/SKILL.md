---
name: discord-heartbeat
description: Set up, repair, or operate durable Codex heartbeat automations that post concise project-collaboration status summaries to a Discord channel through an incoming webhook. Use when the user asks for async AI coworker updates, recurring Discord workstream summaries, start/checkpoint/final progress reports, heartbeat notifications, webhook-based Codex progress reports, or a setup that survives context compaction by using absolute local scripts, a persistent webhook secret, rolling summaries, and send logs.
---

# Discord Heartbeat

## Goal

Create a durable Codex status reporter that summarizes project work into Discord without relying on the model remembering a webhook URL from chat history. Optimize for async Git collaboration: enough context to avoid duplicated work and merge drift, without raw prompts, code dumps, or private scratchpad noise.

## Durable Pattern

Use three local artifacts with absolute paths:

- Sender script: `<home>\.codex\discord-heartbeat\post-discord-summary.ps1`
- Rolling summary: `<home>\.codex\discord-heartbeat\rolling-summary.md`
- Send log: `<home>\.codex\discord-heartbeat\send-log.jsonl`
- Last-send state: `<home>\.codex\discord-heartbeat\last-send-state.json`

Store the webhook as a persistent secret:

```powershell
[Environment]::SetEnvironmentVariable('DISCORD_WEBHOOK_URL', '<webhook-url>', 'User')
```

Never put the webhook URL in the automation prompt or final answer. If the URL appears in chat, tell the user it should be treated like a password and rotated if exposure matters.

## Setup Workflow

1. Create `<home>\.codex\discord-heartbeat`.
2. Copy or create `scripts/post-discord-summary.ps1` into that folder.
3. Create `rolling-summary.md` with the current durable summary.
4. Set `DISCORD_WEBHOOK_URL` in the Windows user environment, and also in the current shell before live verification.
5. Run a dry-run test before any live post.
6. Send one live confirmation through the script.
7. Create or update a heartbeat automation with `FREQ=MINUTELY;INTERVAL=20` unless the user requests a different interval.

## Collaboration Update Policy

Post summary-only updates at these points:

- Start summary: when a task begins.
- Checkpoint summary: every 20 minutes while work is active, even if nothing has been pushed.
- Architecture summary: before choosing or changing an important design, API, schema, dependency, data model, ownership boundary, or merge strategy.
- Final pre-push/PR summary: before pushing a branch or opening/updating a PR.
- Blocker summary: when stuck, uncertain, or waiting on a human decision.

Default interval: 20 minutes. Use 30 or 60 minutes for low-intensity work. Avoid intervals shorter than 20 minutes unless the user explicitly values immediacy over token cost and Discord noise.

Each update must answer:

- Asked: what the human asked the AI to do, including the current branch or work area when known.
- Thinking: the AI's current approach, hypothesis, tradeoff, or decision being considered. Summarize reasoning; do not expose hidden chain-of-thought.
- Did: what was actually inspected, changed, tested, or decided since the last update.
- Next: the next concrete step.
- Risk: blockers, assumptions, merge risks, or files/modules likely to conflict.

Do not post raw prompts unless the user explicitly asks for raw prompts. Do not post code, secrets, tokens, long logs, private credentials, or every minor action.

## Token Budget Rules

- Summarize only what changed since the last update; do not recap the whole project each time.
- Keep Discord updates to five short bullets using `Asked`, `Thinking`, `Did`, `Next`, and `Risk`.
- Use `rolling-summary.md` as the durable memory. Read it first and keep it short.
- If there is no meaningful change since the rolling summary, do not send a Discord message.
- If unsure whether wording changes are only cosmetic, reuse the previous summary exactly and call the sender with `-SuppressDuplicate`; the script will skip duplicate posts by content hash.
- Do not include raw prompts, full code diffs, long logs, or exhaustive file lists.
- Prefer event-triggered updates over frequent timers: task start, architecture decision, blocker, and final pre-push/PR.

## Heartbeat Prompt Template

Use this prompt when creating or updating the automation, replacing `<home>` with the absolute Windows user profile path:

```text
Every time this heartbeat fires, post a durable project-collaboration summary of this current Codex thread to the configured Discord channel.

Use these absolute local paths:
- Sender script: <home>\.codex\discord-heartbeat\post-discord-summary.ps1
- Rolling summary: <home>\.codex\discord-heartbeat\rolling-summary.md
- Send log: <home>\.codex\discord-heartbeat\send-log.jsonl
- Last-send state: <home>\.codex\discord-heartbeat\last-send-state.json

Required workflow:
1. Read the rolling summary file if it exists.
2. Identify only meaningful changes since the rolling summary: new ask, changed approach, actual work done, next step, blocker, or risk.
3. If there is no meaningful change, do not post to Discord. Keep the thread reply quiet/brief.
4. If there is a meaningful change, summarize this current thread in 3-5 concise bullets using this schema: Asked, Thinking, Did, Next, Risk. Summarize reasoning; do not reveal hidden chain-of-thought.
5. Update the rolling summary file with the new durable summary. Keep it concise and current.
6. Call the sender script with duplicate suppression, for example: & '<home>\.codex\discord-heartbeat\post-discord-summary.ps1' -Content $summary -SuppressDuplicate
7. The sender script reads DISCORD_WEBHOOK_URL from the Windows user environment. Do not print, reveal, or hardcode the webhook URL.
8. If posting fails, reply in this thread with the exact error and mention the send log path. If posting succeeds or is suppressed as a duplicate, keep the thread reply brief.

Cadence:
- Default recurring interval: every 20 minutes while work is active.
- Also post manually at task start, before important architecture decisions, when blocked, and before push/PR.
- Keep updates summary-only; do not post raw prompts, code, secrets, tokens, or long logs.
- When no work has changed since the last update, skip Discord posting until the next meaningful change.
```

## Operating Rules

- Use `codex_app.automation_update` for creating, viewing, updating, or deleting heartbeat automations.
- Prefer updating an existing heartbeat over creating duplicates.
- Heartbeats are tied to a single Codex thread. They do not automatically follow the user into a new thread.
- If the user says "until I say stop", create an active heartbeat with no `COUNT`.
- Prefer a 20-minute interval for coworker project status. Shorter intervals consume more tokens and create noisy Discord logs.
- For event-triggered updates such as task start, architecture decisions, blockers, or final pre-push/PR status, call the sender script directly instead of waiting for the next heartbeat.
- Use `-SuppressDuplicate` on normal sender calls so identical summaries are not reposted.
- If the user asks to stop, delete the automation by id and say it has stopped.
- If Discord posting fails, check `send-log.jsonl`, verify the env var exists, and test the script in dry-run mode.

## Verification Commands

Dry-run:

```powershell
$env:DISCORD_WEBHOOK_URL = [Environment]::GetEnvironmentVariable('DISCORD_WEBHOOK_URL', 'User')
& '<home>\.codex\discord-heartbeat\post-discord-summary.ps1' -Content 'Dry run test.' -SuppressDuplicate -DryRun
```

Live post:

```powershell
$env:DISCORD_WEBHOOK_URL = [Environment]::GetEnvironmentVariable('DISCORD_WEBHOOK_URL', 'User')
& '<home>\.codex\discord-heartbeat\post-discord-summary.ps1' -Content 'Durable Discord heartbeat test.' -SuppressDuplicate
```

Log check:

```powershell
Get-Content -Path '<home>\.codex\discord-heartbeat\send-log.jsonl' -Tail 5
```
