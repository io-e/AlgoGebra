package javagiac;

/**
 * Spike-only loader placed in the GIAC JNI host bundle's class space by an
 * OSGi fragment. JNI libraries are scoped to the class loader that performs
 * the load, so this must be defined by the same bundle class loader as
 * {@code javagiac.giacJNI}.
 */
public final class GiacNativeBootstrap {

    private static volatile boolean loaded;

    private GiacNativeBootstrap() {
    }

    public static synchronized boolean loadFromLibraryPath() {
        if (!loaded) {
            System.loadLibrary("javagiac64");
            loaded = true;
        }
        return loaded;
    }

    public static boolean isLoaded() {
        return loaded;
    }
}
