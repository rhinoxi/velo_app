package io.flutter.plugins.camera;

import static android.view.OrientationEventListener.ORIENTATION_UNKNOWN;
import static io.flutter.plugins.camera.CameraUtils.computeBestPreviewSize;

import android.annotation.SuppressLint;
import android.annotation.TargetApi;
import android.app.Activity;
import android.content.Context;
import android.graphics.ImageFormat;
import android.graphics.SurfaceTexture;
import android.hardware.camera2.CameraAccessException;
import android.hardware.camera2.CameraCaptureSession;
import android.hardware.camera2.CameraCharacteristics;
import android.hardware.camera2.CameraDevice;
import android.hardware.camera2.CameraManager;
import android.hardware.camera2.CameraMetadata;
import android.hardware.camera2.CaptureFailure;
import android.hardware.camera2.CaptureRequest;
import android.hardware.camera2.params.OutputConfiguration;
import android.hardware.camera2.params.SessionConfiguration;
import android.hardware.camera2.params.StreamConfigurationMap;
import android.media.CamcorderProfile;
import android.media.Image;
import android.media.ImageReader;
import android.media.MediaRecorder;
import android.os.Build;
import android.os.Build.VERSION;
import android.os.Build.VERSION_CODES;
import android.util.Size;
import android.view.OrientationEventListener;
import android.view.Surface;
import androidx.annotation.NonNull;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugins.camera.media.MediaRecorderBuilder;
import io.flutter.view.TextureRegistry.SurfaceTextureEntry;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.Executors;

import org.opencv.core.Mat;
import org.opencv.core.Point;
import org.opencv.core.MatOfDouble;
import org.opencv.core.MatOfByte;
import org.opencv.core.MatOfFloat;
import org.opencv.core.MatOfPoint;
import org.opencv.core.MatOfPoint2f;
import org.opencv.core.Core;
import org.opencv.core.CvType;
import org.opencv.video.Video;
import org.opencv.calib3d.Calib3d;
import org.opencv.imgproc.Imgproc;

public class Camera {
  private final SurfaceTextureEntry flutterTexture;
  private final CameraManager cameraManager;
  private final OrientationEventListener orientationEventListener;
  private final boolean isFrontFacing;
  private final int sensorOrientation;
  private final String cameraName;
  private final Size captureSize;
  private final Size previewSize;
  private final boolean enableAudio;

  private CameraDevice cameraDevice;
  private CameraCaptureSession cameraCaptureSession;
  private ImageReader pictureImageReader;
  private ImageReader imageStreamReader;
  private DartMessenger dartMessenger;
  private CaptureRequest.Builder captureRequestBuilder;
  private MediaRecorder mediaRecorder;
  private boolean recordingVideo;
  private CamcorderProfile recordingProfile;
  private int currentOrientation = ORIENTATION_UNKNOWN;

  private final Mat t0;
  private final Mat fixedT0;
  private final Mat t1;
  private final Mat t2;
  private final Mat fixedT2;
  private final Mat deltaT01;
  private final Mat deltaT02;
  private final Mat deltaT12;
  private final Mat thT01;
  private final Mat thT02;
  private final Mat thT12;
  private final double threshFactor = 3;
  private final double minArea = 40;  // 连通区域最小面积
  private final double maxArea = 400;  // 连通区域最大面积
  private final double minWhRatio = 0.3; // 连通区域最小宽高比
  private final double maxWhRatio = 3; // 连通区域最大宽高比
  private final double maxEmptyRatio = 3; // 连通区域矩形面积 与 实际面积 最大比值
  // goodFeaturesToTrack 参数
  private final int maxCorners = 10;
  private final double qualityLevel = 0.01;
  private final double minDistance = 30;

  private final int cvFrameInterval;
  private int frameCounter = 0;
  private int zoneLeft;
  private int zoneRight;
  private int zoneWidth;
  private int zoneTop;
  private int zoneBottom;
  private int zoneHeight;
  private int cvCount = 0;

  // Mirrors camera.dart
  public enum ResolutionPreset {
    low,
    medium,
    high,
    veryHigh,
    ultraHigh,
    max,
  }

