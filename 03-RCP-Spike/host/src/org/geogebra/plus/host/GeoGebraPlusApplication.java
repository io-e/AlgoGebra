package org.geogebra.plus.host;

import java.awt.BorderLayout;
import java.awt.Frame;
import java.awt.Robot;
import java.awt.image.BufferedImage;
import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;

import javax.imageio.ImageIO;
import javax.swing.JPanel;
import javax.swing.SwingUtilities;

import org.eclipse.equinox.app.IApplication;
import org.eclipse.equinox.app.IApplicationContext;
import org.eclipse.swt.SWT;
import org.eclipse.swt.awt.SWT_AWT;
import org.eclipse.swt.custom.SashForm;
import org.eclipse.swt.layout.FillLayout;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Shell;
import org.geogebra.common.main.App;
import org.geogebra.desktop.CommandLineArguments;
import org.geogebra.desktop.GeoGebraPanel;
import org.geogebra.desktop.geogebra3D.App3D;
import org.osgi.framework.Bundle;
import org.osgi.framework.BundleContext;
import org.osgi.framework.FrameworkUtil;
import org.osgi.framework.wiring.FrameworkWiring;

/**
 * Raw-SWT GeoGebraPlus RCP application used for D-02, D-04 and D-05.
 * The ordinary 2D app is the upstream GeoGebraPanel. A separate App3D instance
 * supplies the 3D proof because GeoGebraPanel itself constructs AppD (2D).
 */
public final class GeoGebraPlusApplication implements IApplication {

    private static final String LOG = "[GeoGebraPlus] ";
    private static final int EXPECTED_GGB_EXTERNAL_BUNDLES = 50;

    private volatile Display display;
    private volatile Shell shell;

    @Override
    public Object start(IApplicationContext applicationContext) throws Exception {
        System.out.println(LOG + "IApplication.start() — D-02 entry");
        System.out.println(LOG + "Runtime: " + System.getProperty("java.runtime.version")
                + "; OS=" + System.getProperty("os.name") + "/"
                + System.getProperty("os.arch"));
        BundleContext context = FrameworkUtil.getBundle(getClass()).getBundleContext();
        System.out.println(LOG + "JogAmp boot delegation="
                + context.getProperty("org.osgi.framework.bootdelegation"));

        boolean d02Pass = resolveAndReportBundles();
        if (!d02Pass) {
            throw new IllegalStateException("D-02 bundle resolution acceptance failed; see bundle states above");
        }

        if (Boolean.getBoolean("ggbplus.headless")) {
            System.out.println(LOG + "Headless D-02 smoke mode; UI was intentionally skipped");
            return EXIT_OK;
        }

        openSwtShellWithGeoGebra();
        return EXIT_OK;
    }

    private boolean resolveAndReportBundles() {
        BundleContext context = FrameworkUtil.getBundle(getClass()).getBundleContext();
        Bundle[] all = context.getBundles();
        List<Bundle> toResolve = new ArrayList<>();
        List<String> problems = new ArrayList<>();
        int expectedCount = 0;
        int active = 0;
        int resolved = 0;
        int unresolved = 0;

        for (Bundle bundle : all) {
            String name = bundle.getSymbolicName();
            if (!isExpectedGeoGebraOrExternal(name)) {
                continue;
            }
            expectedCount++;
            toResolve.add(bundle);
        }

        FrameworkWiring wiring = context.getBundle(0).adapt(FrameworkWiring.class);
        boolean resolverResult = wiring != null && wiring.resolveBundles(toResolve);
        normalizeUnneededLazyStarts(toResolve);
        waitForBundleTransitions(toResolve);
        for (Bundle bundle : toResolve) {
            int state = bundle.getState();
            if (state == Bundle.ACTIVE) {
                active++;
            } else if (state == Bundle.RESOLVED) {
                resolved++;
            } else {
                unresolved++;
                problems.add(bundle.getSymbolicName() + ": " + stateName(state));
            }
        }

        System.out.println(LOG + "D-02 D-03-set check: expected="
                + EXPECTED_GGB_EXTERNAL_BUNDLES + ", found=" + expectedCount
                + ", ACTIVE=" + active + ", RESOLVED=" + resolved
                + ", unresolved/other=" + unresolved + ", resolveBundles=" + resolverResult);
        for (String problem : problems) {
            System.err.println(LOG + "UNRESOLVED " + problem);
        }
        boolean pass = expectedCount == EXPECTED_GGB_EXTERNAL_BUNDLES && unresolved == 0;
        System.out.println(LOG + "D-02 " + (pass ? "PASS" : "FAIL"));
        return pass;
    }

