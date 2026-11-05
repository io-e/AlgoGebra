package org.geogebra.plus.test.extension;

import java.util.Dictionary;
import java.util.Hashtable;

import org.osgi.framework.BundleActivator;
import org.osgi.framework.BundleContext;

/** Test-only bundle used by the opt-in D-06 lifecycle proof. */
public final class Activator implements BundleActivator {

    public static final String TOKEN_KEY = "ggbplus.d06.token";
    public static final String TOKEN = "d06-service-v1";

    @Override
    public void start(BundleContext context) {
        Dictionary<String, Object> properties = new Hashtable<>();
        properties.put(TOKEN_KEY, TOKEN);
        context.registerService(Runnable.class, () ->
                System.out.println("[TEST-EXT] D-06 Runnable service invoked"), properties);
        System.out.println("[TEST-EXT] D-06 extension started and service registered");
    }

    @Override
    public void stop(BundleContext context) {
        System.out.println("[TEST-EXT] D-06 extension stopped");
    }
}
