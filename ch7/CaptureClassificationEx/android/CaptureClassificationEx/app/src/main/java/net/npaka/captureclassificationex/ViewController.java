package net.npaka.captureclassificationex;
import android.app.Activity;
import android.app.AlertDialog;
import android.content.Context;
import android.graphics.ImageFormat;
import android.graphics.SurfaceTexture;
import android.hardware.camera2.CameraAccessException;
import android.hardware.camera2.CameraCaptureSession;
import android.hardware.camera2.CameraCharacteristics;
import android.hardware.camera2.CameraDevice;
import android.hardware.camera2.CameraManager;
import android.hardware.camera2.CaptureRequest;
import android.hardware.camera2.params.StreamConfigurationMap;
import android.media.Image;
import android.media.ImageReader;
import android.os.Handler;
import android.os.HandlerThread;
import android.support.annotation.NonNull;
import android.util.Size;
import android.util.SparseIntArray;
import android.view.LayoutInflater;
import android.view.Surface;
import android.view.TextureView;
import android.view.View;
import android.widget.FrameLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;

import com.google.android.gms.tasks.OnFailureListener;
import com.google.android.gms.tasks.OnSuccessListener;
import com.google.firebase.ml.vision.FirebaseVision;
import com.google.firebase.ml.vision.common.FirebaseVisionImage;
import com.google.firebase.ml.vision.common.FirebaseVisionImageMetadata;
import com.google.firebase.ml.vision.label.FirebaseVisionLabel;
import com.google.firebase.ml.vision.label.FirebaseVisionLabelDetector;
import com.google.firebase.ml.vision.label.FirebaseVisionLabelDetectorOptions;

import java.util.Arrays;
import java.util.List;

//画像検出（カメラ映像）
public class ViewController extends FrameLayout {
    //定数
    private static final SparseIntArray ORIENTATIONS = new SparseIntArray();
    static {
        ORIENTATIONS.append(Surface.ROTATION_0, 90);
        ORIENTATIONS.append(Surface.ROTATION_90, 0);
        ORIENTATIONS.append(Surface.ROTATION_180, 270);
        ORIENTATIONS.append(Surface.ROTATION_270, 180);
    }

    //UI
    private TextureView textureView;
    private TextView lblText;

    //カメラ
    private Activity activity;
    private CameraManager manager;
    private Handler workHandler;
    private String cameraId;
    private CameraCharacteristics cameraInfo;
    private CameraDevice camera;
    private Size previewSize;
    private CaptureRequest.Builder previewBuilder;
    private ImageReader imageReader;
    private Surface surface;

    //情報
    private boolean predictFlag = false;


//====================
//ライフサイクル
//====================
    //コンストラクタ
    public ViewController(Activity activity) {
        super(activity);
        this.activity = activity;

        //レイアウト
        this.setLayoutParams(new FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT));
        LayoutInflater inflater = (LayoutInflater)activity.
            getSystemService(Context.LAYOUT_INFLATER_SERVICE);
        View view = inflater.inflate(R.layout.main, null);
        addView(view);

