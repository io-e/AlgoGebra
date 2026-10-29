# WIMS external-engine source notice

The Pari/GP and Maxima engine bundles preserve and port configuration strings,
command-deny lists, and output-cleanup behavior from:

- `D:\ALF_ZGit\02-wims4win\src\Interfaces\pari.c`
- `D:\ALF_ZGit\02-wims4win\src\Interfaces\maxima.c`
- Shared filtering/output helpers in `D:\ALF_ZGit\02-wims4win\src\Interfaces\common.c`

The WIMS interface sources identify their copyright as Copyright (C) 1998-2003
XIAO, Gang of Universite de Nice - Sophia Antipolis, and state that they are
licensed under GNU GPL version 2 or (at the recipient's option) any later
version. The corresponding WIMS license text is preserved in `GPL-2.0.txt`.
See the source-file notices in `PariGPEngine.java` and `MaximaEngine.java`.

The Java process runner and public service API are new implementations. The
Gnuplot adapter is also new code and is not copied from a WIMS C interface.
Their final project licensing must be decided independently. Pari/GP and
Maxima are built as separate OSGi bundles to keep the WIMS-derived code boundary
visible. This is provenance documentation, not a legal compatibility opinion;
review the bundle composition and distribution obligations before publishing
or shipping the combined product.