  public Camera(
      final Activity activity,
      final SurfaceTextureEntry flutterTexture,
      final DartMessenger dartMessenger,
      final String cameraName,
      final String resolutionPreset,
      final boolean enableAudio,
      final int cvFrameInterval)
      throws CameraAccessException {
    if (activity == null) {
      throw new IllegalStateException("No activity available!");
    }
    this.cameraName = cameraName;
    this.enableAudio = enableAudio;
    this.flutterTexture = flutterTexture;
    this.dartMessenger = dartMessenger;
    this.cameraManager = (CameraManager) activity.getSystemService(Context.CAMERA_SERVICE);
    this.cvFrameInterval = cvFrameInterval;
    System.out.format("3343a1 cvFrameInterval: %d\n", cvFrameInterval);
    orientationEventListener =
        new OrientationEventListener(activity.getApplicationContext()) {
          @Override
          public void onOrientationChanged(int i) {
            if (i == ORIENTATION_UNKNOWN) {
              return;
            }
            // Convert the raw deg angle to the nearest multiple of 90.
            currentOrientation = (int) Math.round(i / 90.0) * 90;
          }
        };
    orientationEventListener.enable();

    CameraCharacteristics characteristics = cameraManager.getCameraCharacteristics(cameraName);
    StreamConfigurationMap streamConfigurationMap =
        characteristics.get(CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP);
    //noinspection ConstantConditions
    sensorOrientation = characteristics.get(CameraCharacteristics.SENSOR_ORIENTATION);
    //noinspection ConstantConditions
    isFrontFacing =
        characteristics.get(CameraCharacteristics.LENS_FACING) == CameraMetadata.LENS_FACING_FRONT;
    ResolutionPreset preset = ResolutionPreset.valueOf(resolutionPreset);
    recordingProfile =
        CameraUtils.getBestAvailableCamcorderProfileForResolutionPreset(cameraName, preset);
    captureSize = new Size(recordingProfile.videoFrameWidth, recordingProfile.videoFrameHeight);
    previewSize = computeBestPreviewSize(cameraName, preset);

    int height = previewSize.getHeight();
    int width = previewSize.getWidth();

    int quarterWidth = width / 4;
    int quarterHeight = height / 4;

    zoneLeft = quarterWidth;
    zoneRight = width - quarterWidth; // exclude
    zoneWidth = zoneRight - zoneLeft;
    zoneTop = quarterHeight;
    zoneBottom = height - quarterHeight;
    zoneHeight = zoneBottom - zoneTop;

    t0 = new Mat(zoneHeight, zoneWidth, CvType.CV_8UC1);
    fixedT0 = new Mat(zoneHeight, zoneWidth, CvType.CV_8UC1);
    t1 = new Mat(zoneHeight, zoneWidth, CvType.CV_8UC1);
    t2 = new Mat(zoneHeight, zoneWidth, CvType.CV_8UC1);
    fixedT2 = new Mat(zoneHeight, zoneWidth, CvType.CV_8UC1);
    deltaT01 = new Mat(zoneHeight, zoneWidth, CvType.CV_8UC1);
    deltaT02 = new Mat(zoneHeight, zoneWidth, CvType.CV_8UC1);
    deltaT12 = new Mat(zoneHeight, zoneWidth, CvType.CV_8UC1);
    thT01 = new Mat(zoneHeight, zoneWidth, CvType.CV_8UC1);
    thT02 = new Mat(zoneHeight, zoneWidth, CvType.CV_8UC1);
    thT12 = new Mat(zoneHeight, zoneWidth, CvType.CV_8UC1);
  }

  private void prepareMediaRecorder(String outputFilePath) throws IOException {
    if (mediaRecorder != null) {
      mediaRecorder.release();
    }

    mediaRecorder =
        new MediaRecorderBuilder(recordingProfile, outputFilePath)
            .setEnableAudio(enableAudio)
            .setMediaOrientation(getMediaOrientation())
            .build();
  }

