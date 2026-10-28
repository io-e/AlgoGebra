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
