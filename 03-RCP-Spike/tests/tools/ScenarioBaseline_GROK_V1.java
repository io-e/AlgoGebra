// GROK_V1 - upstream baseline runner for scenario scripts (P-02/P-03/P-04/P-05).
// Runs the SAME ScenarioScript class (host bundle jar, used as a plain jar) against the pinned upstream desktop
// distribution (geogebra/source/desktop/desktop/build/distributions/desktop.tar, lib/*) WITHOUT OSGi/SWT:
// GeoGebraPanel in a JFrame (2D, full GUI, CAS on) + App3D in a second JFrame. Output lines are identical in format.
// Usage: java -cp <upstream lib/*>:<host jar>:<this> ScenarioBaseline_GROK_V1 <script.tsv>
import java.awt.BorderLayout;
import java.lang.reflect.Field;
import java.nio.file.Path;
import javax.swing.JFrame;
import javax.swing.JPanel;
import javax.swing.SwingUtilities;
import org.geogebra.common.main.App;
import org.geogebra.desktop.CommandLineArguments;
import org.geogebra.desktop.GeoGebraPanel;
import org.geogebra.desktop.geogebra3D.App3D;
import org.geogebra.plus.host.ScenarioScript;

public class ScenarioBaseline_GROK_V1 {
    public static void main(String[] a) throws Exception {
        Object[] h = new Object[3];
        SwingUtilities.invokeAndWait(() -> {
            try {
                Class<?> ft = Class.forName("org.geogebra.common.factories.CASFactory");
                Object f = Class.forName("org.geogebra.desktop.factories.CASFactoryD").getConstructor().newInstance();
                ft.getMethod("setPrototype", ft).invoke(null, f);
                GeoGebraPanel panel = new GeoGebraPanel();
                Field af = GeoGebraPanel.class.getDeclaredField("app"); af.setAccessible(true);
                Object app = af.get(panel);
                app.getClass().getMethod("enableUseFullGui").invoke(app);
                panel.setShowMenubar(true); panel.setShowToolbar(true); panel.setShowAlgebraInput(true); panel.setShowAlgebraView(true);
                panel.buildGUI();
                JFrame f2 = new JFrame("baseline-2d"); f2.add(panel); f2.setSize(860, 870); f2.setVisible(true);
                Object settings = app.getClass().getMethod("getSettings").invoke(app);
                Object cas = settings.getClass().getMethod("getCasSettings").invoke(settings);
                cas.getClass().getMethod("setEnabled", boolean.class).invoke(cas, true);
                JPanel host3 = new JPanel(new BorderLayout());
                App3D app3D = new App3D(new CommandLineArguments(null), host3);
                JPanel p3 = app3D.buildApplicationPanel();
                app3D.getGuiManager().setShowView(true, App.VIEW_EUCLIDIAN3D);
                host3.add(p3, BorderLayout.CENTER);
                JFrame f3 = new JFrame("baseline-3d"); f3.add(host3); f3.setSize(620, 870); f3.setLocation(900, 0); f3.setVisible(true);
                app3D.getGgbApi().evalCommand("A = (1, 2, 3)");   // same initial 3D state as the RCP host
                h[0] = panel.getGeoGebraAPI(); h[1] = app3D.getGgbApi(); h[2] = app;
                System.out.println("[GeoGebraPlus] baseline ready; ggb=" + panel.getGeoGebraAPI().getVersion());
            } catch (Exception e) { throw new RuntimeException(e); }
        });
        Thread.sleep(Long.getLong("ggbplus.scenarioDelayMs", 4000L));
        new ScenarioScript(h[0], h[1], h[2], System.out).runFile(Path.of(a[0]), t -> {
            try { SwingUtilities.invokeAndWait(t); } catch (Exception e) { throw new IllegalStateException(e); } });
        System.exit(0);
    }
}
