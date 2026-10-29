package org.geogebra.plus.compute.api;

import java.nio.file.Path;
import java.time.Duration;
import java.util.Objects;

/** Per-call settings. A call is independent; engines do not retain a session. */
public final class ComputeContext {

    private static final ComputeContext DEFAULT = new ComputeContext(
            Duration.ofSeconds(30), 20, 8, 1, 800, 600,
            defaultTempDirectory());

    private final Duration timeout;
    private final int precision;
    private final int seriesLength;
    private final long randomSeed;
    private final int plotWidth;
    private final int plotHeight;
    private final Path tempDirectory;

    public ComputeContext(Duration timeout, int precision, int seriesLength, long randomSeed,
            int plotWidth, int plotHeight, Path tempDirectory) {
        this.timeout = Objects.requireNonNull(timeout, "timeout");
        this.tempDirectory = Objects.requireNonNull(tempDirectory, "tempDirectory");
        if (timeout.isZero() || timeout.isNegative() || timeout.compareTo(Duration.ofDays(1)) > 0) {
            throw new IllegalArgumentException("timeout must be greater than zero and at most one day");
        }
        if (precision < 1 || precision > 100_000) {
            throw new IllegalArgumentException("precision must be between 1 and 100000");
        }
        if (seriesLength < 1 || seriesLength > 10_000) {
            throw new IllegalArgumentException("seriesLength must be between 1 and 10000");
        }
        if (randomSeed < 0 || randomSeed > 0x7fff_ffffL) {
            throw new IllegalArgumentException("randomSeed must be between 0 and 2147483647");
        }
        if (plotWidth < 1 || plotWidth > 4096 || plotHeight < 1 || plotHeight > 4096) {
            throw new IllegalArgumentException("plot dimensions must be between 1 and 4096 pixels");
        }
        this.precision = precision;
        this.seriesLength = seriesLength;
        this.randomSeed = randomSeed;
        this.plotWidth = plotWidth;
        this.plotHeight = plotHeight;
    }

    public static ComputeContext defaults() {
        return DEFAULT;
    }

    private static Path defaultTempDirectory() {
        String configured = System.getProperty("ggbplus.tempDirectory");
        if (configured != null && !configured.isBlank()) {
            return Path.of(configured);
        }
        return Path.of(System.getProperty("java.io.tmpdir"), "GeoGebraPlus", "external-engines");
    }

    public Duration timeout() {
        return timeout;
    }

    public int precision() {
        return precision;
    }

    public int seriesLength() {
        return seriesLength;
    }

    public long randomSeed() {
        return randomSeed;
    }

    public int plotWidth() {
        return plotWidth;
    }

    public int plotHeight() {
        return plotHeight;
    }

    public Path tempDirectory() {
        return tempDirectory;
    }
}
