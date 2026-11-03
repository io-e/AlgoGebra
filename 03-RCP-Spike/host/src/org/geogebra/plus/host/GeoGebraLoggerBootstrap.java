package org.geogebra.plus.host;

import org.geogebra.common.util.debug.Log;
import org.geogebra.desktop.util.LoggerD;

/** Initializes the desktop GeoGebra logger when the RCP host embeds GeoGebraPanel. */
final class GeoGebraLoggerBootstrap {

    private GeoGebraLoggerBootstrap() {
    }

    /**
     * Installs the same default logger setup used by GeoGebraFrame, but only
     * when no host or test adapter has already supplied a logger.
     *
     * @return true if this method installed the logger
     */
    static boolean initializeIfAbsent() {
        if (Log.getLogger() != null) {
            return false;
        }

        LoggerD logger = new LoggerD();
        logger.setReading(true);
        Log.setLogger(logger);
        Log.setLogDestination(Log.LogDestination.CONSOLE);
        return true;
    }
}