  @SuppressLint("MissingPermission")
  public void open(@NonNull final Result result) throws CameraAccessException {
    pictureImageReader =
        ImageReader.newInstance(
            captureSize.getWidth(), captureSize.getHeight(), ImageFormat.JPEG, 2);

    // Used to steam image byte data to dart side.
    imageStreamReader =
        ImageReader.newInstance(
            previewSize.getWidth(), previewSize.getHeight(), ImageFormat.YUV_420_888, 2);

    cameraManager.openCamera(
        cameraName,
        new CameraDevice.StateCallback() {
          @Override
          public void onOpened(@NonNull CameraDevice device) {
            cameraDevice = device;
            try {
              startPreview();
            } catch (CameraAccessException e) {
              result.error("CameraAccess", e.getMessage(), null);
              close();
              return;
            }
            Map<String, Object> reply = new HashMap<>();
            reply.put("textureId", flutterTexture.id());
            reply.put("previewWidth", previewSize.getWidth());
            reply.put("previewHeight", previewSize.getHeight());
            result.success(reply);
          }

          @Override
          public void onClosed(@NonNull CameraDevice camera) {
            dartMessenger.sendCameraClosingEvent();
            super.onClosed(camera);
          }

          @Override
          public void onDisconnected(@NonNull CameraDevice cameraDevice) {
            close();
            dartMessenger.send(DartMessenger.EventType.ERROR, "The camera was disconnected.");
          }

          @Override
          public void onError(@NonNull CameraDevice cameraDevice, int errorCode) {
            close();
            String errorDescription;
            switch (errorCode) {
              case ERROR_CAMERA_IN_USE:
                errorDescription = "The camera device is in use already.";
                break;
              case ERROR_MAX_CAMERAS_IN_USE:
                errorDescription = "Max cameras in use";
                break;
              case ERROR_CAMERA_DISABLED:
                errorDescription = "The camera device could not be opened due to a device policy.";
                break;
              case ERROR_CAMERA_DEVICE:
                errorDescription = "The camera device has encountered a fatal error";
                break;
              case ERROR_CAMERA_SERVICE:
                errorDescription = "The camera service has encountered a fatal error.";
                break;
              default:
                errorDescription = "Unknown camera error";
            }
            dartMessenger.send(DartMessenger.EventType.ERROR, errorDescription);
          }
        },
        null);
  }

  private void writeToFile(ByteBuffer buffer, File file) throws IOException {
    try (FileOutputStream outputStream = new FileOutputStream(file)) {
      while (0 < buffer.remaining()) {
        outputStream.getChannel().write(buffer);
      }
    }
  }

  SurfaceTextureEntry getFlutterTexture() {
    return flutterTexture;
  }

  public void takePicture(String filePath, @NonNull final Result result) {
    final File file = new File(filePath);

    if (file.exists()) {
      result.error(
          "fileExists", "File at path '" + filePath + "' already exists. Cannot overwrite.", null);
      return;
    }

    pictureImageReader.setOnImageAvailableListener(
        reader -> {
          try (Image image = reader.acquireLatestImage()) {
            ByteBuffer buffer = image.getPlanes()[0].getBuffer();
            writeToFile(buffer, file);
            result.success(null);
          } catch (IOException e) {
            result.error("IOError", "Failed saving image", null);
          }
        },
        null);

    try {
      final CaptureRequest.Builder captureBuilder =
          cameraDevice.createCaptureRequest(CameraDevice.TEMPLATE_STILL_CAPTURE);
      captureBuilder.addTarget(pictureImageReader.getSurface());
      captureBuilder.set(CaptureRequest.JPEG_ORIENTATION, getMediaOrientation());

      cameraCaptureSession.capture(
          captureBuilder.build(),
          new CameraCaptureSession.CaptureCallback() {
            @Override
            public void onCaptureFailed(
                @NonNull CameraCaptureSession session,
                @NonNull CaptureRequest request,
                @NonNull CaptureFailure failure) {
              String reason;
              switch (failure.getReason()) {
                case CaptureFailure.REASON_ERROR:
                  reason = "An error happened in the framework";
                  break;
                case CaptureFailure.REASON_FLUSHED:
                  reason = "The capture has failed due to an abortCaptures() call";
                  break;
                default:
                  reason = "Unknown reason";
              }
              result.error("captureFailure", reason, null);
            }
          },
          null);
    } catch (CameraAccessException e) {
      result.error("cameraAccess", e.getMessage(), null);
    }
  }

