package org.geogebra.plus.compute.api;

import java.util.Set;

/** OSGi service contract for one-shot external mathematical computation. */
public interface ExternalComputeService {

    String getEngineId();

    Set<ComputeCapability> getCapabilities();

    /** False when the configured executable is not installed on PATH. */
    boolean isAvailable();

    ComputeResult eval(String command, ComputeContext context) throws ExternalComputeException;
}
