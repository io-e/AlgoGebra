# GROK_V1

# Architecture decisions, closed

Status: closed for the four conflicts, 2026-10-28.

Sources: `Decisions_Architecture_ALF_GROK_V1.md` and `Decisions_Architecture_ALF_GROK_V1.2.md`.

## 1. Conflicts closed

1. Eclipse IDE 2026-09 at `D:\ALF_ZGit\G2_Eclipse\01_src\eclipse` is the workbench only. The shipped desktop product is a standalone RCP application on Equinox.
2. A desktop OSGi plugin does not run in the browser by itself. A web twin exists only when one is written. Which web mechanism to use is still a study, not a decision (section 3).
3. Teachers select and configure prebuilt features and evaluation schemas. They do not write, compile, or install plugins.
4. Upstream `common` is not modified and not split. OSGi sees it through a bundle wrapper around the intact module.

## 2. Rules added by the V1.2 answers

- End users see the same features on desktop and web. The loading mechanism may differ (OSGi on the desktop, a web module on the browser).
- "All native features" means Algebra View, CAS, spreadsheet, 2D, and 3D, with the same tools and views as the official stable GeoGebra release this tree tracks. Acceptance is no regression against that release.
- Extension hooks live in the GeoGebraPlus host, outside `common`. That host talks to Wims and, later, Lean 4.
- A custom algorithm (physics, discrete math) is an external module. It exchanges results through the host API. It is not a new `AlgoElement` inside upstream `common`.
- The desktop product discovers extensions at startup through the OSGi service registry. It is not a single preassembled monolith. Unload-without-restart remains out of scope.

## 3. Still open

One study remains, with two paths and no winner yet:

- Java-to-web compilation that is not GWT, so a Java extension can be shipped to the browser.
- Native JavaScript or TypeScript add-ons on the web wrapper.

Until that study picks one path, web work is limited to the wrapper around the existing applet, and new domain modules are desktop OSGi services only.

## 4. First build

1. Wrapper bundle for unmodified `common`, launched from the RCP product, with Algebra, CAS, spreadsheet, 2D, and 3D opening.
2. A GeoGebraPlus host bundle that discovers one extra service at startup: the Wims submission backend.
3. The web parity study in section 3, before any second implementation of that backend.
