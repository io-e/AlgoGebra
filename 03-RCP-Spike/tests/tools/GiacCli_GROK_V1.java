// GROK_V1 - GiacCli: evaluate one expression with the javagiac JNI shipped in the RCP image (no GeoGebra UI).
// Usage: java -Dgiac.lib=/path/libjavagiac64.so|javagiac64.dll -cp <giac.jni bundle> GiacCli_GROK_V1 "<expr>"
public final class GiacCli_GROK_V1 {
    public static void main(String[] a) {
        System.load(System.getProperty("giac.lib"));
        javagiac.context c = new javagiac.context();
        System.out.println(new javagiac.gen(a[0], c).eval(1, c).print(c));
    }
}
