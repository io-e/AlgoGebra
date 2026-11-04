package org.geogebra.plus.host;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Set;
import java.util.jar.JarFile;

import org.osgi.framework.Bundle;
import org.osgi.framework.BundleContext;
import org.osgi.framework.BundleException;
import org.osgi.framework.Constants;
import org.osgi.framework.Filter;
import org.osgi.framework.FrameworkUtil;
import org.osgi.util.tracker.ServiceTracker;

/**
 * Opt-in D-06 spike manager. This intentionally has a tiny, explicit allowlist;
 * it is proof code, not a general extension marketplace or a signing policy.
 */
final class ExtensionBundleManager {

    private static final String LOG = "[GeoGebraPlus] ";
    private static final String ALLOWED_TEST_BSN = "org.geogebra.plus.test.extension";
    private static final String SERVICE_TOKEN_KEY = "ggbplus.d06.token";
    private static final String SERVICE_TOKEN = "d06-service-v1";
    private static final long SERVICE_TIMEOUT_MILLIS = 10_000;
    private static final int EXPECTED_CORE_BUNDLES = 50;
    private static final Set<String> ALLOWLIST = Set.of(ALLOWED_TEST_BSN);

    private final BundleContext context;

    private ExtensionBundleManager(BundleContext context) {
        this.context = context;
    }

    static void runProof(BundleContext context, Path goodBundle, Path unresolvedBundle,
            Path unapprovedBundle) throws Exception {
        new ExtensionBundleManager(context).run(goodBundle, unresolvedBundle, unapprovedBundle);
    }

    private void run(Path goodBundlePath, Path unresolvedBundlePath, Path unapprovedBundlePath)
            throws Exception {
        long baselineCoreCount = assertCoreBundleSet("before D-06");
        Bundle goodBundle = null;
        try {
            expectUnapprovedBundleRejected(unapprovedBundlePath);

            goodBundle = installAllowlisted(goodBundlePath);
            if (goodBundle.getState() != Bundle.INSTALLED) {
                throw new IllegalStateException("New extension should initially be INSTALLED, got "
                        + stateName(goodBundle.getState()));
            }
            System.out.println(LOG + "D-06-01 extension installed: " + goodBundle.getSymbolicName()
                    + " location=" + goodBundle.getLocation());

            Filter filter = FrameworkUtil.createFilter("(&(objectClass=java.lang.Runnable)("
                    + SERVICE_TOKEN_KEY + "=" + SERVICE_TOKEN + "))");
            ServiceTracker<Runnable, Runnable> tracker = new ServiceTracker<>(context, filter, null);
            try {
                tracker.open();
                goodBundle.start();
                if (goodBundle.getState() != Bundle.ACTIVE) {
                    throw new IllegalStateException("Extension did not become ACTIVE: "
                            + stateName(goodBundle.getState()));
                }
                Runnable service = tracker.waitForService(SERVICE_TIMEOUT_MILLIS);
                if (service == null) {
                    throw new IllegalStateException("ServiceTracker did not discover the extension Runnable service");
                }
                service.run();
                if (tracker.getServiceReference() == null) {
                    throw new IllegalStateException("ServiceTracker returned a service without a tracked reference");
                }
                System.out.println(LOG + "D-06-02 ServiceTracker discovered the allowlisted extension service");

                goodBundle.stop();
                if (goodBundle.getState() != Bundle.RESOLVED) {
                    throw new IllegalStateException("Extension did not become RESOLVED after stop: "
                            + stateName(goodBundle.getState()));
                }
                if (tracker.getServiceReference() != null || tracker.getService() != null) {
                    throw new IllegalStateException("Extension service remained visible after bundle stop");
                }
                System.out.println(LOG + "D-06-03 ServiceTracker confirmed service removal after stop");
            } finally {
                tracker.close();
            }

            goodBundle.uninstall();
            if (goodBundle.getState() != Bundle.UNINSTALLED) {
                throw new IllegalStateException("Extension did not become UNINSTALLED: "
                        + stateName(goodBundle.getState()));
            }
            goodBundle = null;
            System.out.println(LOG + "D-06-04 allowlisted extension uninstalled without framework restart");

            expectUnresolvedBundleRejected(unresolvedBundlePath);
            long finalCoreCount = assertCoreBundleSet("after D-06");
            if (baselineCoreCount != finalCoreCount) {
                throw new IllegalStateException("Core bundle count changed during D-06: before="
                        + baselineCoreCount + ", after=" + finalCoreCount);
            }
            System.out.println(LOG + "D-06 PASS: install/start/ServiceTracker/stop/uninstall;"
                    + " bad bundles rejected; core=" + finalCoreCount + "/" + EXPECTED_CORE_BUNDLES);
        } catch (Exception | Error failure) {
            System.err.println(LOG + "D-06 FAIL: " + failure.getClass().getSimpleName() + ": "
                    + failure.getMessage());
            throw failure;
        } finally {
            uninstallQuietly(goodBundle);
        }
    }

    private Bundle installAllowlisted(Path candidate) throws Exception {
        Path archive = requireRegularFile(candidate);
        String symbolicName = readSymbolicName(archive);
        if (!ALLOWLIST.contains(symbolicName)) {
            System.err.println(LOG + "D-06 REJECTED bundle before installation: not allowlisted: "
                    + symbolicName + " at " + archive);
            throw new SecurityException("OSGi bundle is not on the D-06 allowlist: " + symbolicName);
        }
        String location = archive.toUri().toString();
        Bundle installed = context.installBundle(location);
        System.out.println(LOG + "D-06 allowlisted bundle installed: " + symbolicName + " at " + location);
        return installed;
    }

