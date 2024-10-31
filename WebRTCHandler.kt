// WebRTCHandler.kt
class WebRTCHandler : ProtocolHandler {
    private val signaling = WebRTCSignaling()
    private val peerConnections = ConcurrentHashMap<String, RTCPeerConnection>()

    override suspend fun startReceiving(uri: String, channel: Channel<ByteArray>) {
        signaling.connect(uri)

        signaling.onOffer { sessionDescription ->
            val peerConnection = createPeerConnection()
            peerConnection.ontrack = { event ->
                launch {
                    event.streams.forEach { stream ->
                        stream.getTracks().forEach { track ->
                            channel.send(track.getBytes())
                        }
                    }
                }
            }
            peerConnection.setRemoteDescription(sessionDescription)
            // Send answer
            val answer = peerConnection.createAnswer()
            signaling.sendAnswer(answer)
        }
    }

    override suspend fun send(uri: String, message: ByteArray) {
        val peerConnection = createPeerConnection()
        val dataChannel = peerConnection.createDataChannel("data")
        dataChannel.send(message)
    }

    private fun createPeerConnection(): RTCPeerConnection {
        return RTCPeerConnection(
            iceServers = listOf(
                IceServer("stun:stun.router:3478"),
                IceServer(
                    "turn:turn.router:3478",
                    username = config.turnUsername,
                    credential = config.turnPassword
                )
            )
        )
    }
}

// GrpcHandler.kt
class GrpcHandler : ProtocolHandler {
    private val server = ServerBuilder.forPort(9000)
        .useTransportSecurity(certFile, keyFile)
        .addService(RouterService())
        .build()

    override suspend fun startReceiving(uri: String, channel: Channel<ByteArray>) {
        server.start()

        // Handle incoming streams
        RouterService().streamData { request ->
            channel.send(request.toByteArray())
        }
    }

    override suspend fun send(uri: String, message: ByteArray) {
        val stub = RouterServiceGrpc.newStub(
            ManagedChannelBuilder.forTarget(uri)
                .useTransportSecurity()
                .build()
        )

        stub.sendData(message.toRequest())
    }
}

// SecureWebSocketHandler.kt
class SecureWebSocketHandler : ProtocolHandler {
    private val server = WebSocketServer(8443) {
        ssl {
            keyStore = loadKeyStore("/certs/keystore.jks")
            keyStorePassword = config.keystorePassword
        }
    }

    override suspend fun startReceiving(uri: String, channel: Channel<ByteArray>) {
        server.start()

        server.onMessage { socket, message ->
            channel.send(message.toByteArray())
        }
    }

    override suspend fun send(uri: String, message: ByteArray) {
        val client = WebSocketClient(uri) {
            ssl {
                trustStore = loadTrustStore("/certs/truststore.jks")
                trustStorePassword = config.truststorePassword
            }
        }

        client.connect()
        client.send(message)
    }
}