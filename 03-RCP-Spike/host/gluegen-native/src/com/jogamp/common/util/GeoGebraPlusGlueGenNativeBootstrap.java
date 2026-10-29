package com.jogamp.common.util;

import java.io.InputStream;
import java.net.URL;
import java.nio.file.Files;
import java.nio.file.Path;

/** Product-local native preloader defined in the GlueGen bundle's class space. */
public final class GeoGebraPlusGlueGenNativeBootstrap {

    private static volatile boolean loaded;

    private GeoGebraPlusGlueGenNativeBootstrap() {
    }

    public static synchronized boolean loadFromClasspath() throws Exception {
        if (!loaded) {
            loadResource("natives/windows-amd64/gluegen_rt.dll", "gluegen_rt.dll");
            loaded = true;
        }
        return loaded;
    }

    private static void loadResource(String resourceName, String fileName) throws Exception {
        URL resource = ClassLoader.getSystemResource(resourceName);
        if (resource == null) {
            throw new UnsatisfiedLinkError("Native resource is absent from the product class path: "
                    + resourceName);
        }
        Path extractionDirectory = Files.createTempDirectory("geogebraplus-gluegen-");
        Path extractedLibrary = extractionDirectory.resolve(fileName);
        try (InputStream input = resource.openStream()) {
            Files.copy(input, extractedLibrary);
        }
        System.load(extractedLibrary.toAbsolutePath().toString());
        System.out.println("[GeoGebraPlus] GlueGen native loaded from product classpath: "
                + extractedLibrary.toAbsolutePath());
    }

    public static boolean isLoaded() {
        return loaded;
    }
}