    private static void normalizeUnneededLazyStarts(List<Bundle> bundles) {
        for (Bundle bundle : bundles) {
            if (bundle.getState() == Bundle.STARTING
                    && "lazy".equals(bundle.getHeaders().get("Bundle-ActivationPolicy"))) {
                try {
                    // A D-03 bundle can be lazily started as a side effect of
                    // resolver/runtime probing. No GeoGebra bundle requires JNA
                    // activator state, so return such bundles to RESOLVED; a later
                    // real class use can activate them normally.
                    bundle.stop(Bundle.STOP_TRANSIENT);
                    System.out.println(LOG + "Normalized lazy bundle to RESOLVED for D-02: "
                            + bundle.getSymbolicName());
                } catch (Exception e) {
                    System.err.println(LOG + "Could not normalize lazy bundle "
                            + bundle.getSymbolicName() + ": " + e);
                }
            }
        }
    }

    private static void waitForBundleTransitions(List<Bundle> bundles) {
        // Simple Configurator and Equinox raise the start level asynchronously.
        // Do not mistake a short-lived STARTING/STOPPING state for a resolver failure.
        for (int attempt = 0; attempt < 30; attempt++) {
            boolean transitioning = false;
            for (Bundle bundle : bundles) {
                if (bundle.getState() == Bundle.STARTING || bundle.getState() == Bundle.STOPPING) {
                    transitioning = true;
                    break;
                }
            }
            if (!transitioning) {
                return;
            }
            try {
                Thread.sleep(100);
            } catch (InterruptedException interrupted) {
                Thread.currentThread().interrupt();
                return;
            }
        }
    }

    private static boolean isExpectedGeoGebraOrExternal(String symbolicName) {
        if (symbolicName == null) {
            return false;
        }
        return symbolicName.startsWith("org.geogebra.migration.")
                || symbolicName.equals("com.sun.jna")
                || symbolicName.equals("org.jspecify.jspecify")
                || symbolicName.equals("org.jsr-305")
                || symbolicName.equals("spotbugs-annotations");
    }

    private static String stateName(int state) {
        switch (state) {
        case Bundle.UNINSTALLED:
            return "UNINSTALLED";
        case Bundle.INSTALLED:
            return "INSTALLED";
        case Bundle.RESOLVED:
            return "RESOLVED";
        case Bundle.STARTING:
            return "STARTING";
        case Bundle.STOPPING:
            return "STOPPING";
        case Bundle.ACTIVE:
            return "ACTIVE";
        default:
            return "UNKNOWN(" + state + ")";
        }
    }

    private void openSwtShellWithGeoGebra() throws Exception {
        display = new Display();
        shell = new Shell(display);
        shell.setText("GeoGebraPlus — Eclipse RCP Integration Spike");
        org.eclipse.swt.graphics.Rectangle workArea = display.getPrimaryMonitor().getClientArea();
        int shellWidth = Math.max(640, Math.min(1500, workArea.width - 24));
        int shellHeight = Math.max(480, Math.min(900, workArea.height - 48));
        shell.setSize(shellWidth, shellHeight);
        shell.setLocation(workArea.x + (workArea.width - shellWidth) / 2,
                workArea.y + (workArea.height - shellHeight) / 2);
        shell.setLayout(new FillLayout());

        SashForm sash = new SashForm(shell, SWT.HORIZONTAL);
        sash.setSashWidth(6);
        Composite twoDComposite = new Composite(sash, SWT.EMBEDDED | SWT.NO_BACKGROUND);
        Composite threeDComposite = new Composite(sash, SWT.EMBEDDED | SWT.NO_BACKGROUND);
        sash.setWeights(new int[] {58, 42});

        Frame twoDFrame = SWT_AWT.new_Frame(twoDComposite);
        Frame threeDFrame = SWT_AWT.new_Frame(threeDComposite);
        twoDFrame.setLayout(new BorderLayout());
        threeDFrame.setLayout(new BorderLayout());
        shell.addListener(SWT.Resize, event -> SwingUtilities.invokeLater(() -> {
            twoDFrame.validate();
            threeDFrame.validate();
        }));

        SwingUtilities.invokeAndWait(() -> initializeGeoGebra(twoDFrame, threeDFrame));

        shell.open();
        // Start with enough room for the full GeoGebra UI, including the
        // algebra-input rows. The shell remains resizable.
        shell.setMaximized(true);
        shell.forceActive();
        if (Boolean.getBoolean("ggbplus.captureEvidenceScreenshot")) {
            display.timerExec(25000, () -> captureEvidenceScreenshot(shell));
        }
        while (!shell.isDisposed()) {
            if (!display.readAndDispatch()) {
                display.sleep();
            }
        }
        display.dispose();
        display = null;
        shell = null;
    }

