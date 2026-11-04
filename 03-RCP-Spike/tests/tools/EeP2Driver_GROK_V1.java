/* GROK_V1 — EE-P2c driver: run one command through the Java SubprocessEngine adapters (no production change). */
import java.nio.file.*;
import java.time.Duration;
import org.geogebra.plus.compute.api.*;
import org.geogebra.plus.compute.runtime.SubprocessEngine;

public final class EeP2Driver_GROK_V1 {
    public static void main(String[] a) throws Exception {
        String engine = a[0];
        String cmd = a[1].replace("\\n", "\n");
        SubprocessEngine e = switch (engine) {
            case "pari" -> new org.geogebra.plus.engine.pari.PariGPEngine();
            case "maxima" -> new org.geogebra.plus.engine.maxima.MaximaEngine();
            case "gnuplot" -> new org.geogebra.plus.engine.gnuplot.GnuplotEngine();
            default -> null;
        };
        if (e == null) { System.out.println("NA|no Java adapter for " + engine); return; }
        ComputeContext ctx = new ComputeContext(Duration.ofSeconds(60), 20, 8, 1, 800, 600,
                Path.of(System.getProperty("java.io.tmpdir")));
        try (ComputeResult r = e.eval(cmd, ctx)) {
            if (r.artifact().isPresent()) {
                byte[] b = Files.readAllBytes(r.artifact().get());
                int w = ((b[16]&255)<<24)|((b[17]&255)<<16)|((b[18]&255)<<8)|(b[19]&255);
                int h = ((b[20]&255)<<24)|((b[21]&255)<<16)|((b[22]&255)<<8)|(b[23]&255);
                System.out.println("OK|PNG " + w + "x" + h);
            } else System.out.println("OK|" + r.text().replace("\n", "\\n"));
        } catch (ExternalComputeException x) {
            System.out.println("ERR|" + x.code());
        }
    }
}
