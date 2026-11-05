package org.geogebra.plus.host;

import org.osgi.framework.Bundle;

/**
 * Shared D-02 / D-03 / D-06 catalog of GeoGebra + wrapped-external OSGi bundles.
 * <!-- GROK_V1: extracted so ExtensionBundleManager and GeoGebraPlusApplication
 * stay lockstep on BSN patterns, expected count, and state names (PR #63 review). -->
 */
final class CoreBundleCatalog {

    /** Expected count of GeoGebra migration + wrapped external bundles in the product image. */
    static final int EXPECTED_CORE_BUNDLES = 50;

    private CoreBundleCatalog() {
    }

    /**
     * True for the D-03 product set: {@code org.geogebra.migration.*} plus the
     * four wrapped externals that ship in the installed image.
     */
    static boolean isExpectedGeoGebraOrExternal(String symbolicName) {
        if (symbolicName == null) {
            return false;
        }
        return symbolicName.startsWith("org.geogebra.migration.")
                || symbolicName.equals("com.sun.jna")
                || symbolicName.equals("org.jspecify.jspecify")
                || symbolicName.equals("org.jsr-305")
                || symbolicName.equals("spotbugs-annotations");
    }

    static String stateName(int state) {
        switch (state) {
        case Bundle.UNINSTALLED:
            return "UNINSTALLED";
        case Bundle.INSTALLED:
            return "INSTALLED";
        case Bundle.RESOLVED:
            return "RESOLVED";
        case Bundle.STARTING:
            return "STARTING";
        case Bundle.STOPPING:
            return "STOPPING";
        case Bundle.ACTIVE:
            return "ACTIVE";
        default:
            return "UNKNOWN(" + state + ")";
        }
    }
}
