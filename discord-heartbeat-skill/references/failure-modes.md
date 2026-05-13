# Discord Heartbeat Failure Modes

- Context compaction: keep webhook outside chat and use rolling-summary.md as backup context.
- Wrong destination: heartbeats reply to their target thread unless the prompt explicitly calls the Discord sender script.
- New thread: heartbeat automations are bound to one Codex thread; recreate the automation per new thread.
- Missing secret: set DISCORD_WEBHOOK_URL in the Windows user environment and copy it into the current shell before live verification.
- Rotated webhook: Discord POST fails; update DISCORD_WEBHOOK_URL and re-run dry-run plus live verification.
- Wrong path: use absolute Windows paths in the heartbeat prompt.
- Silent failure: inspect send-log.jsonl after each test or reported failure.
- Secret leakage: do not print the webhook URL; if exposed, tell the user to rotate it.
- Duplicate wording drift: if no meaningful work changed, reuse the previous summary exactly or skip sending; otherwise small wording changes can defeat hash-based duplicate suppression.
- False quiet period: the heartbeat only knows about work represented in its thread, rolling summary, or explicit status files. It cannot detect private work in another environment unless that environment writes or posts an update.
