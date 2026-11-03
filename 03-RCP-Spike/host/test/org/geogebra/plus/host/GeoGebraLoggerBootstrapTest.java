package org.geogebra.plus.host;

import org.geogebra.common.util.debug.Log;
import org.geogebra.desktop.util.LoggerD;

/** Standalone regression smoke for BUG-010's embedded desktop logger setup. */
public final class GeoGebraLoggerBootstrapTest {

    private static int checks;

    private GeoGebraLoggerBootstrapTest() {
    }

    public static void main(String[] args) {
        Log.setLogger(null);

        check(GeoGebraLoggerBootstrap.initializeIfAbsent(), "logger is installed when absent");
        Log logger = Log.getLogger();
        check(logger instanceof LoggerD, "desktop LoggerD is installed");
        check(Log.getLogDestination() == Log.LogDestination.CONSOLE, "logger uses console destination");

        try {
            Log.read("GeoGebraPlus logger smoke");
            check(true, "Log.read no longer throws when the embedded logger is initialized");
        } catch (RuntimeException error) {
            check(false, "Log.read threw " + error);
        }

        check(!GeoGebraLoggerBootstrap.initializeIfAbsent(), "second initialization preserves the existing logger");
        check(Log.getLogger() == logger, "existing logger instance is not replaced");
        System.out.println("GeoGebraLoggerBootstrapTest: " + checks + " PASS, 0 FAIL");
    }

    private static void check(boolean condition, String description) {
        checks++;
        if (!condition) {
            throw new AssertionError(description);
        }
        System.out.println("PASS: " + description);
    }
}
