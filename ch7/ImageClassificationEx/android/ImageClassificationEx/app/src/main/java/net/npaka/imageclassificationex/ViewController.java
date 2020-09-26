package net.npaka.imageclassificationex;
import android.app.Activity;
import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.graphics.Bitmap;
import android.graphics.Color;
import android.support.annotation.NonNull;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.widget.Button;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.TextView;

import com.google.android.gms.tasks.OnFailureListener;
import com.google.android.gms.tasks.OnSuccessListener;
import com.google.firebase.ml.vision.FirebaseVision;
import com.google.firebase.ml.vision.cloud.FirebaseVisionCloudDetectorOptions;
import com.google.firebase.ml.vision.cloud.label.FirebaseVisionCloudLabel;
import com.google.firebase.ml.vision.cloud.label.FirebaseVisionCloudLabelDetector;
import com.google.firebase.ml.vision.common.FirebaseVisionImage;
import com.google.firebase.ml.vision.label.FirebaseVisionLabel;
import com.google.firebase.ml.vision.label.FirebaseVisionLabelDetector;
import com.google.firebase.ml.vision.label.FirebaseVisionLabelDetectorOptions;

import java.util.List;

//画像分類（画像）
public class ViewController extends FrameLayout implements View.OnClickListener {
    //UI
    private ImageView imageView;
    private TextView lblText;
    private Button btnSegmentControl0;
    private Button btnSegmentControl1;
    private int segmentControl = 0;


//====================
//ライフサイクル
//====================
    //コンストラクタ
    public ViewController(Activity activity) {
        super(activity);

        //レイアウト
        this.setLayoutParams(new FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT));
        LayoutInflater inflater = (LayoutInflater)activity.
            getSystemService(Context.LAYOUT_INFLATER_SERVICE);
        View view = inflater.inflate(R.layout.main, null);
        addView(view);

        //UI
        this.imageView = this.findViewById(R.id.image_view);
        this.lblText = this.findViewById(R.id.lbl_text);
        this.btnSegmentControl0 = this.findViewById(R.id.btn_segment_control0);
        this.btnSegmentControl0.setOnClickListener(this);
        this.btnSegmentControl1 = this.findViewById(R.id.btn_segment_control1);
        this.btnSegmentControl1.setOnClickListener(this);

        //ジェスチャーの追加
        view.setOnTouchListener(new OnTouchListener() {
            @Override
            public boolean onTouch(View view, MotionEvent event) {
                if (event.getAction() == MotionEvent.ACTION_UP) {
                    showActionSheet();
                }
                return false;
            }
        });

        //アクションシートの表示
        showActionSheet();
    }


//====================
//イベント
//====================
    @Override
    public void onClick(View view) {
        if (view == this.btnSegmentControl0) {
            segmentControl = 0;
            this.btnSegmentControl0.setTextColor(Color.WHITE);
            this.btnSegmentControl0.setBackgroundColor(Color.BLUE);
            this.btnSegmentControl0.setEnabled(false);
            this.btnSegmentControl1.setTextColor(Color.BLUE);
            this.btnSegmentControl1.setBackgroundColor(Color.LTGRAY);
            this.btnSegmentControl1.setEnabled(true);
        } else if (view == this.btnSegmentControl1) {
            segmentControl = 1;
            this.btnSegmentControl0.setTextColor(Color.BLUE);
            this.btnSegmentControl0.setBackgroundColor(Color.LTGRAY);
            this.btnSegmentControl0.setEnabled(true);
            this.btnSegmentControl1.setTextColor(Color.WHITE);
            this.btnSegmentControl1.setBackgroundColor(Color.BLUE);
            this.btnSegmentControl1.setEnabled(false);
        }
    }


//====================
//アクションシート
//====================
    //アクションシートの表示
    private void showActionSheet() {
        String[] items = {"カメラ", "フォトライブラリ"};
        new AlertDialog.Builder(this.getContext())
            .setItems(items, new DialogInterface.OnClickListener() {
                @Override
                public void onClick(DialogInterface dialog, int which) {
                    ((AppDelegate)getContext()).openPicker(which, new AppDelegate.ICompletion(){
                        public void onCompletion(Bitmap image) {
                            if (image == null) return;
                            imageView.setImageBitmap(image);

                            //予測
                            if (segmentControl == 0) {
                                detectLabels(image);
                            } else if (segmentControl == 1) {
                                detectCloudLabels(image);
                            }
                        }
                    });
                }
            })
            .setNegativeButton("キャンセル", null)
            .show();
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
//画像分類（画像）
//====================
    //オンデバイスAPIの画像分類（画像）
    private void detectLabels(Bitmap image) {
        //(1)FirebaseVisionImageの生成
        FirebaseVisionImage visionImage = FirebaseVisionImage.fromBitmap(image);

        //(2)画像分類のオプションの生成
        FirebaseVisionLabelDetectorOptions options =
            new FirebaseVisionLabelDetectorOptions.Builder()
            .setConfidenceThreshold(0.75f)
            .build();

        //(3)画像分類の検出器の生成
        FirebaseVisionLabelDetector labelDetector = FirebaseVision.getInstance()
            .getVisionLabelDetector(options);

        //(4)画像分類の実行
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

    //クラウドAPIの画像分類（画像）
    private void detectCloudLabels(Bitmap image) {
        //FirebaseVisionImageの生成
        FirebaseVisionImage visionImage = FirebaseVisionImage.fromBitmap(image);

        //(5)画像分類のオプションの生成
        FirebaseVisionCloudDetectorOptions options =
            new FirebaseVisionCloudDetectorOptions.Builder()
                .setModelType(FirebaseVisionCloudDetectorOptions.LATEST_MODEL)
                .setMaxResults(20)
                .build();

        //(6)画像分類の検出器の生成
        FirebaseVisionCloudLabelDetector labelDetector = FirebaseVision.getInstance()
            .getVisionCloudLabelDetector(options);

        //(7)画像分類の実行
        labelDetector.detectInImage(visionImage)
            .addOnSuccessListener(new OnSuccessListener<List<FirebaseVisionCloudLabel>>() {
                //成功時に呼ばれる
                @Override
                public void onSuccess(List<FirebaseVisionCloudLabel> labels) {
                    //検証結果の取得
                    String text = "\n";
                    for (FirebaseVisionCloudLabel label: labels) {
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