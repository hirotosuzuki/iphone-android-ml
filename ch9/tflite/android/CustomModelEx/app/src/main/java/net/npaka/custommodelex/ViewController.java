package net.npaka.custommodelex;
import android.app.Activity;
import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.graphics.Bitmap;
import android.graphics.Color;
import android.graphics.Point;
import android.os.Build;
import android.support.annotation.NonNull;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.TextView;

import com.google.android.gms.tasks.OnFailureListener;
import com.google.android.gms.tasks.OnSuccessListener;
import com.google.firebase.ml.common.FirebaseMLException;
import com.google.firebase.ml.custom.FirebaseModelDataType;
import com.google.firebase.ml.custom.FirebaseModelInputOutputOptions;
import com.google.firebase.ml.custom.FirebaseModelInputs;
import com.google.firebase.ml.custom.FirebaseModelInterpreter;
import com.google.firebase.ml.custom.FirebaseModelManager;
import com.google.firebase.ml.custom.FirebaseModelOptions;
import com.google.firebase.ml.custom.FirebaseModelOutputs;
import com.google.firebase.ml.custom.model.FirebaseCloudModelSource;
import com.google.firebase.ml.custom.model.FirebaseLocalModelSource;
import com.google.firebase.ml.custom.model.FirebaseModelDownloadConditions;

import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

//カスタムモデル
public class ViewController extends FrameLayout {
    //UI
    private ImageView imageView;
    private TextView lblText;

    //情報
    private FirebaseModelInterpreter interpreter;
    private String[] labels;


//====================
//ライフサイクル
//====================
    //コンストラクタ
    public ViewController(Activity activity) {
        super(activity);

        //モデルの初期化
        initModel();

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

    //モデルの初期化
    private void initModel() {
        //(1)ラベルの読み込み
        String text = readAssetsText("labels.txt");
        labels = text.split("\n", 0);

        //(2)クラウドモデルの自動更新の条件の生成
        FirebaseModelDownloadConditions.Builder conditionsBuilder =
            new FirebaseModelDownloadConditions.Builder()
            .requireWifi();
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            conditionsBuilder = conditionsBuilder
                .requireCharging()
                .requireDeviceIdle();
        }
        FirebaseModelDownloadConditions conditions = conditionsBuilder.build();

        //(3)クラウドモデルソースの登録
        FirebaseCloudModelSource cloudSource =
            new FirebaseCloudModelSource.Builder("image_classification")
            .enableModelUpdates(true)
            .setInitialDownloadConditions(conditions)
            .setUpdatesDownloadConditions(conditions)
            .build();
        FirebaseModelManager.getInstance().registerCloudModelSource(cloudSource);

        //(4)ローカルモデルソースの登録
        FirebaseLocalModelSource localSource =
            new FirebaseLocalModelSource.Builder("local_image_classification")
            .setAssetFilePath("image_classification.tflite")
            .build();
        FirebaseModelManager.getInstance().registerLocalModelSource(localSource);

        //(5)カスタムモデルの検出器の生成の生成
        try {
            FirebaseModelOptions options = new FirebaseModelOptions.Builder()
                .setCloudModelName("image_classification")
                .setLocalModelName("local_image_classification")
                .build();
            interpreter = FirebaseModelInterpreter.getInstance(options);
        } catch (FirebaseMLException e) {
            android.util.Log.d("debug",e.getLocalizedMessage());
        }
    }

    //アセットテキストの読み込み
    private String readAssetsText(String name) {
        char[] work = new char[1024];
        InputStreamReader in = null;
        try {
            StringBuffer sb = new StringBuffer();
            in = new InputStreamReader(
                getContext().getAssets().open(name));
            while (true) {
                int size = in.read(work);
                if (size <= 0) break;
                sb.append(work, 0, size);
            }
            in.close();
            return sb.toString();
        } catch (Exception e) {
            try {
                if (in != null) in.close();
            } catch (Exception e2) {
            }
            return null;
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
                            predict(image);
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
//予測
//====================
    //予測
    private void predict(Bitmap image) {
        try {
            //(6)モデルの入力形式と出力形式の指定
            FirebaseModelInputOutputOptions inputOutputOptions =
                new FirebaseModelInputOutputOptions.Builder()
                    .setInputFormat(0, FirebaseModelDataType.FLOAT32, new int[]{1, 28, 28, 1})
                    .setOutputFormat(0, FirebaseModelDataType.FLOAT32, new int[]{1, 10})
                    .build();

            //(7)モデルの入力データの生成
            float[][][][] input = image2inputData(image, new Point(28, 28));
            FirebaseModelInputs inputs = new FirebaseModelInputs.Builder()
                .add(input)
                .build();

            //(9)予測の実行
            interpreter.run(inputs, inputOutputOptions)
                //成功時に呼ばれる
                .addOnSuccessListener(
                    new OnSuccessListener<FirebaseModelOutputs>() {
                        @Override
                        public void onSuccess(FirebaseModelOutputs outputs) {
                            //検出結果の取得
                            float[][] output = outputs.getOutput(0);

                            //outputsをHashMapに変換
                            Map<Integer, Integer> hashMap = new HashMap<>();
                            float[] inArray = output[0];
                            for (int i = 0; i < inArray.length; i++) {
                                hashMap.put(i, (int)inArray[i]);
                            }

                            //信頼度順にソート
                            List<Map.Entry<Integer,Integer>> entries =
                                new ArrayList<>(hashMap.entrySet());
                            Collections.sort(entries, new Comparator<Map.Entry<Integer,Integer>>() {
                                @Override
                                public int compare(Map.Entry<Integer,Integer> entry1,
                                    Map.Entry<Integer,Integer> entry2) {
                                    return (entry2.getValue()).compareTo(entry1.getValue());
                                }
                            });
                            String text = "\n";
                            for (int i = 0; i < Math.min(3, entries.size()); i++) { //上位3件
                                Map.Entry<Integer,Integer> s = entries.get(i);
                                int index = s.getKey(); //Index
                                int accuracy = (int)((float)s.getValue()*100f); //信頼度
                                text += String.format("%s : %d%%\n", labels[index], accuracy);
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
                //エラー時に呼ばれる
                .addOnFailureListener(
                    new OnFailureListener() {
                        @Override
                        public void onFailure(@NonNull Exception e) {
                            showAlert(e.getMessage());
                        }
                    });
        } catch (FirebaseMLException e) {
            android.util.Log.d("debug",e.getLocalizedMessage());
        }
    }

    //(8)Bitmapを多次元配列に変換
    private float[][][][] image2inputData(Bitmap image, Point size) {
        //BitmapのリサイズとRGBAのint配列への変換
        int[] rgbaData = cgImage2rgbaData(image, size);

        //RGBAのint配列をグレースケールのfloat配列に変換
        float[][][][] inputData = new float[1][size.y][size.x][1];
        for (int i = 0; i < rgbaData.length; i++) {
            float r = (float)Color.red(rgbaData[i]);
            float g = (float)Color.green(rgbaData[i]);
            float b = (float)Color.blue(rgbaData[i]);
            float gray = r*0.3f+g*0.59f+b*0.11f;
            inputData[0][i/size.x][i%size.x][0] = gray;
        }
        return inputData;
    }

    //BitmapをRGBAのint配列に変換
    private int[] cgImage2rgbaData(Bitmap image, Point size) {
        Bitmap resizeImage = Bitmap.createScaledBitmap(
            image, size.x, size.y, true);
        int[] pixels = new int[size.x*size.y];
        resizeImage.getPixels(pixels, 0, size.x, 0, 0, size.x, size.y);
        return pixels;
    }
}