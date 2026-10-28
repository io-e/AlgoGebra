import com.jogamp.opengl.GLProfile;

public final class NativeProbe {
    public static void main(String[] args) {
        System.out.println("Java=" + System.getProperty("java.runtime.version"));
        if (args.length > 0 && args[0].equals("jogl-preload")) {
            for (String name : new String[] {"gluegen_rt", "nativewindow_awt", "nativewindow_win32", "newt_head", "jogl_desktop", "jogl_mobile"}) {
                System.loadLibrary(name);
                System.out.println("preloaded=" + name);
            }
        }
        System.out.println("TCCL=" + Thread.currentThread().getContextClassLoader());
        System.out.println("GLProfileLoader=" + GLProfile.class.getClassLoader());
        System.out.println(GLProfile.glAvailabilityToString());
        System.out.println("GL_DEFAULT=" + GLProfile.getDefault());
    }
}
