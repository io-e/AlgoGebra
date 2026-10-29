# Evidence index

## Valid capture

- `rcp-20261028-235656-23884-34151d6a.png` — captured from the RCP shell after activating the target window. It shows the SWT host shell, both embedded GeoGebra views, algebra views, toolbars, input rows, and the rendered 3D point `A`.
- Corresponding run log: `../logs/rcp-20261028-235656-23884-34151d6a.log` (regenerable local output, intentionally ignored by Git).
- `rcp-20261029-000134-9160-c931fe29.png` — interactive input test. The entered `C=5` appears in the left Algebra View, but a “Please check your input” dialog also appeared after Enter; it is retained as diagnostic evidence, not as the clean product screenshot.
- Corresponding run log: `../logs/rcp-20261029-000134-9160-c931fe29.log` (regenerable local output, intentionally ignored by Git).

## Retained but invalid early captures

- `rcp-20261028-234616-37212-6a47ee6c.png`
- `rcp-20261028-234928-22368-f5f609ee.png`

These files were preserved, not deleted, but are excluded from version control and must not be cited as product evidence: the Robot capture ran while File Explorer was the foreground window, so both images show Explorer rather than GeoGebraPlus.

## Versioned test-pack runs (GROK_V1)

One folder per reviewed run: `<YYYYMMDD>-<os>-<who>-<commit or runid>/` with `MANIFEST_GROK_V1.tsv` (run metadata, path, bytes, sha256).
Never edit or delete a file here; add a new folder. Verify with `sha256sum` / `Get-FileHash` against the manifest.
Mutable run output goes to `tests/results/<runid>/` (git-ignored); export a reviewed run with
`pwsh -File tests/Run_All_GROK_V1.ps1 ... -ExportEvidence <name>`. Full logs of routine runs belong in CI artifacts or stay local by run ID.

| Folder | Run |
|---|---|
| `20261029-debian-grokbot-c5dc145` | Debian sh + pwsh runs, 01-13, D-04/D-05 screenshots (screenshots/) |
| `20261029-windows-codex-689d4b4` | Codex Windows suites 01-07, 75/0/3 |
| `20261029-windows-codex-r9-e3e8a82` | Codex Windows r9 image: 01-08 + 12 = 95/0/3, suite 13 |
| `20261029-linux-debian-grokbot-bug006-20261029_160937-grok-bot-vm-419969949` | Debian Run_All -SkipUi after the BUG-006 fix, 101/0/3 |

Files here are stored byte-exact (`.gitattributes`: `-text`), so the manifest hashes hold on Windows checkouts.
