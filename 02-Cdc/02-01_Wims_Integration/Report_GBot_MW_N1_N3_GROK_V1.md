<!-- GROK_V1 -->
# Report — MW-N1 Windows sibling runtime + MW-N3 Debian HTTP smoke

| Field | Value |
|---|---|
| Date | 2026-11-06 |
| wims4win branch | `feat/algogebra-json-hook` @ `faa983e` (build provenance) |
| Windows sibling | `D:\ALF_ZGit\43-wims-paris-saclay_fr\Reprise_Wims_Grok\wims-runtime-r19040-grok-hook-20261106` |
| Live runtime (unchanged) | `...\wims-runtime-r19040-grok` |
| Debian HTTP | `http://127.0.0.1:18441/wims/wims.cgi` (private front, not :18431) |
| Archive SHA-256 | `45ee6cd8f8f2cf4fcd12ba54e0722e46bebb4f1e2ddcde0777f5db066dfe0090` (143 MiB) |

## MW-N1

`tools/build-runtime-tree.sh /workspace/svn-r19040.tgz` produced `wims-runtime.tgz` (WIMS 4.33a, r19040, hook installed in Linux `$WD/wims` and Windows `$OUT`). Staged as a **new sibling**; `wims-runtime-r19040-grok` was not overwritten (its `answer.phtml` still has no hook; `log/wims.conf` mtime 2026-11-04; Laragon `WIMS_RT` unchanged).

Copied into the sibling only: `log/wims.conf`, `public_html/bin/ch..root.conf`, `modules/local/oef2html_web.fr` (+ `eleda_test.fr`, `exemple.fr`). Added smoke module `H6/test/oef2html.fr` (00006+00076, seed 1). Sibling-only `threshold1/2` raise.

CGI smoke via `wims.cgi.exe` (Apache-like env): **8/8 PASS**. Sandbox: `ch..root.exe --selftest` exit 0; PARI through `ch..root` printed `4`. Evidence: `windows-sibling/results.txt` and on the PC under the sibling `smoke-evidence/`.

## MW-N3

Private Python CGI front on **127.0.0.1:18441** in front of the packaged Linux tree (`rt-linux-packaged`). Did not bind or change port 18431. HTTP smoke **8/8 PASS** (00006/00076 × wrong/right with hook; no `ALGOGEBRA_JSON_BEGIN` without it). Pages `charset=windows-1252`, JSON block ASCII. Raw HTML + JSON in `http/`.

## Laragon swap line (not applied)

In `C:\laragon\etc\apache2\sites-enabled\auto.wims_paris_saclay_fr.test.conf` line 15, replace:

```
Define WIMS_RT "D:/ALF_ZGit/43-wims-paris-saclay_fr/Reprise_Wims_Grok/wims-runtime-r19040-grok/public_html"
```

with:

```
Define WIMS_RT "D:/ALF_ZGit/43-wims-paris-saclay_fr/Reprise_Wims_Grok/wims-runtime-r19040-grok-hook-20261106/public_html"
```

Then reload Apache. No other Laragon change is required if ScriptAliasMatch already uses `${WIMS_RT}`.
