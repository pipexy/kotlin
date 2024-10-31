// VideoProcessingPipeline.kt
package com.example.router.pipelines

import com.example.router.protocols.*
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import javax.inject.Inject

class VideoProcessingPipeline @Inject constructor(
    private val rtspHandler: RtspHandler,
    private val ftpHandler: FtpHandler,
    private val mediaProcessor: MediaProcessor,
    private val metrics: MetricsCollector
) {
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private val processingJobs = ConcurrentHashMap<String, Job>()

    data class PipelineConfig(
        val sourceUri: String,
        val targetUri: String,
        val segmentDuration: Int = 60,          // seconds
        val retentionPeriod: Int = 7,           // days
        val compression: CompressionConfig = CompressionConfig(),
        val metadata: MetadataConfig = MetadataConfig()
    )

    data class CompressionConfig(
        val codec: String = "h264",
        val quality: Int = 23,                  // Lower is better
        val bitrate: String = "2M",
        val resolution: String = "1280x720"
    )

    data class MetadataConfig(
        val includeTimestamp: Boolean = true,
        val includeCameraId: Boolean = true,
        val customMetadata: Map<String, String> = emptyMap()
    )

    fun startPipeline(config: PipelineConfig) {
        val pipelineId = generatePipelineId()

        val job = scope.launch {
            try {
                processPipeline(pipelineId, config)
            } catch (e: Exception) {
                metrics.recordError(pipelineId, "pipeline_error", e)
                throw e
            }
        }

        processingJobs[pipelineId] = job
        metrics.pipelineStarted(pipelineId)
    }

    private suspend fun processPipeline(pipelineId: String, config: PipelineConfig) {
        val channel = Channel<VideoSegment>(Channel.UNLIMITED)

        // Start RTSP stream processing
        launch {
            rtspHandler.startReceiving(config.sourceUri, channel)
                .onEach { segment ->
                    metrics.recordMetric(pipelineId, "segment_received", 1)
                }
                .catch { e ->
                    metrics.recordError(pipelineId, "rtsp_error", e)
                }
                .collect()
        }

        // Process and upload segments
        channel.consumeAsFlow()
            .buffer(Channel.UNLIMITED)
            .map { segment -> processSegment(segment, config) }
            .filter { it.size > 0 }
            .collect { processedSegment ->
                uploadSegment(processedSegment, config)
                metrics.recordMetric(pipelineId, "segment_processed", 1)
            }
    }

    private suspend fun processSegment(
        segment: VideoSegment,
        config: PipelineConfig
    ): ProcessedSegment = coroutineScope {
        metrics.timeOperation("segment_processing") {
            mediaProcessor.processSegment(segment) {
                // Configure FFmpeg processing
                withCodec(config.compression.codec)
                withBitrate(config.compression.bitrate)
                withResolution(config.compression.resolution)
                withQuality(config.compression.quality)

                // Add metadata
                if (config.metadata.includeTimestamp) {
                    withTimestamp()
                }
                if (config.metadata.includeCameraId) {
                    withCameraId(extractCameraId(config.sourceUri))
                }
                config.metadata.customMetadata.forEach { (key, value) ->
                    withMetadata(key, value)
                }
            }
        }
    }

    private suspend fun uploadSegment(
        segment: ProcessedSegment,
        config: PipelineConfig
    ) {
        val targetPath = generateTargetPath(config)
        metrics.timeOperation("segment_upload") {
            ftpHandler.send(targetPath, segment.data)
        }
    }

    private fun generateTargetPath(config: PipelineConfig): String {
        val timestamp = LocalDateTime.now()
            .format(DateTimeFormatter.ofPattern("yyyy/MM/dd/HH/mm"))
        val cameraId = extractCameraId(config.sourceUri)
        return "${config.targetUri}/$cameraId/$timestamp.mp4"
    }

    fun stopPipeline(pipelineId: String) {
        processingJobs[pipelineId]?.cancel()
        processingJobs.remove(pipelineId)
        metrics.pipelineStopped(pipelineId)
    }

    private fun generatePipelineId(): String =
        "pipeline-${System.currentTimeMillis()}"

    private fun extractCameraId(uri: String): String =
        uri.substringAfterLast("/").substringBefore("?")
}

// MediaProcessor.kt
class MediaProcessor @Inject constructor(
    private val ffmpeg: FFmpegWrapper,
    private val metrics: MetricsCollector
) {
    suspend fun processSegment(
        segment: VideoSegment,
        configuration: FFmpegBuilder.() -> Unit
    ): ProcessedSegment = coroutineScope {
        val builder = FFmpegBuilder().apply(configuration)

        metrics.timeOperation("ffmpeg_processing") {
            ffmpeg.process(segment.data, builder.build())
        }
    }

    class FFmpegBuilder {
        private val commands = mutableListOf<String>()

        fun withCodec(codec: String) {
            commands.add("-c:v")
            commands.add(codec)
        }

        fun withBitrate(bitrate: String) {
            commands.add("-b:v")
            commands.add(bitrate)
        }

        fun withResolution(resolution: String) {
            commands.add("-s")
            commands.add(resolution)
        }

        fun withQuality(crf: Int) {
            commands.add("-crf")
            commands.add(crf.toString())
        }

        fun withTimestamp() {
            commands.add("-vf")
            commands.add("drawtext=text='%{localtime}':x=10:y=10:fontsize=24:fontcolor=white")
        }

        fun withCameraId(cameraId: String) {
            commands.add("-metadata")
            commands.add("camera_id=$cameraId")
        }

        fun withMetadata(key: String, value: String) {
            commands.add("-metadata")
            commands.add("$key=$value")
        }

        fun build(): List<String> = commands.toList()
    }
}

// Usage example in Router configuration
class RouterConfig {
    fun configurePipelines() {
        val pipeline = VideoProcessingPipeline(
            rtspHandler = RtspHandler(),
            ftpHandler = FtpHandler(),
            mediaProcessor = MediaProcessor(
                ffmpeg = FFmpegWrapper(),
                metrics = MetricsCollector()
            ),
            metrics = MetricsCollector()
        )

        // Configure and start pipeline
        pipeline.startPipeline(
            PipelineConfig(
                sourceUri = "rtsp://camera.example.com:554/stream1",
                targetUri = "ftp://storage.example.com/videos",
                segmentDuration = 60,
                compression = CompressionConfig(
                    codec = "h264",
                    quality = 23,
                    bitrate = "2M",
                    resolution = "1280x720"
                ),
                metadata = MetadataConfig(
                    includeTimestamp = true,
                    includeCameraId = true,
                    customMetadata = mapOf(
                        "location" to "entrance",
                        "camera_type" to "dome"
                    )
                )
            )
        )
    }
}