package javagiac;

import java.io.InputStream;
import java.net.URL;
import java.nio.file.Files;
import java.nio.file.Path;

/**
 * Product-local Equinox replacement for the desktop classpath native loader.
 * This class is placed in the GIAC JNI host bundle's class space by an OSGi
 * fragment because JNI libraries belong to the class loader that performs
 * the load. The DLL is read from the installed application's native-classifier
 * JAR and loaded by absolute path, without requiring java.library.path.
 */
public final class GiacNativeBootstrap {

    private static volatile boolean loaded;

    private GiacNativeBootstrap() {
    }

    public static synchronized boolean loadFromClasspath() throws Exception {
        if (!loaded) {
            URL dllResource = ClassLoader.getSystemResource("javagiac64.dll");
            if (dllResource == null) {
                dllResource = GiacNativeBootstrap.class.getClassLoader().getResource("javagiac64.dll");
            }
            if (dllResource == null) {
                throw new UnsatisfiedLinkError("javagiac64.dll is absent from the product class path");
            }
            Path extractionDirectory = Files.createTempDirectory("geogebraplus-giac-");
            Path extractedDll = extractionDirectory.resolve("javagiac64.dll");
            try (InputStream input = dllResource.openStream()) {
                Files.copy(input, extractedDll);
            }
            System.load(extractedDll.toAbsolutePath().toString());
            System.out.println("[GeoGebraPlus] GIAC DLL loaded from product classpath: "
                    + extractedDll.toAbsolutePath());
            loaded = true;
        }
        return loaded;
    }

    public static boolean isLoaded() {
        return loaded;
    }
}
