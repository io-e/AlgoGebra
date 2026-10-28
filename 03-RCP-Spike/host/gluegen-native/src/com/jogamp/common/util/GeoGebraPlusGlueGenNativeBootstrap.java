package com.jogamp.common.util;

/** Spike-only native preloader defined in the GlueGen host bundle's class space. */
public final class GeoGebraPlusGlueGenNativeBootstrap {

    private static volatile boolean loaded;

    private GeoGebraPlusGlueGenNativeBootstrap() {
    }

    public static synchronized boolean loadFromLibraryPath() {
        if (!loaded) {
            System.loadLibrary("gluegen_rt");
            loaded = true;
        }
        return loaded;
    }

    public static boolean isLoaded() {
        return loaded;
    }
}
