// GROK_V1 - EngineCli: drive one AlgoGebra external engine from the command line.
// Usage: java EngineCli_GROK_V1 <pari|maxima|gnuplot> <timeoutSeconds>   (command read from stdin, UTF-8)
// Output (stdout, UTF-8), one line:  OK\t<text> | ART\t<path>\t<bytes>\t<deletedAfterClose> | ERR\t<Class>: <message>
// Exit: 0 OK/ART, 3 ERR, 2 usage.
import java.io.PrintStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import org.geogebra.plus.compute.api.ComputeContext;
import org.geogebra.plus.compute.api.ComputeResult;
import org.geogebra.plus.compute.api.ExternalComputeService;

public final class EngineCli_GROK_V1 {
    public static void main(String[] a) throws Exception {
        PrintStream out = new PrintStream(System.out, true, StandardCharsets.UTF_8);
        if (a.length < 2) { out.println("usage: EngineCli <engine> <timeoutSeconds>"); System.exit(2); }
        String cmd = new String(System.in.readAllBytes(), StandardCharsets.UTF_8).replaceAll("\\R+$", "");
        ExternalComputeService e = switch (a[0]) {
            case "pari" -> new org.geogebra.plus.engine.pari.PariGPEngine();
            case "maxima" -> new org.geogebra.plus.engine.maxima.MaximaEngine();
            case "gnuplot" -> new org.geogebra.plus.engine.gnuplot.GnuplotEngine();
            default -> throw new IllegalArgumentException(a[0]);
        };
        ComputeContext ctx = new ComputeContext(Duration.ofSeconds(Long.parseLong(a[1])), 20, 8, 1, 800, 600,
                Path.of(System.getProperty("java.io.tmpdir")));
        try {
            ComputeResult r = e.eval(cmd, ctx);
            if (r.artifact().isPresent()) {
                Path p = r.artifact().get(); long n = Files.size(p);
                byte[] h = Files.readAllBytes(p);
                String dim = h.length > 24 ? (((h[16]&255)<<24|(h[17]&255)<<16|(h[18]&255)<<8|(h[19]&255)) + "x"
                        + ((h[20]&255)<<24|(h[21]&255)<<16|(h[22]&255)<<8|(h[23]&255))) : "?";
                r.close();
                out.println("ART\t" + p + "\t" + n + "\t" + dim + "\t" + !Files.exists(p));
            } else {
                out.println("OK\t" + r.text().replace("\n", "\\n")); r.close();
            }
        } catch (Exception ex) {
            out.println("ERR\t" + ex.getClass().getSimpleName() + ": " + String.valueOf(ex.getMessage()).replace("\n", "\\n"));
            System.exit(3);
        }
    }
}
