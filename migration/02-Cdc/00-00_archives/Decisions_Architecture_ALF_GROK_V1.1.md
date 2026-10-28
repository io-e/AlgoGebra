# GROK_V1

Architecture decisions from Q&A_Architecture_ALF_v1.1

Status: draft, 2026-10-28.

Source: `02-Cdc\Q&A_Architecture_ALF_v1.1.md`.

Where two answers conflict, the later and more specific one wins. Conflicts are listed in section 4 so they are not silent.

## 1. Locked decisions

**Product.** A hybrid system.

- Desktop: an Eclipse RCP application on Equinox. Offline use and teacher authoring run here. This is a shipped runtime, not only "open the Gradle tree in the Eclipse IDE". Eclipse IDE 2026-09 (platform 4.41.0) is already installed at `D:\ALF_ZGit\G2_Eclipse\01_src\eclipse`. The Q&A text that mentions the 2024 branch and Java 21 is out of date relative to that install.
- Web: a browser client for students. It is a custom JavaScript wrapper around GeoGebra, not a GWT port of the plugins. The wrapper must fix the limits named in the Q&A: Promises instead of `appletOnLoad`, more than one applet per page, TypeScript types, a structured state instead of only `evalCommand` strings, reactive update listeners, predictable layout, and safe batch edits.

**Kernel.** `common` is embedded and not forked. No package split inside upstream `common`. No long-term delta against the GeoGebra tree. OSGi sees `common` through a bundle wrapper or a fragment. New behavior is added beside it.

**Features that must keep working.** Every current GeoGebra surface stays: Algebra View, CAS, spreadsheet, 2D, and 3D. The notebook does not replace those views. Algo* objects stay in the calculation model. Views and RCP extensions hook that model. They do not copy it.

**Who extends what.**

| Actor | May do |
|---|---|
| Developers and administrators | Build and install OSGi bundles. A rebuild or a restart is enough. No hot unload. |
| Teachers | Select and configure prebuilt features in an activity (tools, evaluation schema). They do not compile or install plugins. |
| Students | Use the web client or the desktop client. They do not install extensions. |

**What an extension may add.**

1. A submission backend, first target Wims, with a JSON evaluation schema (the note names `alphavalon-eval-v1`). It reads geometric state through listeners and grades without editing `common`.
2. A domain bundle (physics, discrete math, or another Algo*) registered beside the kernel, not by editing upstream Algo classes.
3. UI adapters for the 2D and 3D views so a web page can drive them. Those adapters are the JavaScript wrapper, not a second kernel.

**Deployment.** Wims stays outside GeoGebra. OEF content becomes XML/JSON (the note names XWims). The embedded core is the geometry client of that backend.

**Explicitly rejected.**

- A long-lived fork of `common`, including an OSGi "package cut" that moves classes.
- Dropping Algebra View or CAS in favor of the notebook.
- Hot-swap of bundles that hold constructions.
- GWT as the web runtime.

## 2. What this changes in the earlier specification

`Cdc_Evolution_GeoGebra_GROK_V1.md` said algebra and CAS leave GeoGebra and live only in the notebook, and that a Java fork is the fallback. Those two points are withdrawn.

Still valid: GeoGebraPlus is the geometry and 3D surface, Jupyter is an added surface for non-graphical work, Wims is the class tool, VS Code is where the teacher uses an LLM.

## 3. First build that matches these answers

1. OSGi wrapper bundle that contains unmodified `common` and starts under the installed Eclipse 2026-09, with Algebra, CAS, spreadsheet, 2D, and 3D still opening.
2. One fragment or sibling bundle that registers a Wims submission backend without a source change in `common`.
3. A small web page with two applets, a Promise-based loader, and a typed read of the construction state.

Step 1 is the blocker named in the Q&A. Step 2 is use case 1. Step 3 is the web requirement that the JavaScript API does not meet today.

## 4. Conflicts left in the Q&A

These are not decided by section 1. They need a direct answer before implementation.

1. Question 4 says "Eclipse IDE". The Codex block says "ship an RCP application". Section 1 follows the Codex block. Confirm that the IDE install is only the workbench.
2. Question 2 says web modules are "only in java", and question 5 drops GWT. Java plugins then cannot run in the browser. Section 1 reads the web half as the JavaScript wrapper, with OSGi plugins only on the desktop. Confirm that a desktop-only plugin has no web twin unless someone writes a second JS adapter.
3. Question 1 says teachers who never compile also extend GeoGebra. The Codex block says teachers only select prebuilt features. Section 1 follows the Codex block.
4. Question 10 asks for a package cut of `common`. Question 6 and Codex question 8 forbid changes inside `common`. Section 1 follows the ban. The next design is a wrapper, not a split of upstream packages.

# Codex

A few points still need clarification:

1. Does “web extensions only in Java” mean the web app must remain GWT-compiled Java, or may web add-ons use JavaScript/TypeScript?
2. Must a custom physics or discrete-math algorithm be a native GeoGebra AlgoElement, or could it compute separately and exchange results through supported APIs?
3. Must desktop and web have full feature parity, or may their extension capabilities differ?
4. Which GeoGebra version defines “all native features,” and what should count as acceptance?
5. Can extension hooks live in the separate GeoGebraPlus host, or must they be inside GeoGebra’s common kernel?
6. Should each distributed product be preassembled with its selected extensions, or must it discover and load extensions at startup?
