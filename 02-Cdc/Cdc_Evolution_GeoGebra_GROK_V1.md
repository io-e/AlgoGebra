# GROK_V1

# Specification: evolution of GeoGebra

Status: draft, 2026-10-28.

Folder: `D:\ALF_Agents\G1_Geogebra_Migration\02-Cdc`.

This document says how GeoGebra changes inside the student workspace. The student-tool contract is `01-Recherche\Cahier_des_charges_outil_eleve_GROK_V1.md`. The name list for the other subjects is `Noms.md`. Gemini's brief is `01-Recherche\synth_se_de_l_architecture_et_du_d_veloppement_sur_geogebra_GEM.md`.

## 1. Decision

GeoGebra stays the geometry and 3D engine. It does not become the whole student environment.

| Concern | Where it goes |
|---|---|
| Plane figures and 3D scenes | GeoGebraPlus, a wrapper around the GeoGebra web applet |
| Algebra, calculus, text, tables, probability, data, and the other Algo* subjects | Jupyter notebook |
| Class, assignment, deadline, grade | Wims |
| LLM help while the teacher prepares an activity | VS Code |

GeoGebraPlus is the only evolution of the GeoGebra product in this project. The other names in `Noms.md` (AlgoGebra, AlgoProba, AlgoPhy, and the rest) are notebook subjects. They do not each get a fork of GeoGebra.

## 2. What does not change

The kernel, the renderer, the CAS inside the applet, and the `.ggb` file stay upstream GeoGebra.

Reasons, from the Gemini brief:

- The public code is a Java/GWT monolith with no plugin loader.
- Extension today means macros, GeoGebra Script, the JavaScript API, or a fork.
- A Java SPI, PF4J, or OSGi split of Classic 5 is a second product. It is not required to ship the student tool.

The clone at `D:\ALF_ZGit\G1_Geogebra_Migration` is the reference build (Classic 5 desktop and the GWT web apps). Students do not install it. Teachers do not build it.

License boundary: non-commercial educational use, as stated by GeoGebra's own terms (GPL on the code, CC BY-NC-SA on many resources). GeoGebraPlus embeds the applet. It does not ship a modified kernel.

## 3. What GeoGebraPlus adds

GeoGebraPlus is a thin module with one applet and a fixed command channel.

The applet provides the figure. GeoGebraPlus provides:

1. A figure id, stable for the life of the activity.
2. Load and save of one `.ggb` per figure.
3. Commands the notebook can call: get object, set value, eval one GeoGebra command, reset to the teacher file.
4. A mode the teacher sets: explore, construct, or locked.
5. Two configurations of the same module: 2D and 3D. Same commands, different applet setup.

GeoGebraPlus does not add a second algebra view, a notebook, a grader, or an LLM.

## 4. What leaves GeoGebra

These stay out of the applet on purpose:

- Statements, proofs, and short answers: notebook cells.
- Symbolic or numeric work that is not a construction: notebook.
- Score and roster: Wims.
- Prompt writing: VS Code.

A static plot in a notebook cell is not a GeoGebraPlus figure. An interactive construction is.

## 5. How the pieces talk

```
Wims  --launch / collect-->  student page
student page  --notebook-->  Jupyter
student page  --figure-->    GeoGebraPlus  --JS API-->  GeoGebra web applet
VS Code (teacher, LLM)  --prepares-->  notebook + initial .ggb  --stored in-->  Wims
```

The first protocol is the official JavaScript API (`deployggb.js`). A later WebSocket bridge may let the notebook kernel call the same four commands. That bridge is optional. The command set does not change when the transport changes.

Allowed values on the channel in the first version: numbers, booleans, and names of existing objects. Points and lists wait until those four commands are stable.

## 6. Evolution steps

| Step | Result | Out of this step |
|---|---|---|
| 0. Reference | Local clone builds desktop and web. Already done. | No student feature. |
| 1. Embed | One page, one 2D applet, load and save one `.ggb`. | No notebook binding. |
| 2. Channel | Notebook reads one named number and writes one named number. | No points, no lists. |
| 3. Package | Submit notebook plus `.ggb` to a fake Wims store. | No real Wims screens. |
| 4. 3D | Same channel on a 3D applet configuration. | No new commands. |
| 5. Modes | explore / construct / locked enforced by the wrapper. | No new kernel features. |

A fork of the Java sources starts only if a required behavior cannot be done with the JavaScript API. That decision is a separate specification. It is not step 1.

## 7. Acceptance for GeoGebraPlus

- The student reloads the page and finds the same `.ggb` and the same linked numbers.
- Reset restores the teacher's file and clears notebook-written values that the activity marked as derived.
- Locked mode ignores construction tools and still allows the notebook to read exported values.
- 2D and 3D figures in one activity use two figure ids and do not overwrite each other.
- The page works without a local JDK.

## 8. Non-goals

- Replacing Classic 5 or Classic 6 as a general desktop application.
- Rebuilding the CAS, the 3D renderer, or the theorem prover inside the wrapper.
- One GeoGebra fork per name in `Noms.md`.
- Putting the teacher LLM inside the student page.