    private static void captureEvidenceScreenshot(Shell targetShell) {
        if (targetShell == null || targetShell.isDisposed()) {
            return;
        }
        try {
            org.eclipse.swt.graphics.Rectangle bounds = targetShell.getBounds();
            BufferedImage image = new Robot().createScreenCapture(
                    new java.awt.Rectangle(bounds.x, bounds.y, bounds.width, bounds.height));
            String runId = System.getProperty("ggbplus.runId", Long.toString(System.currentTimeMillis()));
            Path evidenceDir = Paths.get("evidence");
            Files.createDirectories(evidenceDir);
            Path screenshot = evidenceDir.resolve("rcp-" + runId + ".png");
            if (Files.exists(screenshot)) {
                throw new IllegalStateException("Refusing to overwrite existing evidence: " + screenshot);
            }
            ImageIO.write(image, "png", screenshot.toFile());
            System.out.println(LOG + "D-04 screenshot evidence saved: " + screenshot.toAbsolutePath());
        } catch (Throwable error) {
            System.err.println(LOG + "D-04 screenshot evidence capture failed: " + error);
            error.printStackTrace(System.err);
        }
    }

    private void initializeGeoGebra(Frame twoDFrame, Frame threeDFrame) {
        try {
            prepareNativeInOwningBundle(
                    "org.geogebra.migration.shared.giac.jni",
                    "javagiac.GiacNativeBootstrap",
                    "javagiac.giacJNI",
                    "GIAC");
            if (Boolean.getBoolean("ggbplus.jogampBootDelegation")) {
                System.out.println(LOG + "D-05 JogAmp uses app-loader boot delegation; "
                        + "native JARs are on the application class path");
            } else {
                prepareNativeInOwningBundle(
                        "org.geogebra.migration.external.org.jogamp.gluegen.gluegen-rt",
                        "com.jogamp.common.util.GeoGebraPlusGlueGenNativeBootstrap",
                        "jogamp.common.jvm.JVMUtil",
                        "GlueGen");
                prepareNativeInOwningBundle(
                        "org.geogebra.migration.external.org.jogamp.jogl.jogl-all",
                        "com.jogamp.opengl.GeoGebraPlusJoglNativeBootstrap",
                        "jogamp.nativewindow.jawt.JAWTFactory",
                        "JOGL");
            }
            prepareDesktopCasFactory();
            System.out.println(LOG + "System-loader GIAC DLL resource="
                    + ClassLoader.getSystemResource("javagiac64.dll"));
            GeoGebraPanel panel = new GeoGebraPanel();
            enableFullGuiForSpike(panel);
            panel.setShowMenubar(true);
            panel.setShowToolbar(true);
            panel.setShowAlgebraInput(true);
            panel.setShowAlgebraView(true);
            panel.buildGUI();
            twoDFrame.add(panel, BorderLayout.CENTER);
            twoDFrame.setVisible(true);
            twoDFrame.validate();
            System.out.println(LOG + "D-04 GeoGebraPanel embedded in SWT_AWT shell");

            try {
                boolean casEnabled = enableCasForSpike(panel);
                System.out.println(LOG + "D-05 CAS enabled=" + casEnabled
                        + "; factory=" + getCasFactoryClass(panel)
                        + " (test adapter uses reflection; not a proposed public API)");
                System.out.println(LOG + "D-05 GIAC JNI host-loader native loaded="
                        + isNativeBootstrapLoaded("org.geogebra.migration.shared.giac.jni",
                                "javagiac.GiacNativeBootstrap"));
                String cas = panel.getGeoGebraAPI().evalCommandCAS("Expand[(x+1)^2]", null);
                System.out.println(LOG + "D-05 GIAC native loaded=" + isGiacNativeLoaded(panel));
                System.out.println(LOG + "D-05 CAS result: " + cas);
                System.out.println(LOG + "D-05 CAS smoke 1+1: "
                        + panel.getGeoGebraAPI().evalCommandCAS("1+1", null));
                System.out.println(LOG + "D-05 CAS smoke x+1: "
                        + panel.getGeoGebraAPI().evalCommandCAS("x+1", null));
                System.out.println(LOG + "D-05 direct GIAC smoke: " + evaluateRawGiac(panel, "1+1"));
                String normalizedCas = normalizeCasResult(cas);
                if (cas == null || !(normalizedCas.contains("x^2+2x+1")
                        || normalizedCas.contains("x^2+2*x+1"))) {
                    System.err.println(LOG + "D-05 CAS result did not match the expected expansion");
                } else {
                    System.out.println(LOG + "D-05 CAS ASSERTION PASS: normalized=" + normalizedCas);
                }
            } catch (Throwable error) {
                System.err.println(LOG + "D-05 CAS FAILED: " + error);
                error.printStackTrace(System.err);
            }

            try {
                JPanel threeDHost = new JPanel(new BorderLayout());
                App3D app3D = new App3D(new CommandLineArguments(null), threeDHost);
                JPanel threeDPanel = app3D.buildApplicationPanel();
                // App3D needs its toolbar/container UI initialized before
                // DockManagerD updates the 3D panel visibility.
                app3D.getGuiManager().setShowView(true, App.VIEW_EUCLIDIAN3D);
                threeDHost.add(threeDPanel, BorderLayout.CENTER);
                threeDFrame.add(threeDHost, BorderLayout.CENTER);
                threeDFrame.setVisible(true);
                threeDFrame.validate();
                boolean pointCreated = app3D.getGgbApi().evalCommand("A = (1, 2, 3)");
                boolean threeDInitialized = app3D.isEuclidianView3Dinited();
                System.out.println(LOG + "D-05 3D point command accepted=" + pointCreated
                        + "; 3D view initialized=" + threeDInitialized);
                System.out.println(LOG + "D-05 3D note: GeoGebraPanel constructs the 2D AppD;"
                        + " the 3D proof uses an upstream App3D instance in the second SWT_AWT pane");
            } catch (Throwable error) {
                System.err.println(LOG + "D-05 3D FAILED: " + error);
                error.printStackTrace(System.err);
            }
        } catch (Throwable error) {
            System.err.println(LOG + "D-04 EMBEDDING FAILED: " + error);
            error.printStackTrace(System.err);
        }
    }

