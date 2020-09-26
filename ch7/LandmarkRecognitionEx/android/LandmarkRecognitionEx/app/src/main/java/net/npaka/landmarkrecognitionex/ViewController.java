package net.npaka.landmarkrecognitionex;
import android.app.Activity;
import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.graphics.Bitmap;
import android.support.annotation.NonNull;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.TextView;

import com.google.android.gms.tasks.OnFailureListener;
import com.google.android.gms.tasks.OnSuccessListener;
import com.google.firebase.ml.vision.FirebaseVision;
import com.google.firebase.ml.vision.cloud.FirebaseVisionCloudDetectorOptions;
import com.google.firebase.ml.vision.cloud.landmark.FirebaseVisionCloudLandmark;
import com.google.firebase.ml.vision.cloud.landmark.FirebaseVisionCloudLandmarkDetector;
import com.google.firebase.ml.vision.common.FirebaseVisionImage;

import java.util.List;

//ランドマーク認識
public class ViewController extends FrameLayout {
    //UI
    private ImageView imageView;
    private TextView lblText;


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
                            detectLandmarks(image);
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
//ランドマーク認識
//====================
    //クラウドAPIのランドマーク認識
    private void detectLandmarks(Bitmap image) {
        //FirebaseVisionImageの生成
        FirebaseVisionImage visionImage = FirebaseVisionImage.fromBitmap(image);

        //(1)ランドマーク認識のオプションの生成
        FirebaseVisionCloudDetectorOptions options =
            new FirebaseVisionCloudDetectorOptions.Builder()
                .setModelType(FirebaseVisionCloudDetectorOptions.LATEST_MODEL)
                .setMaxResults(20)
                .build();

        //(2)ランドマーク認識の検出器の生成
        FirebaseVisionCloudLandmarkDetector landmarkDetector = FirebaseVision.getInstance()
            .getVisionCloudLandmarkDetector(options);

        //(3)ランドマーク認識の実行
        landmarkDetector.detectInImage(visionImage)
            .addOnSuccessListener(new OnSuccessListener<List<FirebaseVisionCloudLandmark>>() {
                //成功時に呼ばれる
                @Override
                public void onSuccess(List<FirebaseVisionCloudLandmark> landmarks) {
                    //検証結果の取得
                    String text = "\n";
                    for (FirebaseVisionCloudLandmark landmark: landmarks) {
                        text += landmark.getLandmark()+" : "+
                            (int)(landmark.getConfidence()*100)+"%\n";
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