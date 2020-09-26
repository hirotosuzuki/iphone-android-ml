package net.npaka.textrecognitionex;
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

import com.google.android.gms.tasks.OnFailureListener;
import com.google.android.gms.tasks.OnSuccessListener;
import com.google.firebase.ml.vision.FirebaseVision;
import com.google.firebase.ml.vision.common.FirebaseVisionImage;
import com.google.firebase.ml.vision.text.FirebaseVisionText;
import com.google.firebase.ml.vision.text.FirebaseVisionTextRecognizer;

//テキスト認識
public class ViewController extends FrameLayout implements View.OnClickListener {
    //UI
    private ImageView imageView;
    private Button btnSegmentControl0;
    private Button btnSegmentControl1;
    private int segmentControl = 0;
    private DrawView drawView;

    //情報
    private boolean predictFlag = false;


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
        this.btnSegmentControl0 = this.findViewById(R.id.btn_segment_control0);
        this.btnSegmentControl0.setOnClickListener(this);
        this.btnSegmentControl1 = this.findViewById(R.id.btn_segment_control1);
        this.btnSegmentControl1.setOnClickListener(this);
        this.drawView = this.findViewById(R.id.draw_view);

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
                                detectTexts(image);
                            } else if (segmentControl == 1) {
                                detectCloudTexts(image);
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
//テキスト認識
//====================
    //オンデバイスAPIのテキスト認識
    private void detectTexts(Bitmap image) {
        //画像サイズの指定
        drawView.setImageSize(image.getWidth(), image.getHeight());

        //予測中は無処理
        if (predictFlag) return;
        predictFlag = true;

        //FirebaseVisionImageの生成
        FirebaseVisionImage visionImage = FirebaseVisionImage.fromBitmap(image);

        //(1)テキスト認識の検出器の生成
        FirebaseVisionTextRecognizer textRecognizer = FirebaseVision.getInstance()
            .getOnDeviceTextRecognizer();

        //(2)テキスト認識の実行
        textRecognizer.processImage(visionImage)
            .addOnSuccessListener(new OnSuccessListener<FirebaseVisionText>() {
                //成功時に呼ばれる
                @Override
                public void onSuccess(final FirebaseVisionText texts) {
                    post(new Runnable() {
                        @Override
                        public void run() {
                            //検出結果の取得
                            drawView.texts = texts;

                            //UIの更新
                            drawView.postInvalidate();
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
                    predictFlag = false;
                }
            });
    }

    //クラウドAPIのテキスト認識
    private void detectCloudTexts(Bitmap image) {
        //画像サイズの指定
        drawView.setImageSize(image.getWidth(), image.getHeight());

        //予測中は無処理
        if (predictFlag) return;
        predictFlag = true;

        //FirebaseVisionImageの生成
        FirebaseVisionImage visionImage = FirebaseVisionImage.fromBitmap(image);

        //(4)テキスト認識の検出器の生成
        FirebaseVisionTextRecognizer textRecognizer = FirebaseVision.getInstance()
            .getCloudTextRecognizer();

        //(5)テキスト認識の実行
        textRecognizer.processImage(visionImage)
            .addOnSuccessListener(new OnSuccessListener<FirebaseVisionText>() {
                //成功時に呼ばれる
                @Override
                public void onSuccess(final FirebaseVisionText texts) {
                    post(new Runnable() {
                        @Override
                        public void run() {
                            //検出結果の取得
                            drawView.texts = texts;

                            //UIの更新
                            drawView.postInvalidate();
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
                    predictFlag = false;
                }
            });
    }
}