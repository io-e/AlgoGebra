package com.jogamp.opengl;

/** Spike-only native preloader defined in the JOGL host bundle's class space. */
public final class GeoGebraPlusJoglNativeBootstrap {

    private static volatile boolean loaded;

    private GeoGebraPlusJoglNativeBootstrap() {
    }

    public static synchronized boolean loadFromLibraryPath() {
        if (!loaded) {
            // These nativewindow/Newt classes are packaged in the JOGL host
            // bundle in this OSGi wrapping, so their JNI libraries must be
            // associated with that same bundle class loader (not GlueGen's).
            System.loadLibrary("nativewindow_awt");
            System.loadLibrary("nativewindow_win32");
            System.loadLibrary("newt_head");
            System.loadLibrary("jogl_desktop");
            System.loadLibrary("jogl_mobile");
            loaded = true;
        }
        return loaded;
    }

    public static boolean isLoaded() {
        return loaded;
    }
}
