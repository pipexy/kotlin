import os
import logging
import grpc
from concurrent import futures
import cv2
import numpy as np
import torch
from torchvision.models import detection

import video_pb2
import video_pb2_grpc
import common_pb2

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class ObjectDetectorService(video_pb2_grpc.ObjectDetectorServicer):
    def __init__(self):
        self.device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
        self.model = None
        self.confidence_threshold = float(os.getenv('CONFIDENCE_THRESHOLD', '0.5'))
        self.initialized = False
        self._load_model()

    def _load_model(self):
        try:
            # Load YOLO model
            self.model = detection.fasterrcnn_resnet50_fpn(pretrained=True)
            self.model.to(self.device)
            self.model.eval()
            self.initialized = True
            logger.info("Model loaded successfully")
        except Exception as e:
            logger.error(f"Failed to load model: {str(e)}")
            raise

    async def Configure(self, request, context):
        try:
            self.confidence_threshold = float(request.parameters.get(
                'confidence_threshold',
                self.confidence_threshold
            ))
            return common_pb2.ConfigResponse(
                success=True,
                message="Object detector configured successfully"
            )
        except Exception as e:
            return common_pb2.ConfigResponse(
                success=False,
                message=f"Configuration failed: {str(e)}"
            )

    async def Detect(self, request, context):
        if not self.initialized:
            context.abort(grpc.StatusCode.FAILED_PRECONDITION, "Model not initialized")
            return

        try:
            # Convert frame data to numpy array
            nparr = np.frombuffer(request.frame.data, np.uint8)
            img = nparr.reshape((request.height, request.width, -1))

            # Prepare image for model
            img_tensor = torch.from_numpy(img).permute(2, 0, 1).float().div(255.0)
            img_tensor = img_tensor.unsqueeze(0).to(self.device)

            # Perform detection
            with torch.no_grad():
                predictions = self.model(img_tensor)

            # Process detections
            detections = []
            for score, label, box in zip(
                    predictions[0]['scores'],
                    predictions[0]['labels'],
                    predictions[0]['boxes']
            ):
                if score < self.confidence_threshold:
                    continue

                x1, y1, x2, y2 = box.tolist()
                detections.append(video_pb2.Detection(
                    object_class=str(label.item()),
                    confidence=score.item(),
                    bbox=video_pb2.BoundingBox(
                        x=x1,
                        y=y1,
                        width=x2-x1,
                        height=y2-y1
                    )
                ))

            # Draw detections on frame
            for detection in detections:
                cv2.rectangle(
                    img,
                    (int(detection.bbox.x), int(detection.bbox.y)),
                    (int(detection.bbox.x + detection.bbox.width),
                     int(detection.bbox.y + detection.bbox.height)),
                    (0, 255, 0),
                    2
                )

            return video_pb2.DetectionResult(
                detections=detections,
                frame=video_pb2.VideoFrame(
                    frame=common_pb2.Frame(
                        data=img.tobytes(),
                        timestamp=request.frame.timestamp,
                        format=request.pixel_format,
                        metadata=request.frame.metadata
                    ),
                    width=request.width,
                    height=request.height,
                    pixel_format=request.pixel_format
                )
            )

        except Exception as e:
            logger.error(f"Error in detection: {str(e)}")
            context.abort(grpc.StatusCode.INTERNAL, str(e))

def serve():
    port = int(os.getenv('GRPC_PORT', '50061'))
    server = grpc.aio.server(futures.ThreadPoolExecutor(max_workers=10))
    video_pb2_grpc.add_ObjectDetectorServicer_to_server(
        ObjectDetectorService(), server
    )
    server.add_insecure_port(f'[::]:{port}')
    return server

async def main():
    server = serve()
    logger.info(f"Starting object detector service on port {os.getenv('GRPC_PORT', '50061')}")
    await server.start()
    await server.wait_for_termination()

if __name__ == '__main__':
    import asyncio
    asyncio.run(main())