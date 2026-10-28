

Here are the formal explanations to resolve Grok's inconsistencies (Section 4), followed by the expanded English answers for Codex based on your notes.

### Part 1: Resolutions for Grok (Resolving Section 4 Conflicts)

You can feed this directly to Grok to stabilize the architectural draft:

**1. Re: IDE vs. RCP Application**
I confirm that the Eclipse IDE 2026-09 installation is strictly our development workbench. The final shipped product for end-users will be a standalone Eclipse RCP (Rich Client Platform) application running on Equinox.

**2. Re: Web modules in Java vs. JavaScript wrapper**
Since we are dropping GWT, a Java OSGi plugin written for the desktop will not automatically run in the browser. A desktop plugin will not have a web twin by default unless it is explicitly developed for the web. However, to achieve parity, we will conduct a dual architectural study to determine the best approach for web extensions (either alternative Java-to-Web compilation or native JS/TS add-ons).

**3. Re: Teachers extending vs. selecting**
I confirm the Codex block interpretation: teachers are end-users regarding architecture. They will only select and configure prebuilt features and evaluation schemas within an activity. They will not author, compile, or install code-level extensions.

**4. Re: Package cut vs. No split of `common**`
I confirm the strict ban on modifying the upstream `common` source code. We completely abandon the idea of an OSGi "package cut" that moves or splits upstream classes. We will exclusively use an OSGi bundle wrapper around the intact `common` module to prevent split-package errors and upstream merge conflicts.

---

### Part 2: Answers for Codex

Here are the expanded English responses based on your short notes, ready to be sent to Codex:

**1. Does “web extensions only in Java” mean the web app must remain GWT-compiled Java, or may web add-ons use JavaScript/TypeScript?**
We will conduct a dual study for this requirement. We want to evaluate both paths: maintaining a Java-to-Web compilation pipeline (exploring modern alternatives to GWT if necessary) and allowing native JavaScript/TypeScript add-ons to plug into the modernized web wrapper.

**2. Must a custom physics or discrete-math algorithm be a native GeoGebra AlgoElement, or could it compute separately and exchange results through supported APIs?**
Yes, it is perfectly acceptable—and preferred for decoupling—that custom algorithms compute separately. They should act as external modules or OSGi services that exchange results through supported APIs rather than being forced into the upstream `AlgoElement` class hierarchy.

**3. Must desktop and web have full feature parity, or may their extension capabilities differ?**
Yes, the desktop and web versions must maintain full feature parity from the end-user's perspective, even if the underlying architectural mechanisms for loading extensions (OSGi bundles vs. Web modules) differ.

**4. Which GeoGebra version defines “all native features,” and what should count as acceptance?**
All current native features of GeoGebra (Algebra View, CAS, 3D, Spreadsheet, 2D) must be fully supported. Acceptance is defined by the system's ability to run all standard GeoGebra tools and views without any regressions compared to the official stable release.

**5. Can extension hooks live in the separate GeoGebraPlus host, or must they be inside GeoGebra’s common kernel?**
Hooks must live in the separate GeoGebraPlus host, not inside the `common` kernel. They must be safely decoupled to ensure security and stability for the user, allowing safe data extraction and communication with external systems like WIMS or Lean 4 without destabilizing the core math engine.

**6. Should each distributed product be preassembled with its selected extensions, or must it discover and load extensions at startup?**
The product must dynamically discover and load extensions at startup (e.g., via the OSGi service registry on the desktop), rather than being a rigidly preassembled monolith.

Equinox is the reference implementation of the OSGi standard and serves as the fundamental runtime engine for any Eclipse RCP application. It is the technical keystone that makes your architectural decisions regarding separate development and strict decoupling possible.

**Dynamic Discovery and Resolution at Startup**
To satisfy your requirement to "discover and load extensions at startup" rather than distributing a rigid monolith, Equinox manages a strict lifecycle. At launch, it scans the plugin directory, reads the manifests (`MANIFEST.MF`), and instantly resolves the dependency graph. If a component is missing or incompatible, Equinox isolates it without crashing the rest of the application.

**Isolation via ClassLoaders ("No-Fork" Guarantee)**
In a standard Java application with a flat classpath, wrapping GeoGebra's `common` without causing conflicts is risky. Equinox assigns a unique `ClassLoader` to each bundle. This perfectly isolates the intact GeoGebra kernel in its own memory space, ensuring your separately developed extensions will never pollute the upstream source tree and completely avoids the "split packages" anti-pattern.

**The Service Registry for External Algorithms**
You decided that custom algorithms (physics, discrete math) and external hooks (WIMS, Lean 4) must act as separate services rather than being forced into native `AlgoElement` classes. Equinox provides a robust Service Registry (OSGi Declarative Services). Your external domain modules publish their capabilities to this registry, and the GeoGebraPlus host safely consumes them through decoupled interfaces.

**The RCP Ecosystem**
Finally, because the locked decision is to ship a native desktop product (Eclipse RCP), Equinox is not optional. It is the mandatory foundation that supports Eclipse's UI toolkits (SWT/JFace) and the modern application model (Eclipse e4). Developing independent Eclipse extensions inherently means building Equinox bundles.