    private void expectUnapprovedBundleRejected(Path candidate) throws Exception {
        Path archive = requireRegularFile(candidate);
        String symbolicName = readSymbolicName(archive);
        if (ALLOWLIST.contains(symbolicName)) {
            throw new IllegalStateException("Unapproved-bundle fixture unexpectedly uses an allowlisted BSN: "
                    + symbolicName);
        }
        String location = archive.toUri().toString();
        try {
            installAllowlisted(archive);
            throw new IllegalStateException("Unapproved extension was installed: " + symbolicName);
        } catch (SecurityException expected) {
            if (findByLocation(location) != null) {
                throw new IllegalStateException("Rejected bundle was nevertheless installed: " + symbolicName);
            }
            System.out.println(LOG + "D-06-05 unapproved extension rejected before install: " + symbolicName);
        }
    }

    private void expectUnresolvedBundleRejected(Path candidate) throws Exception {
        Bundle badBundle = installAllowlisted(candidate);
        try {
            try {
                badBundle.start();
                throw new IllegalStateException("Bundle with a mandatory missing import unexpectedly started");
            } catch (BundleException expected) {
                if (badBundle.getState() != Bundle.INSTALLED) {
                    throw new IllegalStateException("Unresolved extension must remain INSTALLED, got "
                            + stateName(badBundle.getState()), expected);
                }
                System.out.println(LOG + "D-06-06 unresolved allowlisted extension rejected at resolve/start: "
                        + badBundle.getSymbolicName() + "; state=" + stateName(badBundle.getState()));
            }
        } finally {
            uninstallQuietly(badBundle);
        }
    }

    private long assertCoreBundleSet(String phase) {
        long seen = 0;
        long usable = 0;
        for (Bundle bundle : context.getBundles()) {
            if (!isCoreBundle(bundle.getSymbolicName())) {
                continue;
            }
            seen++;
            if (bundle.getState() == Bundle.RESOLVED || bundle.getState() == Bundle.ACTIVE) {
                usable++;
            }
        }
        System.out.println(LOG + "D-06 core integrity " + phase + ": resolved-or-active=" + usable
                + "/" + seen + "; expected=" + EXPECTED_CORE_BUNDLES);
        if (seen != EXPECTED_CORE_BUNDLES || usable != EXPECTED_CORE_BUNDLES) {
            throw new IllegalStateException("D-03 core bundle set was not preserved " + phase
                    + ": resolved-or-active=" + usable + ", seen=" + seen);
        }
        return usable;
    }

    private static boolean isCoreBundle(String symbolicName) {
        return symbolicName != null && (symbolicName.startsWith("org.geogebra.migration.")
                || symbolicName.equals("com.sun.jna")
                || symbolicName.equals("org.jspecify.jspecify")
                || symbolicName.equals("org.jsr-305")
                || symbolicName.equals("spotbugs-annotations"));
    }

    private Bundle findByLocation(String location) {
        for (Bundle bundle : context.getBundles()) {
            if (location.equals(bundle.getLocation())) {
                return bundle;
            }
        }
        return null;
    }

    private static Path requireRegularFile(Path candidate) throws IOException {
        if (candidate == null) {
            throw new IllegalArgumentException("D-06 fixture path is required");
        }
        Path archive = candidate.toRealPath();
        if (!Files.isRegularFile(archive) || !Files.isReadable(archive)) {
            throw new IllegalArgumentException("D-06 fixture is not a readable regular file: " + archive);
        }
        return archive;
    }

    private static String readSymbolicName(Path archive) throws IOException {
        try (JarFile jar = new JarFile(archive.toFile(), false)) {
            String header = jar.getManifest() == null ? null
                    : jar.getManifest().getMainAttributes().getValue(Constants.BUNDLE_SYMBOLICNAME);
            if (header == null || header.isBlank()) {
                throw new IllegalArgumentException("D-06 fixture has no Bundle-SymbolicName: " + archive);
            }
            return header.split(";", 2)[0].trim();
        }
    }

    private static void uninstallQuietly(Bundle bundle) {
        if (bundle == null || bundle.getState() == Bundle.UNINSTALLED) {
            return;
        }
        try {
            if (bundle.getState() == Bundle.ACTIVE || bundle.getState() == Bundle.STARTING) {
                bundle.stop();
            }
            bundle.uninstall();
        } catch (BundleException cleanupFailure) {
            System.err.println(LOG + "D-06 cleanup warning for " + bundle.getSymbolicName() + ": "
                    + cleanupFailure.getMessage());
        }
    }

    private static String stateName(int state) {
        return switch (state) {
        case Bundle.UNINSTALLED -> "UNINSTALLED";
        case Bundle.INSTALLED -> "INSTALLED";
        case Bundle.RESOLVED -> "RESOLVED";
        case Bundle.STARTING -> "STARTING";
        case Bundle.STOPPING -> "STOPPING";
        case Bundle.ACTIVE -> "ACTIVE";
        default -> "UNKNOWN(" + state + ")";
        };
    }
}
