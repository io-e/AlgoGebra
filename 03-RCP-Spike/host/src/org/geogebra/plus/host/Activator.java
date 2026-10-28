package org.geogebra.plus.host;

import org.osgi.framework.BundleActivator;
import org.osgi.framework.BundleContext;

/** Minimal activator for the RCP spike host bundle. */
public final class Activator implements BundleActivator {

    @Override
    public void start(BundleContext context) {
        System.out.println("[GeoGebraPlus] Host bundle ACTIVE; id="
                + context.getBundle().getBundleId());
    }

    @Override
    public void stop(BundleContext context) {
        System.out.println("[GeoGebraPlus] Host bundle stopping");
    }
}
