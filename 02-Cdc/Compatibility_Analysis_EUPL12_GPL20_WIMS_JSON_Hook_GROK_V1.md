<!-- GROK_V1 -->
# License Compatibility Analysis — EUPL 1.2, GPL-2.0 and the WIMS JSON Hook

| Field | Value |
|---|---|
| Version | GROK_V1 |
| Date | 2026-11-05 |
| Status | **Preliminary legal-risk analysis; counsel/rights-holder review required** — implementation status refreshed |
| Scope | WI-R7: WIMS-side `special_parm=algogebra_json` output hook (WA-8/L2-1) |
| Related | `Cdc_WIMS_Integration_AlgoGebra_GROK_V2_2.md`; wims4win `AlgoGebra_Wims_Integration/`; `WIMS-INTERFACES.md` |
| Prior | `Compatibility_Analysis_EUPL12_GPL20_WIMS_JSON_Hook_CODEX_V1.md` (archive) |

## Executive conclusion

The planned WIMS JSON hook does **not, by itself, create an automatic EUPL/GPL conflict** if it remains a WIMS-side modification, communicates with GeoGebraPlus through the specified HTTP/HTML/JSON protocol, and is distributed as a separately licensed WIMS component. The GeoGebraPlus client does not copy the hook's source; it sends a request and parses a response.

EUPL 1.2 expressly lists **GPL version 2** as a compatible license. Its Article 5 provides a route for distributing a derivative work based on both EUPL and compatible-licensed code under that compatible license when the clause applies. This is not a blanket permission to relicense unrelated code, and it does not remove the need to identify copyright ownership, distribution boundaries, and the GeoGebra package's separate non-commercial statement. Therefore this is **not distribution clearance**.

## What was inspected

