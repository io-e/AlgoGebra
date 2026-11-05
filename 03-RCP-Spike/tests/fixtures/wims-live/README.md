# WIMS live-response fixtures (WA-9)

These seven HTML responses were derived from Grok Bot's evidence in draft PR #64
(source commit `da6d1a4`, 2026-11-05): successful and unsuccessful 00006 grading,
00076 checkbox grading, and the GB-W8 accented-answer run. They are parser/test
fixtures only; the test suite replays them to a loopback mock and never contacts
the WIMS server.

Before adding them here, ephemeral WIMS session IDs were replaced with stable
`FIXTURE...` values and the captured localhost origin was replaced with
`https://wims.example.invalid`. The rest of each file, including Windows-1252
response bytes and JSON comment payloads, is preserved. The fixtures are not a
license or a claim that the connected client has passed a live-server test.

Run `pwsh -NoProfile -ExecutionPolicy Bypass -File 03-RCP-Spike/host/test-wims-client.ps1`
to verify the request/response contract against these captures.
