# BUG-014 Initial Investigation — Course Tree Sprint 1

| Field | Value |
|---|---|
| Status | **IN PROGRESS — root cause not confirmed; no fix proposed yet** |
| Date | 2026-11-01 |
| Owner | Codex |
| Scope | Sprint 1 task X-05; host and OSGi investigation only |
| Constraint | Do not edit source/shared/common; any fix must remain in the host or packaging |

## Observed evidence

The Debian P-02 run on 2026-10-29 used GeoGebra source pin 375db7faf5407390bb322165f2414415da8faeda, image GeoGebraPlus-RCP-0.1.0-linux-gtk-x86_64, and fixture SHA-256 356ee086ebb02d263e976f5788ffebc812f8e551a2462b34a42494794a9e043b. The evidence is preserved under 03-RCP-Spike/evidence/20261029-linux-scenarios-20261029_171259-grok-bot-vm-419969949/.

| Directive | RCP evalCommand | Follow-up readback in RCP | Pinned desktop |
|---|---:|---|---:|
| f(x) = x^2 - 2x | false | f(x) = x² - 2x | true |
| m = {{1, 2}, {3, 4}} | false | Determinant(m) succeeds; d = -2 | true |
| pl = Plane(A, B, (1, 0, 0)) | false | pl: 6x - 3y + 2z = 6 | true |

The raw product log records two “Please check your input” dialogs and one CAS.GeneralErrorMessage dialog. Their asynchronous log placement does not yet map each dialog to a specific directive.

## Source-path findings

1. In the pinned GgbAPI, evalCommand(String) returns whether evalCommandGetLabels(String) returned a non-null string. The boolean is therefore a result-label signal, not an independent proof that no construction change occurred.
2. evalCommandGetLabels calls AlgebraProcessor.processAlgebraCommand, collects labels from its returned elements, and returns null when it collected none.
3. AlgebraProcessor.processAlgebraCommand catches exceptions, calls the app error handler, and returns null. A failure after partial construction therefore remains possible.
4. The scenario hook invokes the public GgbAPI.evalCommand reflectively on the Swing EDT using SwingUtilities.invokeAndWait; an obvious asynchronous result-read race in that hook is not indicated by the source.

## Initial assessment

The follow-up values show that construction objects exist after the three false results. This weakens the simple hypothesis that the relevant parser or command processor is entirely invisible in OSGi. It does not rule out an OSGi resource/classloader problem later in processing, an error after partial creation, or a result-label/API contract difference. The root cause remains unconfirmed.

## Next controlled experiment

Add opt-in diagnostics in the host test hook only (never in common) to record, for each failing command:

- the exact evalCommandGetLabels return value;
- returned element count and labels where available;
- the API, kernel, and algebra-processor classloaders;
- the captured error-handler message/exception, if exposed through a host-side wrapper;
- object names and values before and after the command.

Run one failing directive per fresh 2D/3D app in both the RCP product and pinned plain-classpath baseline, on the same OS and Java. Preserve the full logs and fixture hash. Only then decide whether to trace localization/resources, result post-processing, or the RCP adapter. No common edit is authorized.