  private void createCaptureSession(int templateType, Surface... surfaces)
      throws CameraAccessException {
    createCaptureSession(templateType, null, surfaces);
  }

  private void createCaptureSession(
      int templateType, Runnable onSuccessCallback, Surface... surfaces)
      throws CameraAccessException {
    // Close any existing capture session.
    closeCaptureSession();

    // Create a new capture builder.
    captureRequestBuilder = cameraDevice.createCaptureRequest(templateType);

    // Build Flutter surface to render to
    SurfaceTexture surfaceTexture = flutterTexture.surfaceTexture();
    surfaceTexture.setDefaultBufferSize(previewSize.getWidth(), previewSize.getHeight());
    Surface flutterSurface = new Surface(surfaceTexture);
    captureRequestBuilder.addTarget(flutterSurface);

    List<Surface> remainingSurfaces = Arrays.asList(surfaces);
    if (templateType != CameraDevice.TEMPLATE_PREVIEW) {
      // If it is not preview mode, add all surfaces as targets.
      for (Surface surface : remainingSurfaces) {
        captureRequestBuilder.addTarget(surface);
      }
    }

    // Prepare the callback
    CameraCaptureSession.StateCallback callback =
        new CameraCaptureSession.StateCallback() {
          @Override
          public void onConfigured(@NonNull CameraCaptureSession session) {
            try {
              if (cameraDevice == null) {
                dartMessenger.send(
                    DartMessenger.EventType.ERROR, "The camera was closed during configuration.");
                return;
              }
              cameraCaptureSession = session;
              captureRequestBuilder.set(
                  CaptureRequest.CONTROL_MODE, CameraMetadata.CONTROL_MODE_AUTO);
              cameraCaptureSession.setRepeatingRequest(captureRequestBuilder.build(), null, null);
              if (onSuccessCallback != null) {
                onSuccessCallback.run();
              }
            } catch (CameraAccessException | IllegalStateException | IllegalArgumentException e) {
              dartMessenger.send(DartMessenger.EventType.ERROR, e.getMessage());
            }
          }

          @Override
          public void onConfigureFailed(@NonNull CameraCaptureSession cameraCaptureSession) {
            dartMessenger.send(
                DartMessenger.EventType.ERROR, "Failed to configure camera session.");
          }
        };

    // Start the session
    if (VERSION.SDK_INT >= VERSION_CODES.P) {
      // Collect all surfaces we want to render to.
      List<OutputConfiguration> configs = new ArrayList<>();
      configs.add(new OutputConfiguration(flutterSurface));
      for (Surface surface : remainingSurfaces) {
        configs.add(new OutputConfiguration(surface));
      }
      createCaptureSessionWithSessionConfig(configs, callback);
    } else {
      // Collect all surfaces we want to render to.
      List<Surface> surfaceList = new ArrayList<>();
      surfaceList.add(flutterSurface);
      surfaceList.addAll(remainingSurfaces);
      createCaptureSession(surfaceList, callback);
    }
  }

  @TargetApi(VERSION_CODES.P)
  private void createCaptureSessionWithSessionConfig(
      List<OutputConfiguration> outputConfigs, CameraCaptureSession.StateCallback callback)
      throws CameraAccessException {
    cameraDevice.createCaptureSession(
        new SessionConfiguration(
            SessionConfiguration.SESSION_REGULAR,
            outputConfigs,
            Executors.newSingleThreadExecutor(),
            callback));
  }

  @TargetApi(VERSION_CODES.LOLLIPOP)
  @SuppressWarnings("deprecation")
  private void createCaptureSession(
      List<Surface> surfaces, CameraCaptureSession.StateCallback callback)
      throws CameraAccessException {
    cameraDevice.createCaptureSession(surfaces, callback, null);
  }

  public void startVideoRecording(String filePath, Result result) {
    if (new File(filePath).exists()) {
      result.error("fileExists", "File at path '" + filePath + "' already exists.", null);
      return;
    }
    try {
      prepareMediaRecorder(filePath);
      recordingVideo = true;
      createCaptureSession(
          CameraDevice.TEMPLATE_RECORD, () -> mediaRecorder.start(), mediaRecorder.getSurface());
      result.success(null);
    } catch (CameraAccessException | IOException e) {
      result.error("videoRecordingFailed", e.getMessage(), null);
    }
  }