    private static void prepareDesktopCasFactory() throws ReflectiveOperationException {
        ClassLoader desktopLoader = GeoGebraPanel.class.getClassLoader();
        Class<?> factoryType = desktopLoader.loadClass("org.geogebra.common.factories.CASFactory");
        Class<?> desktopFactoryType = desktopLoader.loadClass("org.geogebra.desktop.factories.CASFactoryD");
        Object factory = desktopFactoryType.getConstructor().newInstance();
        factoryType.getMethod("setPrototype", factoryType).invoke(null, factory);
        System.out.println(LOG + "CAS factory prototype installed: " + factory.getClass().getName());
    }

    private static void prepareNativeInOwningBundle(String bundleName, String bootstrapClassName,
            String referenceClassName, String label) throws Exception {
        BundleContext context = FrameworkUtil.getBundle(GeoGebraPlusApplication.class).getBundleContext();
        Bundle ownerBundle = null;
        for (Bundle candidate : context.getBundles()) {
            if (bundleName.equals(candidate.getSymbolicName())) {
                ownerBundle = candidate;
                break;
            }
        }
        if (ownerBundle == null) {
            throw new IllegalStateException("The native owner bundle is missing: " + bundleName);
        }
        Class<?> bootstrap = ownerBundle.loadClass(bootstrapClassName);
        Class<?> reference = ownerBundle.loadClass(referenceClassName);
        if (bootstrap.getClassLoader() != reference.getClassLoader()) {
            throw new IllegalStateException(label + " bootstrap and native API classes have different class loaders");
        }
        // Native libraries are shipped as classifier-JAR resources in this
        // product. Each bundle fragment extracts and loads the libraries from
        // its owning bundle class loader so JNI ownership remains explicit.
        boolean loaded = (Boolean) bootstrap.getMethod("loadFromClasspath").invoke(null);
        if (!loaded) {
            throw new IllegalStateException(label + " native bootstrap returned false");
        }
        System.out.println(LOG + "D-05 " + label + " natives preloaded in owning bundle class loader: "
                + bootstrap.getClassLoader());
    }

