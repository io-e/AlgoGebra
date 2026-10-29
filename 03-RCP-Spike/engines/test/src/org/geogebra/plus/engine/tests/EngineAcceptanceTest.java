package org.geogebra.plus.engine.tests;

import org.geogebra.plus.compute.runtime.SubprocessEngineTests;
import org.geogebra.plus.engine.gnuplot.GnuplotEngineTests;
import org.geogebra.plus.engine.maxima.MaximaEngineTests;
import org.geogebra.plus.engine.pari.PariEngineTests;

/** Dependency-free Windows/Linux smoke and acceptance test entry point. */
public final class EngineAcceptanceTest {

    private EngineAcceptanceTest() {
    }

    public static void main(String[] args) throws Exception {
        SubprocessEngineTests.run();
        PariEngineTests.run();
        MaximaEngineTests.run();
        GnuplotEngineTests.run();
        System.out.println("External engine tests completed; any unavailable-binary acceptance is explicitly marked SKIP.");
    }
}