        //UI
        this.textureView = this.findViewById(R.id.texture_view);
        this.lblText = this.findViewById(R.id.lbl_text);
    }

    //(1)カメラキャプチャの初期化
    public void initCapture() {
        //ハンドラの生成
        HandlerThread thread = new HandlerThread("work");
        thread.start();
        this.workHandler = new Handler(thread.getLooper());

        //カメラマネージャの取得
        this.manager = (CameraManager)activity
            .getSystemService(Context.CAMERA_SERVICE);

        //テクスチャービューのリスナーの指定
        this.textureView.setSurfaceTextureListener(
            new TextureView.SurfaceTextureListener() {
            //テクスチャ有効化時に呼ばれる
            @Override
            public void onSurfaceTextureAvailable(
                SurfaceTexture surface, int width, int height) {
                startCamera();
            }

            //テクスチャサイズ変更時に呼ばれる
            @Override
            public void onSurfaceTextureSizeChanged(SurfaceTexture surface,
                int width, int height) {
            }

            //テクスチャ更新時に呼ばれる
            @Override
            public void onSurfaceTextureUpdated(SurfaceTexture surface) {
            }

            //テクスチャ破棄時に呼ばれる
            @Override
            public boolean onSurfaceTextureDestroyed(SurfaceTexture surface) {
                stopCamera();
                return true;
            }
        });

        //カメラの開始
        if (this.textureView.isAvailable()) startCamera();
    }

    //(2)カメラの開始
    public void startCamera() {
        try {
            //カメラ情報の取得
            this.cameraId = getCameraId();
            this.cameraInfo = manager.getCameraCharacteristics(this.cameraId);
            this.previewSize = getPreviewSize(this.cameraInfo);

            //カメラ映像のサイズ
            int sw = Math.min(previewSize.getWidth(), previewSize.getHeight());
            int sh = Math.max(previewSize.getWidth(), previewSize.getHeight());
            float scale =
                ((float)getWidth()/(float)sw > (float)getHeight()/(float)sh) ?
                (float)getWidth()/(float)sw : (float)getHeight()/(float)sh;
            RelativeLayout.LayoutParams params = new RelativeLayout.LayoutParams(sw, sh);
            params.addRule(RelativeLayout.CENTER_IN_PARENT);
            textureView.setLayoutParams(params);
            textureView.setScaleX(scale);
            textureView.setScaleY(scale);

            //カメラのオープン
            this.manager.openCamera(this.cameraId, new CameraDevice.StateCallback() {
                //接続時に呼ばれる
                @Override
                public void onOpened(CameraDevice camera) {
                    ViewController.this.camera = camera;
                    initPreview();
                    startPreview();
                }

                //切断時に呼ばれる
                @Override
                public void onDisconnected(CameraDevice camera) {
                    stopCamera();
                }

                //エラー時に呼ばれる
                @Override
                public void onError(CameraDevice camera, int error) {
                    stopCamera();
                }
            }, null);
        } catch (SecurityException e) {
            e.printStackTrace();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    //(3)カメラの停止
    public void stopCamera() {
        if (this.camera == null) return;
        this.camera.close();
        this.camera = null;
    }

    //(4)カメラIDの取得
    private String getCameraId() {
        try {
            for (String cameraId : manager.getCameraIdList()) {
                CameraCharacteristics cameraInfo =
                    manager.getCameraCharacteristics(cameraId);
                //背面カメラ
                if (cameraInfo.get(CameraCharacteristics.LENS_FACING) ==
                    CameraCharacteristics.LENS_FACING_BACK) {
                    return cameraId;
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    //(5)プレビューサイズの取得
    private Size getPreviewSize(CameraCharacteristics characteristics) {
        StreamConfigurationMap map = characteristics.get(
            CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP);
        Size[] sizes = map.getOutputSizes(SurfaceTexture.class);
        for (int i = 0; i < sizes.length; i++) {
            //サイズ1000x1000以下
            if (sizes[i].getWidth() < 1000 && sizes[i].getHeight() < 1000) {
                return sizes[i];
            }
        }
        return sizes[0];
    }

    //(6)プレビューの初期化
    private void initPreview() {
        if (this.camera == null) return;

        //出力先となるサーフェイスの生成
        SurfaceTexture texture = this.textureView.getSurfaceTexture();
        if (texture == null) return;
        texture.setDefaultBufferSize(this.previewSize.getWidth(), this.previewSize.getHeight());
        this.surface = new Surface(texture);

        //出力先となるイメージリーダーの生成
        this.imageReader = ImageReader.newInstance(
            this.previewSize.getWidth(), this.previewSize.getHeight(),
            ImageFormat.JPEG, 10);
        this.imageReader.setOnImageAvailableListener(new ImageReader.OnImageAvailableListener() {
            @Override
            public void onImageAvailable(ImageReader reader) {
                try {
                    //予測
                    Image image = reader.acquireLatestImage();
                    detectLabels(image);
                    image.close();
                } catch (Exception e) {
                    //無処理
                }
            }
        }, workHandler);

        //プレビュービルダーの生成
        try {
            this.previewBuilder = this.camera
                .createCaptureRequest(CameraDevice.TEMPLATE_PREVIEW);
            this.previewBuilder.addTarget(surface);
            this.previewBuilder.addTarget(imageReader.getSurface());
            this.previewBuilder.set(CaptureRequest.JPEG_ORIENTATION, getOrientation());
            this.previewBuilder.set(CaptureRequest.CONTROL_AF_MODE,
                CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_PICTURE);
            this.previewBuilder.set(CaptureRequest.CONTROL_AE_MODE,
                CaptureRequest.CONTROL_AE_MODE_ON);
        } catch (CameraAccessException e) {
            e.printStackTrace();
        }
    }

    //(7)回転の取得
    private int getOrientation() {
        try {
            //ディスプレイの向き
            int deviceRotation = activity.getWindowManager().getDefaultDisplay().getRotation();
            int rotation = ORIENTATIONS.get(deviceRotation);

            //レンズの向き
            CameraManager cameraManager =
                (CameraManager)activity.getSystemService(Activity.CAMERA_SERVICE);
            int sensorOrientation = cameraManager
                .getCameraCharacteristics(this.cameraId)
                .get(CameraCharacteristics.SENSOR_ORIENTATION);

            //回転
            return (rotation + sensorOrientation + 270) % 360;
        } catch (Exception e) {
            e.printStackTrace();
            return 0;
        }
    }

    //(8)プレビューの開始
    private void startPreview() {
        if (this.camera == null) return;
        try {
            //プレビューの開始
            this.camera.createCaptureSession(Arrays.asList(surface, imageReader.getSurface()),
                new CameraCaptureSession.StateCallback() {
                    //成功時に呼ばれる
                    @Override
                    public void onConfigured(CameraCaptureSession session) {
                        if (ViewController.this.camera == null) return;

                        //カメラ映像をテクスチャに表示
                        try {
                            session.setRepeatingRequest(
                                ViewController.this.previewBuilder.build(),
                                null,
                                ViewController.this.workHandler);
                        } catch (CameraAccessException e) {
                            e.printStackTrace();
                        }
                    }

                    //失敗時に呼ばれる
                    @Override
                    public void onConfigureFailed(CameraCaptureSession session) {
                    }
                }, this.workHandler);
        } catch (CameraAccessException e) {
            e.printStackTrace();
        }
    }


//====================
//アラート
//====================
    //アラートの表示
    private void showAlert(String text) {
        new AlertDialog.Builder(this.getContext())
            .setMessage(text)
            .setPositiveButton("OK", null)
            .show();
    }


//====================
//画像分類（カメラ映像）
//====================
    //オンデバイスAPIの画像分類（カメラ映像）
    private void detectLabels(Image image) {
        //(9)検出中に次の検出を実行させない
        if (this.predictFlag) return;
        this.predictFlag = true;

        //(10)FirebaseVisionImageの生成
        FirebaseVisionImage visionImage = FirebaseVisionImage.fromMediaImage(
                image, FirebaseVisionImageMetadata.ROTATION_0);

        //画像分類のオプションの生成
        FirebaseVisionLabelDetectorOptions options =
            new FirebaseVisionLabelDetectorOptions.Builder()
            .setConfidenceThreshold(0.75f)
            .build();

        //画像分類の検出器の生成
        FirebaseVisionLabelDetector labelDetector = FirebaseVision.getInstance()
            .getVisionLabelDetector(options);

        //画像分類の実行
        labelDetector.detectInImage(visionImage)
            .addOnSuccessListener(new OnSuccessListener<List<FirebaseVisionLabel>>() {
                //成功時に呼ばれる
                @Override
                public void onSuccess(List<FirebaseVisionLabel> labels) {
                    //検証結果の取得
                    String text = "\n";
                    for (FirebaseVisionLabel label: labels) {
                        text += label.getLabel()+" : "+
                            (int)(label.getConfidence()*100)+"%\n";
                    }
                    final String str = text;

                    //UIの更新
                    post(new Runnable() {
                        @Override
                        public void run() {
                            lblText.setText(str);
                            lblText.setVisibility(
                                str.length() == 0 ? View.GONE : View.VISIBLE);
                            predictFlag = false;
                        }
                    });
                }
            })
            .addOnFailureListener(new OnFailureListener() {
                //エラー時に呼ばれる
                @Override
                public void onFailure(@NonNull Exception e) {
                    showAlert(e.getMessage());
                }
            });
    }
}