    private static boolean isNativeBootstrapLoaded(String bundleName, String bootstrapClassName)
            throws ReflectiveOperationException {
        BundleContext context = FrameworkUtil.getBundle(GeoGebraPlusApplication.class).getBundleContext();
        for (Bundle candidate : context.getBundles()) {
            if (bundleName.equals(candidate.getSymbolicName())) {
                Class<?> bootstrap = candidate.loadClass(bootstrapClassName);
                return (Boolean) bootstrap.getMethod("isLoaded").invoke(null);
            }
        }
        return false;
    }

    private static String normalizeCasResult(String result) {
        if (result == null) {
            return "";
        }
        return result.toLowerCase(java.util.Locale.ROOT)
                .replace("\u00b2", "^2")
                .replace(" ", "")
                .replace("*", "");
    }

    private static String getCasFactoryClass(GeoGebraPanel panel) throws ReflectiveOperationException {
        Object app = getPanelApp(panel);
        return app.getClass().getMethod("getCASFactory").invoke(app).getClass().getName();
    }

    private static boolean isGiacNativeLoaded(GeoGebraPanel panel) throws ReflectiveOperationException {
        Object app = getPanelApp(panel);
        Class<?> giac = Class.forName("org.geogebra.desktop.cas.giac.CASgiacD", true,
                app.getClass().getClassLoader());
        Field loaded = giac.getDeclaredField("giacLoaded");
        loaded.setAccessible(true);
        return loaded.getBoolean(null);
    }

    private static String evaluateRawGiac(GeoGebraPanel panel, String input) {
        try {
            Object app = getPanelApp(panel);
            Object kernel = app.getClass().getMethod("getKernel").invoke(app);
            Object geoGebraCas = kernel.getClass().getMethod("getGeoGebraCAS").invoke(kernel);
            Object cas = geoGebraCas.getClass().getMethod("getCurrentCAS").invoke(geoGebraCas);
            Object result = cas.getClass().getMethod("evaluateRaw", String.class)
                    .invoke(cas, input);
            return cas.getClass().getName() + "(" + input + ") -> "
                    + String.valueOf(result).replace("\r", "\\r").replace("\n", "\\n");
        } catch (Throwable error) {
            Throwable cause = error.getCause() == null ? error : error.getCause();
            return "FAILED: " + cause;
        }
    }

    private static Object getPanelApp(GeoGebraPanel panel) throws ReflectiveOperationException {
        Field appField = GeoGebraPanel.class.getDeclaredField("app");
        appField.setAccessible(true);
        return appField.get(panel);
    }

    private static boolean enableCasForSpike(GeoGebraPanel panel) throws ReflectiveOperationException {
        Object app = getPanelApp(panel);
        Object settings = app.getClass().getMethod("getSettings").invoke(app);
        Object casSettings = settings.getClass().getMethod("getCasSettings").invoke(settings);
        Method setEnabled = casSettings.getClass().getMethod("setEnabled", boolean.class);
        setEnabled.invoke(casSettings, true);
        return (Boolean) casSettings.getClass().getMethod("isEnabled").invoke(casSettings);
    }

    private static void enableFullGuiForSpike(GeoGebraPanel panel) throws ReflectiveOperationException {
        Object app = getPanelApp(panel);
        app.getClass().getMethod("enableUseFullGui").invoke(app);
        boolean enabled = (Boolean) app.getClass().getMethod("isUsingFullGui").invoke(app);
        System.out.println(LOG + "D-04 embedded AppD full-GUI mode=" + enabled
                + " (spike adapter; GeoGebraPanel constructs AppD with minimal-GUI mode)");
    }

    @Override
    public void stop() {
        Display currentDisplay = display;
        Shell currentShell = shell;
        if (currentDisplay != null && !currentDisplay.isDisposed()
                && currentShell != null && !currentShell.isDisposed()) {
            currentDisplay.asyncExec(currentShell::close);
        }
    }
}
