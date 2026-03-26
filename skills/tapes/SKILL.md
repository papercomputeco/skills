---
name: tapes
description: Use when the user says "check the tapes", "search tapes", "tapes search", or wants to look up past agent sessions. Starts tapes services if needed and queries the local SQLite store at ~/.tapes/.
---

# Tapes

Query local tapes session data. The tapes SQLite database lives at `~/.tapes/` and contains recorded LLM agent sessions across all projects.

## Trigger phrases

- "check the tapes"
- "search tapes for ..."
- "tapes search ..."
- "look up sessions about ..."
- "what did I work on ..."

## Ensure services are running

Before searching, the tapes API server must be running. Start it in the background if it isn't already:

```
# Check if already running
curl -sf http://localhost:8081/health > /dev/null 2>&1

# If not running, start it in the background pointing at the global sqlite db
tapes serve api --sqlite ~/.tapes/tapes.sqlite &
```

Use the Bash tool with `run_in_background` for the serve command so it doesn't block the conversation.

## Search

Run searches with the tapes CLI:

```
tapes search "<query>" --api-target http://localhost:8081 --top 5
```

- Adjust `--top` based on how broad or narrow the user's question is
- Use `--quiet` when piping results to other commands like `tapes skill generate`

## Workflow

1. Check if the API is already listening on port 8081
2. If not, start `tapes serve api --sqlite ~/.tapes/tapes.sqlite` in the background
3. Run the search command the user asked for
4. Present results concisely
