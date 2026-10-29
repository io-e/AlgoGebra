package org.geogebra.plus.host;

import java.io.PrintStream;
import java.lang.reflect.Method;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Base64;
import java.util.List;

/**
 * GROK_V1 opt-in scenario test hook (never active unless -Dggbplus.scenario=&lt;file&gt; is set).
 * Executes a TAB-separated directive file against the embedded 2D GgbAPI, the 3D GgbAPI and the 2D AppD,
 * and prints one line per directive: {@code [GeoGebraPlus] SCN<TAB>id<TAB>OK|ERR<TAB>value}.
 * Uses reflection only (public upstream API names), so the host manifest is unchanged and the same class
 * runs outside OSGi in the plain-classpath upstream baseline (tests/tools/ScenarioBaseline_GROK_V1.java).
 * Directives: CMD, VAL, TYPE, DEF, CAS, CMD3, VAL3, NAMES, NAMES3, COUNT, XMLSHA, SAVE, NEW, OPEN, OPENRAW,
 * PNG, SVG, TOOLS, UNDO, SETVAL, SLEEP, JAVA, EXIT.
 */
public final class ScenarioScript {

    public static final String PREFIX = "[GeoGebraPlus] SCN\t";

    private final Object api2d;
    private final Object api3d;
    private final Object app2d;
    private final PrintStream out;

    public ScenarioScript(Object api2d, Object api3d, Object app2d, PrintStream out) {
        this.api2d = api2d;
        this.api3d = api3d;
        this.app2d = app2d;
        this.out = out;
    }

    /** Runs all lines; returns false when an EXIT directive was read. Each line is run via the supplied executor. */
    public void runFile(Path file, java.util.function.Consumer<Runnable> onUiThread) throws Exception {
        List<String> lines = Files.readAllLines(file, StandardCharsets.UTF_8);
        out.println(PREFIX + "_BEGIN\tOK\t" + file.getFileName() + "\t" + lines.size() + " lines");
        startDialogWatchdog();
        // Test harness only: route command errors to the log instead of a modal JOptionPane that would block the EDT.
        for (Object api : new Object[] {api2d, api3d}) {
            if (api != null) {
                try {
                    call(api, "setErrorDialogsActive", false);
                } catch (Exception e) {
                    out.println(PREFIX + "_WARN\tERR\tsetErrorDialogsActive: " + e);
                }
            }
        }
        for (String raw : lines) {
            if (raw.isBlank() || raw.startsWith("#")) {
                continue;
            }
            String[] f = raw.split("\t", 3);
            String op = f[0].trim();
            String id = f.length > 1 ? f[1] : "-";
            String arg = f.length > 2 ? f[2] : "";
            if (op.equals("SLEEP")) {
                Thread.sleep(Long.parseLong(arg.isEmpty() ? id : arg));
                continue;
            }
            if (op.equals("EXIT")) {
                break;
            }
            String[] result = new String[2];
            onUiThread.accept(() -> {
                try {
                    result[0] = "OK";
                    result[1] = execute(op, arg);
                } catch (Throwable error) {
                    Throwable cause = error.getCause() != null ? error.getCause() : error;
                    result[0] = "ERR";
                    result[1] = cause.getClass().getSimpleName() + ": " + cause.getMessage();
                }
            });
            out.println(PREFIX + id + "\t" + result[0] + "\t" + clean(result[1]));
        }
        out.println(PREFIX + "_END\tOK\tdone");
    }

    private String execute(String op, String arg) throws Exception {
        switch (op) {
        case "CMD":
            return String.valueOf(call(api2d, "evalCommand", arg));
        case "CMD3":
            return String.valueOf(call(require3d(), "evalCommand", arg));
        case "VAL":
            return String.valueOf(call(api2d, "getValueString", arg));
        case "VAL3":
            return String.valueOf(call(require3d(), "getValueString", arg));
        case "TYPE":
            return String.valueOf(call(api2d, "getObjectType", arg));
        case "DEF":
            return String.valueOf(call(api2d, "isDefined", arg));
        case "CAS":
            return String.valueOf(call(api2d, "evalCommandCAS", arg, null));
        case "NAMES":
            return sortedNames(api2d);
        case "NAMES3":
            return sortedNames(require3d());
        case "COUNT":
            return String.valueOf(call(api2d, "getObjectNumber"));
        case "SETVAL": {
            String[] p = arg.split("=", 2);
            call(api2d, "setValue", p[0].trim(), Double.parseDouble(p[1].trim()));
            return String.valueOf(call(api2d, "getValueString", p[0].trim()));
        }
        case "XMLSHA":
            return sha256(String.valueOf(call(api2d, "getXML")).getBytes(StandardCharsets.UTF_8));
        case "SAVE": {
            byte[] ggb = Base64.getDecoder().decode((String) call(api2d, "getBase64"));
            Path target = Path.of(arg);
            Files.createDirectories(target.toAbsolutePath().getParent());
            Files.write(target, ggb);
            return ggb.length + " bytes sha256=" + sha256(ggb);
        }
        case "NEW":
            call(api2d, "newConstruction");
            return String.valueOf(call(api2d, "getObjectNumber"));
        case "OPEN":
        case "OPENRAW": {
            byte[] data = Files.readAllBytes(Path.of(arg));
            call(api2d, "setBase64", Base64.getEncoder().encodeToString(data));
            return "objects=" + call(api2d, "getObjectNumber");
        }
        case "PNG": {
            java.io.File f = arg.isEmpty() ? java.io.File.createTempFile("ggbplus-scn", ".png") : new java.io.File(arg);
            boolean ok = (Boolean) call(api2d, "writePNGtoFile", f.getAbsolutePath(), 1.0, false, 72.0, false);
            return ok + "; bytes=" + f.length();
        }
        case "SVG": {
            String[] svg = new String[1];
            call(api2d, "exportSVG", null, (java.util.function.Consumer<String>) s -> svg[0] = s);
            if (svg[0] == null) {
                return "null";
            }
            if (!arg.isEmpty()) {
                Files.writeString(Path.of(arg), svg[0], StandardCharsets.UTF_8);
            }
            return svg[0].length() + " chars; starts=" + svg[0].substring(0, Math.min(5, svg[0].length()));
        }
        case "TOOLS": {
            Object gui = call(app2d, "getGuiManager");
            return String.valueOf(call(gui, "getToolbarDefinition"));
        }
        case "UNDOPOINT":
            call(api2d, "setUndoPoint");
            return "ok";
        case "UNDO":
            call(api2d, "undo");
            return String.valueOf(call(api2d, "getObjectNumber"));
        case "JAVA":
            return System.getProperty("java.runtime.version") + "; ggb=" + call(api2d, "getVersion");
        default:
            throw new IllegalArgumentException("unknown directive " + op);
        }
    }