  public void stopVideoRecording(@NonNull final Result result) {
    if (!recordingVideo) {
      result.success(null);
      return;
    }

    try {
      recordingVideo = false;
      mediaRecorder.stop();
      mediaRecorder.reset();
      startPreview();
      result.success(null);
    } catch (CameraAccessException | IllegalStateException e) {
      result.error("videoRecordingFailed", e.getMessage(), null);
    }
  }

  public void pauseVideoRecording(@NonNull final Result result) {
    if (!recordingVideo) {
      result.success(null);
      return;
    }

    try {
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
        mediaRecorder.pause();
      } else {
        result.error("videoRecordingFailed", "pauseVideoRecording requires Android API +24.", null);
        return;
      }
    } catch (IllegalStateException e) {
      result.error("videoRecordingFailed", e.getMessage(), null);
      return;
    }

    result.success(null);
  }

  public void resumeVideoRecording(@NonNull final Result result) {
    if (!recordingVideo) {
      result.success(null);
      return;
    }

    try {
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
        mediaRecorder.resume();
      } else {
        result.error(
            "videoRecordingFailed", "resumeVideoRecording requires Android API +24.", null);
        return;
      }
    } catch (IllegalStateException e) {
      result.error("videoRecordingFailed", e.getMessage(), null);
      return;
    }

    result.success(null);
  }

  public void startPreview() throws CameraAccessException {
    if (pictureImageReader == null || pictureImageReader.getSurface() == null) return;

    createCaptureSession(CameraDevice.TEMPLATE_PREVIEW, pictureImageReader.getSurface());
  }

  public void startPreviewWithImageStream(EventChannel imageStreamChannel)
      throws CameraAccessException {
    createCaptureSession(CameraDevice.TEMPLATE_RECORD, imageStreamReader.getSurface());

    imageStreamChannel.setStreamHandler(
        new EventChannel.StreamHandler() {
          @Override
          public void onListen(Object o, EventChannel.EventSink imageStreamSink) {
            setImageStreamImageAvailableListener(imageStreamSink);
          }

          @Override
          public void onCancel(Object o) {
            imageStreamReader.setOnImageAvailableListener(null, null);
          }
        });
  }

  private void setImageStreamImageAvailableListener(final EventChannel.EventSink imageStreamSink) {
    imageStreamReader.setOnImageAvailableListener(
        reader -> {
          long now = System.currentTimeMillis();
          boolean doCV = false;
          if (frameCounter % cvFrameInterval == 0) {
            frameCounter = 0;
            doCV = true;
          }
          frameCounter++;
          Image img = reader.acquireLatestImage();
          if (img == null) return;

          List<Map<String, Object>> planes = new ArrayList<>();
          boolean isYLayer = true;
          for (Image.Plane plane : img.getPlanes()) {
            ByteBuffer buffer = plane.getBuffer();

            byte[] bytes = new byte[buffer.remaining()];
            buffer.get(bytes, 0, bytes.length);

            Map<String, Object> planeBuffer = new HashMap<>();
            planeBuffer.put("bytesPerRow", plane.getRowStride());
            planeBuffer.put("bytesPerPixel", plane.getPixelStride());
            planeBuffer.put("bytes", bytes);

            planes.add(planeBuffer);

            if (doCV && isYLayer) {
              byte[] subBytes = new byte[previewSize.getHeight() * zoneWidth];
              for (int i = zoneTop; i < zoneBottom; i++) {
                System.arraycopy(bytes, i * plane.getRowStride() + zoneLeft, subBytes, (i-zoneTop)*zoneWidth, zoneWidth);
              }
              isYLayer = false;
              t2.put(0, 0, subBytes);
              // System.out.format("62f208 %f\n", t2.get(200, 200)[0]);

              cvCount++;
              // 至少有前后共三帧数据时，才进行抖动校正
              if (cvCount >= 3) {
                
                // long time0 = System.currentTimeMillis();
                stabilize(t1, t0, fixedT0);
                stabilize(t1, t2, fixedT2);
                // long dt = System.currentTimeMillis() - time0;
                // System.out.format("00b1a9 stabilize cost: %d (millisecond)\n", dt);
              }
            }
          }

          Map<String, Object> imageBuffer = new HashMap<>();
          imageBuffer.put("width", img.getWidth());
          imageBuffer.put("height", img.getHeight());
          imageBuffer.put("format", img.getFormat());
          imageBuffer.put("planes", planes);
          imageBuffer.put("timeInMs", now);

          // 检测球的位置
          if (doCV) {
            Core.absdiff(fixedT0, fixedT2, deltaT02);
            Core.absdiff(t1, fixedT2, deltaT12);
            
            MatOfDouble meanT01 = new MatOfDouble();
            MatOfDouble meanT02 = new MatOfDouble();
            MatOfDouble meanT12 = new MatOfDouble();
            MatOfDouble stdT01 = new MatOfDouble();
            MatOfDouble stdT02 = new MatOfDouble();
            MatOfDouble stdT12 = new MatOfDouble();

            Core.meanStdDev(deltaT01, meanT01, stdT01);
            Core.meanStdDev(deltaT02, meanT02, stdT02);
            Core.meanStdDev(deltaT12, meanT12, stdT12);

            double[] th = {
              meanT01.toArray()[0] + threshFactor * Math.sqrt(stdT01.toArray()[0]),
              meanT02.toArray()[0] + threshFactor * Math.sqrt(stdT02.toArray()[0]),
              meanT12.toArray()[0] + threshFactor * Math.sqrt(stdT12.toArray()[0]),
            };
            // System.out.format("66823c %f:%f:%f\n", th[0], th[1], th[2]);

            Imgproc.threshold(deltaT01, thT01, th[0], 255, Imgproc.THRESH_BINARY);
            Imgproc.threshold(deltaT02, thT02, th[1], 255, Imgproc.THRESH_BINARY);
            Imgproc.threshold(deltaT12, thT12, th[2], 255, Imgproc.THRESH_BINARY);

            Mat detect = new Mat();
            Mat andThT01_12 = new Mat();
            Mat notThT02 = new Mat();
            Core.bitwise_not(thT02, notThT02);
            Core.bitwise_and(thT12, thT01, andThT01_12);
            Core.bitwise_and(andThT01_12, notThT02, detect);

            // System.out.format("1e31fe detect is all zero? %d\n", Core.countNonZero(detect));

            Mat labels = new Mat();
            Mat stats = new Mat();
            Mat centroids = new Mat();
            int n = Imgproc.connectedComponentsWithStats(detect, labels, stats, centroids, 8, CvType.CV_16U);
            // System.out.format("d6d03c N = %d\n", n);

            int rectCount = 0;
            double[] ball = new double[2];
            for (int row=0; row<stats.rows(); row++) {
              double area = stats.get(row, Imgproc.CC_STAT_AREA)[0];
              double whRatio = stats.get(row, Imgproc.CC_STAT_WIDTH)[0] / stats.get(row, Imgproc.CC_STAT_HEIGHT)[0];
              // 过滤掉面积较小或较大的连通区域
              // 过滤掉连通区域所包的面积比实际面积大很多的区域（过滤一些斜的线条）
              // 过滤横宽比特别夸张的连通区域
              if (area > minArea &&
                  area < maxArea &&
                  stats.get(row, Imgproc.CC_STAT_WIDTH)[0] * stats.get(row, Imgproc.CC_STAT_HEIGHT)[0] / area < maxEmptyRatio &&
                  whRatio > minWhRatio &&
                  whRatio < maxWhRatio) {
                // System.out.println(stats.get(row, Imgproc.CC_STAT_AREA)[0]);
                rectCount++;
                ball[0] = (centroids.get(row, 0)[0] + zoneLeft) / previewSize.getWidth();
                ball[1] = (centroids.get(row, 1)[0] + zoneTop) / previewSize.getHeight();
                if (rectCount > 1) {
                  break;
                }
              }
            }
            if (rectCount == 1) {
              imageBuffer.put("ball", ball);
            } else {
              imageBuffer.put("ball", null);
            }

            t1.copyTo(t0);
            t2.copyTo(t1);
            deltaT12.copyTo(deltaT01);
          }

          imageStreamSink.success(imageBuffer);
          img.close();

        },
        null);
  }

  private Mat calcTransformMatrix(Mat refImg, Mat origImg) {
    Mat ret = new Mat();
    MatOfPoint refCorners = new MatOfPoint();
    // long time0 = System.currentTimeMillis();
    Imgproc.goodFeaturesToTrack(refImg, refCorners, maxCorners, qualityLevel, minDistance);
    // System.out.format("72e90a goodFeaturesToTrack cost: %d (millisecond)\n", System.currentTimeMillis() - time0);
    MatOfPoint2f refCorners2f = new MatOfPoint2f(refCorners.toArray());
    MatOfPoint2f origCornersMat = new MatOfPoint2f();

    MatOfByte status = new MatOfByte();

    // time0 = System.currentTimeMillis();
    Video.calcOpticalFlowPyrLK(refImg, origImg, refCorners2f, origCornersMat, status, new MatOfFloat());
    // System.out.format("a1888a calcOpticalFlowPyrLK cost: %d (millisecond)\n", System.currentTimeMillis() - time0);
    Point[] refCornersArray = refCorners2f.toArray();
    Point[] origCornersArray = origCornersMat.toArray();

    ArrayList<Point> validRefCornersArrayList = new ArrayList<Point>();
    ArrayList<Point> validOrigCornersArrayList = new ArrayList<Point>();
    
    for (int row=0; row<status.rows(); row++) {
      if (status.get(row, 0)[0] == 0) {
        continue;
      }
      validRefCornersArrayList.add(refCornersArray[row]);
      validOrigCornersArrayList.add(origCornersArray[row]);
    }
    if (validRefCornersArrayList.size() == 0) {
      return ret;
    }
    Point[] validRefCornersArray = new Point[validRefCornersArrayList.size()];
    Point[] validOrigCornersArray = new Point[validOrigCornersArrayList.size()];
    validRefCornersArrayList.toArray(validRefCornersArray);
    validOrigCornersArrayList.toArray(validOrigCornersArray);
    MatOfPoint2f validRefCornersMat = new MatOfPoint2f(validRefCornersArray);
    MatOfPoint2f validOrigCornersMat = new MatOfPoint2f(validOrigCornersArray);

    ret = Calib3d.estimateAffinePartial2D(validOrigCornersMat, validRefCornersMat);
    return ret;
  }

  private void stabilize(Mat refImg, Mat origImg, Mat fixedImg) {
    int rows = refImg.rows();
    int cols = refImg.cols();
    int subTop = rows / 3;
    int subBottom = rows * 2 / 3;
    int subLeft = cols / 3;
    int subRight = cols * 2 / 3;
    Mat subRefImg = refImg.submat(subTop, subBottom, subLeft, subRight);
    Mat subOrigImg = origImg.submat(subTop, subBottom, subLeft, subRight);

    Mat m = calcTransformMatrix(subRefImg, subOrigImg);
    if (m.empty()) {
      fixedImg = origImg;
    } else {
      Imgproc.warpAffine(origImg, fixedImg, m, origImg.size());
    }
  }

  private void closeCaptureSession() {
    if (cameraCaptureSession != null) {
      cameraCaptureSession.close();
      cameraCaptureSession = null;
    }
  }

  public void close() {
    closeCaptureSession();

    if (cameraDevice != null) {
      cameraDevice.close();
      cameraDevice = null;
    }
    if (pictureImageReader != null) {
      pictureImageReader.close();
      pictureImageReader = null;
    }
    if (imageStreamReader != null) {
      imageStreamReader.close();
      imageStreamReader = null;
    }
    if (mediaRecorder != null) {
      mediaRecorder.reset();
      mediaRecorder.release();
      mediaRecorder = null;
    }
  }

  public void dispose() {
    close();
    flutterTexture.release();
    orientationEventListener.disable();
  }

  private int getMediaOrientation() {
    final int sensorOrientationOffset =
        (currentOrientation == ORIENTATION_UNKNOWN)
            ? 0
            : (isFrontFacing) ? -currentOrientation : currentOrientation;
    return (sensorOrientationOffset + sensorOrientation + 360) % 360;
  }
}
