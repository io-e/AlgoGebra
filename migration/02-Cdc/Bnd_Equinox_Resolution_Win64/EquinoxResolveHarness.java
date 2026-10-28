import java.io.File;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.eclipse.osgi.launch.EquinoxFactory;
import org.osgi.framework.Bundle;
import org.osgi.framework.BundleContext;
import org.osgi.framework.launch.Framework;
import org.osgi.framework.wiring.BundleCapability;
import org.osgi.framework.wiring.BundleRequirement;
import org.osgi.framework.wiring.BundleRevision;
import org.osgi.framework.wiring.FrameworkWiring;

/** Resolve the staged bundle set in the exact installed Equinox framework. */
public class EquinoxResolveHarness {
    private static String state(int state) {
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

    public static void main(String[] args) throws Exception {
        if (args.length != 2) {
            throw new IllegalArgumentException("Usage: EquinoxResolveHarness <bundle-dir> <storage-dir>");
        }
        File bundleDir = new File(args[0]).getCanonicalFile();
        File storage = new File(args[1]).getCanonicalFile();
        Map<String, String> config = new HashMap<>();
        config.put("org.osgi.framework.storage", storage.getAbsolutePath());
        config.put("org.osgi.framework.storage.clean", "onFirstInit");
        config.put("osgi.noShutdown", "false");

        Framework framework = new EquinoxFactory().newFramework(config);
        framework.init();
        BundleContext context = framework.getBundleContext();
        List<Bundle> installed = new ArrayList<>();
        File[] jars = bundleDir.listFiles((dir, name) -> name.endsWith(".jar")
                && !name.startsWith("org.eclipse.osgi_"));
        if (jars == null || jars.length == 0) {
            throw new IllegalStateException("No staged bundle jars found in " + bundleDir);
        }
        java.util.Arrays.sort(jars, java.util.Comparator.comparing(File::getName));
        for (File jar : jars) {
            Bundle bundle = context.installBundle(jar.toURI().toString());
            installed.add(bundle);
        }

        FrameworkWiring wiring = framework.adapt(FrameworkWiring.class);
        boolean allResolved = wiring.resolveBundles(installed);
        System.out.println("Equinox=" + framework.getVersion() + "; installed=" + installed.size()
                + "; allResolved=" + allResolved);
        System.out.println("symbolicName\tversion\tstate\tlocation");
        for (Bundle bundle : installed) {
            System.out.println(bundle.getSymbolicName() + "\t" + bundle.getVersion() + "\t"
                    + state(bundle.getState()) + "\t" + new File(bundle.getLocation().replace("file:", "")).getName());
        }

        int unresolved = 0;
        for (Bundle bundle : installed) {
            if (bundle.getState() == Bundle.INSTALLED) {
                unresolved++;
                BundleRevision revision = bundle.adapt(BundleRevision.class);
                System.out.println("UNRESOLVED_BUNDLE\t" + bundle.getSymbolicName());
                for (BundleRequirement requirement : revision.getDeclaredRequirements(null)) {
                    Collection<BundleCapability> providers = wiring.findProviders(requirement);
                    System.out.println("  REQUIREMENT\t" + requirement.getNamespace() + "\t"
                            + requirement.getAttributes() + "\t" + requirement.getDirectives()
                            + "\tproviderCandidates=" + providers.size());
                }
            }
        }
        System.out.println("unresolved=" + unresolved);
        framework.stop();
        framework.waitForStop(10_000L);
        if (!allResolved || unresolved != 0) {
            System.exit(2);
        }
    }
}
