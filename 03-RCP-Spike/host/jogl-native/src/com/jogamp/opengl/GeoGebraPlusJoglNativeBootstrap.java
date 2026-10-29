package com.jogamp.opengl;

import java.io.InputStream;
import java.net.URL;
import java.nio.file.Files;
import java.nio.file.Path;

/** Product-local native preloader defined in the JOGL bundle's class space. */
public final class GeoGebraPlusJoglNativeBootstrap {

    private static volatile boolean loaded;

    private GeoGebraPlusJoglNativeBootstrap() {
    }

    public static synchronized boolean loadFromClasspath() throws Exception {
        if (!loaded) {
            // These nativewindow/Newt classes are packaged in the JOGL host
            // bundle in this OSGi wrapping, so their JNI libraries must be
            // associated with that same bundle class loader (not GlueGen's).
            if (System.getProperty("os.name","").toLowerCase(java.util.Locale.ROOT).startsWith("windows")) {
                loadResource("natives/windows-amd64/nativewindow_awt.dll");
                loadResource("natives/windows-amd64/nativewindow_win32.dll");
                loadResource("natives/windows-amd64/newt_head.dll");
                loadResource("natives/windows-amd64/jogl_desktop.dll");
                loadResource("natives/windows-amd64/jogl_mobile.dll");
            } else { // Linux port (GROK_V1)
                loadResource("natives/linux-amd64/libnativewindow_awt.so");
                loadResource("natives/linux-amd64/libnativewindow_x11.so");
                loadResource("natives/linux-amd64/libnewt_head.so");
                loadResource("natives/linux-amd64/libjogl_desktop.so");
                loadResource("natives/linux-amd64/libjogl_mobile.so");
            }
            loaded = true;
        }
        return loaded;
    }

    private static void loadResource(String resourceName) throws Exception {
        URL resource = ClassLoader.getSystemResource(resourceName);
        if (resource == null) {
            throw new UnsatisfiedLinkError("Native resource is absent from the product class path: "
                    + resourceName);
        }
        String fileName = resourceName.substring(resourceName.lastIndexOf('/') + 1);
        Path extractionDirectory = Files.createTempDirectory("geogebraplus-jogl-");
        Path extractedLibrary = extractionDirectory.resolve(fileName);
        try (InputStream input = resource.openStream()) {
            Files.copy(input, extractedLibrary);
        }
        System.load(extractedLibrary.toAbsolutePath().toString());
        System.out.println("[GeoGebraPlus] JOGL native loaded from product classpath: "
                + extractedLibrary.toAbsolutePath());
    }

    public static boolean isLoaded() {
        return loaded;
    }
}
