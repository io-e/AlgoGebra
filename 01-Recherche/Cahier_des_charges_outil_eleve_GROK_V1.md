# GROK_V1

# Student tool specification

Status: draft, 2026-10-28.

Source: `synth_se_de_l_architecture_et_du_d_veloppement_sur_geogebra_GEM.md`, plus the target split below. This document specifies the student tool. It does not specify a full rewrite of upstream GeoGebra.

## 1. Target

Build a modular student workspace that can evolve without forking the GeoGebra monolith for every new feature.

Long-term split:

| Work | Tool |
|---|---|
| Algebra, calculus, text, proofs, tables, and anything that is not a figure | Jupyter notebook |
| Plane geometry and 3D | GeoGebraPlus, a wrapped GeoGebra applet |
| Authoring, assignment, grading, and the class | Wims |
| LLM assistance for the teacher | VS Code |

The student does not live in Wims or in VS Code. Those stay on the teacher side. The student opens an activity that Wims serves, works in the notebook and in GeoGebraPlus, and sends results back to Wims.

## 2. Users

**Student.** Opens one activity, writes non-graphical work in a notebook, builds or manipulates a figure in GeoGebraPlus, and submits both.

**Teacher.** Writes the activity in Wims, edits notebooks and prompts in VS Code, and uses an LLM there to draft statements, hints, and checks. The teacher does not need the GeoGebra Java build.

## 3. Modularity choice

Upstream GeoGebra has no plugin system. Custom tools, GeoGebra Script, the JavaScript API, or a source fork are the only extension points (Gemini, section 3).

For this project the primary architecture is Gemini's option 1: a web shell around the official web applet. Notebook cells and GeoGebraPlus talk to that applet through the public JavaScript API. A local WebSocket bridge (option 3) is allowed later so a notebook kernel can drive the same applet. A Java SPI or PF4J fork of Classic 5 (options 2 and the Gradle plugin notes) is out of the first delivery. The cloned tree in `D:\ALF_ZGit\G1_Geogebra_Migration` stays a reference build, not the product students run.

## 4. Student tool

### 4.1 One activity, two surfaces

An activity is one package:

- a notebook for statements, symbolic work, numeric work, and short answers
- zero or more GeoGebra figures (2D, 3D, or both)
- a Wims binding: activity id, what is collected, and what is scored

The student sees both surfaces in one page. Closing the figure must not drop the notebook, and the reverse must also hold.

### 4.2 Notebook (non-graphical)

The notebook is the only place for work that is not a construction:

- text and given data
- algebra and calculus
- tables and short numerical answers
- proof text, when a later proof checker is attached

The notebook must be able to:

- read named values out of the current figure (coordinates, lengths, booleans, lists)
- write named values into the figure when the activity allows it
- keep those links after a reload of the activity
- export a submission that Wims can store: notebook source plus the `.ggb` files

Cells that only display a static plot are still notebook cells. An interactive construction is GeoGebraPlus.

### 4.3 GeoGebraPlus (geometry and 3D)

GeoGebraPlus is the geometry module. It embeds the GeoGebra web applet and adds only what the applet does not provide for this project:

- a stable id for each figure in the activity
- load and save of a `.ggb` file
- a short command channel: get object, set value, eval a GeoGebra command, reset to the teacher's file
- a visible mode flag: explore, construct, or locked
- 2D and 3D as two applet configurations of the same module, not two products

GeoGebraPlus must not reimplement the kernel, the renderer, or the CAS. Those stay inside the applet.

### 4.4 What the student can do

- Open the activity from a Wims link, with the teacher's notebook and figures already loaded.
- Edit the notebook and the figure according to the mode the teacher set.
- See the figure update when a notebook cell pushes values, and see notebook inputs update when the teacher marked figure objects as inputs.
- Submit once. The package contains the notebook and every `.ggb`.
- Reopen a returned activity with the same files.

### 4.5 What the student tool must not do

- Author the class, the score formula, or the roster. That is Wims.
- Call an LLM by itself in the first version. Teacher-side VS Code holds the LLM.
- Require a local Java install or a Gradle build.

## 5. Teacher side, only the contract

Wims remains the teacher tool: activity text, access, deadline, and grade. VS Code remains the place where the teacher uses an LLM to prepare notebooks, hints, and checkers.

The student tool only needs this contract from Wims:

- launch URL with an activity id and a learner id
- download of the initial notebook and `.ggb` files
- upload of the submitted notebook and `.ggb` files
- a status the page can show: not started, draft, submitted, returned

No Wims screen is rebuilt inside GeoGebraPlus.

## 6. License

The public GeoGebra source is available for non-commercial educational use under the GeoGebra non-commercial terms, with GPL on the code and CC BY-NC-SA on many resources (Gemini, section 1). This student tool stays in that non-commercial educational scope. Embedding the official web applet through its JavaScript API is the path that avoids shipping a modified fork.

## 7. First delivery

1. A page with one notebook and one 2D GeoGebraPlus applet.
2. Load and save of one `.ggb` from that applet.
3. Two bindings: notebook reads one named number from the figure, notebook writes one named number into the figure.
4. A fake Wims endpoint that serves and stores the package, so the contract is testable before the real Wims link.
5. The same applet configuration switched to 3D, with the same command channel.

A proof assistant, a CAS outside GeoGebra, and the VS Code LLM flow are later activities. They attach to the notebook, not to a fork of the kernel.

## 8. Open points

- Which notebook UI: JupyterLab in an iframe, or a lighter notebook that still saves `.ipynb`.
- Whether the first applet is the official `deployggb.js` build or the `web3d` output already compiled from the local clone.
- Which objects are legal as notebook inputs (numbers only at first, or also points and lists).