1. WIMS repository: `D:\ALF_ZGit\02-wims4win`, branch `feat/algogebra-wims-integration`; root `LICENSE` contains GPL version 2 text.
2. WIMS interface sources `src/Interfaces/pari.c` and `maxima.c` identify their material as GPL v2 or (at the recipient's option) any later version.
3. JSON-hook artifacts are now **committed** on wims4win branch `feat/algogebra-wims-integration` (`bb929e3`): `AlgoGebra_Wims_Integration/runtime_patch/algogebra_json.phtml`, injection snippet for `answer.phtml`, installer script, and smoke test. This is a **prototype**, not a public release; Gate E / O-02 distribution clearance remains open.
4. GeoGebra's pinned source `GeoGebraConstants.java` states that source files are licensed under EUPL 1.2 and separately states that the overall GeoGebra software package is for non-commercial use only.
5. The existing Pari/Maxima Java engine ports are a distinct issue: their source files contain WIMS-derived GPL notices and they are bundled into the RCP product. This document's conclusion about a separate WIMS-side hook **does not clear those engine bundles**.

## License analysis

### EUPL 1.2 compatibility clause

The official EUPL text's Article 5 says that where a licensee distributes a derivative work based on both an EUPL work and another work under a license listed in the EUPL Appendix, distribution may use that compatible license; if obligations conflict, the compatible-license obligations prevail. GPL v2 is named in the Appendix. The European Commission's EUPL guidance explains that the original EUPL code remains EUPL-licensed, that compatibility applies to the combined derivative work when needed, and that mere linking does not merge functional code.

That supports a possible compatibility route if GeoGebra EUPL code and GPLv2 code are actually combined into one derivative work. It does **not** mean every file in either repository automatically changes license, nor may the clause be used simply to relicense the original EUPL work.

### Hook deployment boundary

The proposed hook runs inside WIMS's OEF processing path and reads WIMS/OEF grading state. GeoGebraPlus is a separate client that submits answers and consumes the returned JSON block. The current design has no shared source file or embedded client code. On these facts, the safer working model is:

- WIMS server and modifications to its OEF scripts/templates: distribute under the license applicable to those WIMS files (conservatively GPLv2 for the current fork, pending file-level confirmation), with source, notices and license text kept available;
- GeoGebraPlus client: keep its own source/license notices and the selected rights-holder-approved GeoGebra terms;
- the JSON contract: document and version as an interface, not as copied implementation code;
- a combined download, if any: treat it as a collection of separately licensed components only if they remain independent works; do not impose one top-level term that restricts recipients' GPL rights.

An HTTP boundary is a strong architectural separation, but the legal characterization of a particular implementation/distribution is fact- and jurisdiction-dependent. If the hook copies or modifies existing WIMS templates, retain the relevant upstream notices and verify the exact license on those target files. If it includes copied GeoGebra code or becomes a combined/derivative codebase, reopen the Article 5 analysis with counsel.

### Non-commercial term — unresolved high-risk question

The non-commercial sentence in `GeoGebraConstants.java` is **not an EUPL 1.2 term**. EUPL Article 5 prohibits adding terms that alter or restrict EUPL rights, while the source itself expressly carries the separate GeoGebra package statement. The project must ask GeoGebra's rights holder/legal reviewer to identify which components and acts the statement covers and whether it permits the planned public multi-license distribution.

Do not apply a package-wide “non-commercial only” label to the WIMS/GPL component without legal authorization: that could add restrictions inconsistent with the rights offered under GPLv2. Equally, do not assume the EUPL notice nullifies the GeoGebra package statement; this analysis cannot resolve that question.

## WIMS hook obligations and implementation controls

Before merging or distributing WA-8/L2-1:

1. Identify the exact WIMS source revision and license notice of `answer.phtml` and any OEF helper files being modified; record the upstream file hashes and patch.
2. Add a file-level provenance/license header to the new hook, preserve upstream copyright notices, and include the complete applicable GPL license text in the WIMS distribution.
3. Make the modified WIMS source (including the hook and patch) available to recipients under the applicable GPL terms when distributing binaries or images.
4. Keep the hook in the WIMS repository/runtime layer; do not copy its implementation into GeoGebraPlus. Keep the JSON schema and protocol docs independently authored.
5. Confirm that the response is additive and that it does not leak hidden answer data beyond the intended grading contract; this is a security/privacy review, separate from licensing.
6. Keep the WIMS hook out of the GeoGebraPlus desktop installer unless there is an explicit packaging decision and legal review of the aggregate/component notices.

## Decision table

| Question | Current assessment | Required next step |
|---|---|---|
| Does EUPL 1.2 list GPL-2.0 as compatible? | **Yes**, explicitly in the Appendix. | Preserve official license references and counsel review for actual combined-work facts. |
| Does the WIMS JSON protocol alone combine the codebases? | **No indication from the inspected design**; it is an HTTP/HTML/JSON boundary. | Keep implementation separate; review again if code is copied/shared or bundled as one work. |
| Is the hook implemented/released? | **Prototype implemented** on wims4win Windows (`bb929e3`); **not** publicly released / Gate E uncleared. | Record file provenance hashes; keep GPL notices; do not ship in GeoGebraPlus installer until O-02. |
| Is the overall GeoGebraPlus distribution cleared? | **No.** The GeoGebra non-commercial statement and full image SBOM remain unresolved. | Rights-holder/legal decision; close O-02/Gate E. |
| Are WIMS-derived Pari/Maxima bundles cleared by this conclusion? | **No.** Separate issue; those GPL-derived Java files are within the RCP product. | Review bundle/module scope, notices/source obligations, and interaction with GeoGebra terms separately. |

## References

- European Commission, [EUPL 1.2 official text](https://interoperable-europe.ec.europa.eu/licence/european-union-public-licence-version-12-eupl), especially Articles 3 and 5 and the Appendix.
- European Commission, [How to use the EUPL — compatibility issues](https://interoperable-europe.ec.europa.eu/collection/eupl/how-use-eupl), especially the sections on combined works, linking, and the compatibility clause.
- Free Software Foundation, [GNU GPL version 2 text](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html).
- Local primary evidence: `D:\ALF_ZGit\02-wims4win\LICENSE`, `src/Interfaces/pari.c`, `src/Interfaces/maxima.c`, `AlgoGebra_Wims_Integration/runtime_patch/`.
- Local GeoGebra evidence: pinned source `source/shared/common/src/main/java/org/geogebra/common/GeoGebraConstants.java`.
- Engine provenance distinction: `03-RCP-Spike/engines/licenses/WIMS-INTERFACES.md`.

## Legal caveat

This is an engineering provenance and license-risk assessment, not legal advice, not an opinion on copyright derivation, and not approval to distribute. Distribution requires review by the relevant rights holders/legal counsel, especially because the GeoGebra source notice states an overall non-commercial package condition and the actual product image contains components beyond the 50-bundle resolver baseline.

