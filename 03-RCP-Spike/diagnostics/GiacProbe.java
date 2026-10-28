import javagiac.context;
import javagiac.gen;

public final class GiacProbe {
    public static void main(String[] args) {
        System.out.println("Java=" + System.getProperty("java.runtime.version"));
        System.loadLibrary("javagiac64");
        context c = new context();
        for (String expression : new String[] {"1+1", "caseval(1+1)", "caseval(expand((x+1)^2))", "expand((x+1)^2)"}) {
            gen g = new gen(expression, c);
            gen r = g.eval(1, c);
            System.out.println("GIAC " + expression + " => " + r.print(c));
        }
    }
}
