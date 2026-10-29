package org.geogebra.plus.engine.gnuplot;

import java.util.Hashtable;

import org.geogebra.plus.compute.api.ExternalComputeService;
import org.osgi.framework.BundleActivator;
import org.osgi.framework.BundleContext;
import org.osgi.framework.ServiceRegistration;

/** Registers Gnuplot as an OSGi service without starting it during activation. */
public final class Activator implements BundleActivator {

    private ServiceRegistration<?> registration;

    @Override
    public void start(BundleContext context) {
        GnuplotEngine engine = new GnuplotEngine();
        Hashtable<String, Object> properties = new Hashtable<>();
        properties.put("engine.id", engine.getEngineId());
        properties.put("engine.available", engine.isAvailable());
        registration = context.registerService(ExternalComputeService.class.getName(), engine, properties);
        System.out.println("[GeoGebraPlus] Registered external engine gnuplot; available=" + engine.isAvailable());
    }

    @Override
    public void stop(BundleContext context) {
        if (registration != null) {
            registration.unregister();
            registration = null;
        }
    }
}