    private Object require3d() {
        if (api3d == null) {
            throw new IllegalStateException("no 3D API in this host");
        }
        return api3d;
    }

    private static String sortedNames(Object api) throws Exception {
        String[] names = (String[]) call(api, "getAllObjectNames");
        String[] copy = names.clone();
        Arrays.sort(copy);
        return String.join(",", copy);
    }

    static Object call(Object target, String name, Object... args) throws Exception {
        List<Method> candidates = new ArrayList<>();
        for (Method m : target.getClass().getMethods()) {
            if (m.getName().equals(name) && m.getParameterCount() == args.length) {
                candidates.add(m);
            }
        }
        for (Method m : candidates) {
            Class<?>[] types = m.getParameterTypes();
            boolean ok = true;
            for (int i = 0; i < types.length && ok; i++) {
                ok = args[i] == null ? !types[i].isPrimitive() : box(types[i]).isInstance(args[i]);
            }
            if (ok) {
                m.setAccessible(true);
                return m.invoke(target, args);
            }
        }
        throw new NoSuchMethodException(target.getClass().getName() + "." + name + "/" + args.length);
    }

    private static Class<?> box(Class<?> t) {
        if (!t.isPrimitive()) {
            return t;
        }
        if (t == double.class) {
            return Double.class;
        }
        if (t == boolean.class) {
            return Boolean.class;
        }
        if (t == int.class) {
            return Integer.class;
        }
        return Object.class;
    }

    private static String sha256(byte[] data) throws Exception {
        byte[] d = java.security.MessageDigest.getInstance("SHA-256").digest(data);
        StringBuilder sb = new StringBuilder();
        for (byte b : d) {
            sb.append(String.format("%02x", b));
        }
        return sb.toString();
    }

    private static String clean(String s) {
        return s == null ? "null" : s.replace("\r", "\\r").replace("\n", "\\n").replace("\t", " ");
    }

    /** Test harness only: GgbAPI.evalCommand uses the app error handler, which opens a modal JOptionPane and
     * blocks the script. Record the dialog text as evidence (SCN _DIALOG) and close it, so the run continues. */
    private void startDialogWatchdog() {
        Thread t = new Thread(() -> {
            java.util.Set<java.awt.Window> seen = java.util.Collections.newSetFromMap(new java.util.WeakHashMap<>());
            while (true) {
                try {
                    Thread.sleep(400);
                } catch (InterruptedException e) {
                    return;
                }
                for (java.awt.Window w : java.awt.Window.getWindows()) {
                    if (w instanceof java.awt.Dialog && w.isShowing() && ((java.awt.Dialog) w).isModal() && seen.add(w)) {
                        StringBuilder sb = new StringBuilder();
                        collectText(w, sb);
                        out.println(PREFIX + "_DIALOG\tERR\t" + ((java.awt.Dialog) w).getTitle() + " | " + sb.toString().trim());
                        out.flush();
                        java.awt.EventQueue.invokeLater(w::dispose);
                    }
                }
            }
        }, "ggbplus-scenario-dialog-watchdog");
        t.setDaemon(true);
        t.start();
    }

    private static void collectText(java.awt.Component c, StringBuilder sb) {
        if (c instanceof javax.swing.JLabel) {
            sb.append(((javax.swing.JLabel) c).getText()).append(' ');
        } else if (c instanceof javax.swing.text.JTextComponent) {
            sb.append(((javax.swing.text.JTextComponent) c).getText()).append(' ');
        } else if (c instanceof javax.swing.AbstractButton) {
            sb.append('[').append(((javax.swing.AbstractButton) c).getText()).append("] ");
        }
        if (c instanceof java.awt.Container) {
            for (java.awt.Component k : ((java.awt.Container) c).getComponents()) {
                collectText(k, sb);
            }
        }
    }
}
