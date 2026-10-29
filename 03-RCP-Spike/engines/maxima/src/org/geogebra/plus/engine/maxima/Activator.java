package org.geogebra.plus.engine.maxima;

import java.util.Hashtable;

import org.geogebra.plus.compute.api.ExternalComputeService;
import org.osgi.framework.BundleActivator;
import org.osgi.framework.BundleContext;
import org.osgi.framework.ServiceRegistration;

/** Registers Maxima as an OSGi service without starting it during bundle activation. */
public final class Activator implements BundleActivator {

    private ServiceRegistration<?> registration;

    @Override
    public void start(BundleContext context) {
        MaximaEngine engine = new MaximaEngine();
        Hashtable<String, Object> properties = new Hashtable<>();
        properties.put("engine.id", engine.getEngineId());
        properties.put("engine.available", engine.isAvailable());
        registration = context.registerService(ExternalComputeService.class.getName(), engine, properties);
        System.out.println("[GeoGebraPlus] Registered external engine maxima; available=" + engine.isAvailable());
    }

    @Override
    public void stop(BundleContext context) {
        if (registration != null) {
            registration.unregister();
            registration = null;
        }
    }
}
