package net.npaka.facedetectionex;
import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Point;
import android.graphics.Rect;
import android.util.AttributeSet;
import android.util.DisplayMetrics;
import android.view.View;

import com.google.firebase.ml.vision.face.FirebaseVisionFace;
import com.google.firebase.ml.vision.face.FirebaseVisionFaceLandmark;

import java.util.List;

//描画ビュー
public class DrawView extends View {
    //定数
    private static final int COLOR_BLUE = Color.argb(127, 0, 0, 255);
    private static final int COLOR_WHITE = Color.WHITE;

    //情報
    private Rect imageRect = new Rect();
    private float imageScale = 1;
    public List<FirebaseVisionFace> faces = null;
    private float density;
    private Paint paint;


//====================
//ライフサイクル
//====================
    //コンストラクタ
    public DrawView(Context context) {
        super(context);
        init();
    }

    //コンストラクタ
    public DrawView(Context context, AttributeSet attrs) {
        super(context, attrs);
        init();
    }

    //コンストラクタ
    public DrawView(Context context, AttributeSet attrs,
        int defStyle) {
        super(context, attrs, defStyle);
        init();
    }

    //初期化
    private void init() {
        DisplayMetrics metrics = getContext().getResources().getDisplayMetrics();
        density = metrics.density;
        paint = new Paint();
    }


//====================
//アクセス
//====================
    //画像サイズの指定
    public void setImageSize(int imageWidth, int imageHeight) {
        //画像の表示領域の計算（AspectFill）
        float scale =
            ((float)getWidth()/(float)imageWidth > (float)getHeight()/(float)imageHeight) ?
            (float)getWidth()/(float)imageWidth :
            (float)getHeight()/(float)imageHeight;
        float dw = imageWidth*scale;
        float dh = imageHeight*scale;
        this.imageRect = new Rect(
            (int)((getWidth()-dw)/2),
            (int)((getHeight()-dh)/2),
            (int)((getWidth()-dw)/2+dw),
            (int)((getHeight()-dh)/2+dh));
        this.imageScale = scale;
    }


//====================
//検出結果の描画
//====================
    //(5)検出結果の描画
    @Override
    protected void onDraw(Canvas canvas) {
        if (this.faces == null) return;

        //顔検出の描画
        for (FirebaseVisionFace face : this.faces) {
            //領域の描画
            Rect rect = convertRect(face.getBoundingBox());
            paint.setColor(COLOR_BLUE);
            paint.setStrokeWidth(2*density);
            paint.setStyle(Paint.Style.STROKE);
            canvas.drawRect(rect, paint);

            //顔のランドマークの描画
            paint.setColor(COLOR_WHITE);
            drawLandmark(canvas, face, FirebaseVisionFaceLandmark.LEFT_EYE);
            drawLandmark(canvas, face, FirebaseVisionFaceLandmark.RIGHT_EYE);
            drawLandmark(canvas, face, FirebaseVisionFaceLandmark.LEFT_MOUTH);
            drawLandmark(canvas, face, FirebaseVisionFaceLandmark.RIGHT_MOUTH);
            drawLandmark(canvas, face, FirebaseVisionFaceLandmark.BOTTOM_MOUTH);

            //笑顔確率の表示
            if (face.getSmilingProbability() != FirebaseVisionFace.UNCOMPUTED_PROBABILITY) {
                String text = String.format("%d%%", (int)(face.getSmilingProbability()*100));
                drawText(canvas, text, rect);
            }
        }
    }

    //顔のランドマークの描画
    private void drawLandmark(Canvas canvas, FirebaseVisionFace face, int type) {
        FirebaseVisionFaceLandmark landmark = face.getLandmark(type);
        if (landmark != null) {
            Point point = convertPoint(new Point(
                landmark.getPosition().getX().intValue(),
                landmark.getPosition().getY().intValue()));
            paint.setColor(COLOR_WHITE);
            paint.setStyle(Paint.Style.FILL);
            canvas.drawCircle(point.x, point.y, 3 * density, paint);
        }
    }

    //テキストの描画
    private void drawText(Canvas canvas, String text, Rect rect) {
        if (text == null) return;
        //背景
        Rect textRect = new Rect(rect.left, (int)(rect.top-16*density),
            rect.left+rect.width(), rect.top);
        paint.setColor(COLOR_BLUE);
        paint.setStyle(Paint.Style.FILL);
        canvas.drawRect(textRect, paint);

        //テキスト
        paint.setColor(COLOR_WHITE);
        paint.setTextSize(16*density);
        Paint.FontMetrics metrics = paint.getFontMetrics();
        canvas.save();
        canvas.clipRect(textRect);
        canvas.drawText(text,
            (int)(textRect.left+(textRect.width()-paint.measureText(text))/2),
            textRect.top-metrics.ascent, paint);
        canvas.restore();
    }

    //検出結果の座標系を画面の座標系に変換
    private Rect convertRect(Rect rect) {
        return new Rect(
            (int)(imageRect.left+rect.left*imageScale),
            (int)(imageRect.top+rect.top*imageScale),
            (int)(imageRect.left+rect.left*imageScale+rect.width()*imageScale),
            (int)(imageRect.top+rect.top*imageScale+rect.height()*imageScale));
    }

    //検出結果の座標系を画面の座標系に変換
    private Point convertPoint(Point point) {
        return new Point(
            (int)(imageRect.left+point.x*imageScale),
            (int)(imageRect.top+point.y*imageScale));
    }
}