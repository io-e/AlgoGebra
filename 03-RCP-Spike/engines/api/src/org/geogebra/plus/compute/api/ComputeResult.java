package org.geogebra.plus.compute.api;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import java.util.Objects;
import java.util.Optional;

/** Result of one external computation. Close image results when the UI is done. */
public final class ComputeResult implements AutoCloseable {

    private final String engineId;
    private final String text;
    private final Path artifact;
    private final String mediaType;
    private final Duration elapsed;
    private final Path ownedArtifactDirectory;

    private ComputeResult(String engineId, String text, Path artifact, String mediaType,
            Duration elapsed, Path ownedArtifactDirectory) {
        this.engineId = Objects.requireNonNull(engineId, "engineId");
        this.text = text == null ? "" : text;
        this.artifact = artifact;
        this.mediaType = mediaType;
        this.elapsed = Objects.requireNonNull(elapsed, "elapsed");
        this.ownedArtifactDirectory = ownedArtifactDirectory;
    }

    public static ComputeResult text(String engineId, String text, Duration elapsed) {
        return new ComputeResult(engineId, text, null, null, elapsed, null);
    }

    public static ComputeResult image(String engineId, Path artifact, String mediaType,
            Duration elapsed, Path ownedArtifactDirectory) {
        return new ComputeResult(engineId, "", Objects.requireNonNull(artifact, "artifact"),
                Objects.requireNonNull(mediaType, "mediaType"), elapsed,
                Objects.requireNonNull(ownedArtifactDirectory, "ownedArtifactDirectory"));
    }

    public String engineId() {
        return engineId;
    }

    public String text() {
        return text;
    }

    public Optional<Path> artifact() {
        return Optional.ofNullable(artifact);
    }

    public Optional<String> mediaType() {
        return Optional.ofNullable(mediaType);
    }

    public Duration elapsed() {
        return elapsed;
    }

    /** Deletes an engine-owned image and its per-call directory. */
    @Override
    public void close() throws IOException {
        if (artifact != null) {
            Files.deleteIfExists(artifact);
        }
        if (ownedArtifactDirectory != null) {
            Files.deleteIfExists(ownedArtifactDirectory);
        }
    }
}
