package net.npaka.barcodedetectionex;
import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Rect;
import android.util.AttributeSet;
import android.util.DisplayMetrics;
import android.view.View;

import com.google.firebase.ml.vision.barcode.FirebaseVisionBarcode;

import java.util.List;

//描画ビュー
public class DrawView extends View {
    //定数
    private static final int COLOR_BLUE = Color.argb(127, 0, 0, 255);
    private static final int COLOR_WHITE = Color.WHITE;

    //情報
    private Rect imageRect = new Rect();
    private float imageScale = 1;
    public List<FirebaseVisionBarcode> barcodes = null;
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
    //(4)検出結果の描画
    @Override
    protected void onDraw(Canvas canvas) {
        if (this.barcodes == null) return;

        //バーコード検出の描画
        for (FirebaseVisionBarcode barcode : this.barcodes) {
            //領域の描画
            Rect rect = convertRect(barcode.getBoundingBox());
            paint.setColor(COLOR_BLUE);
            paint.setStyle(Paint.Style.FILL);
            canvas.drawRect(rect, paint);

            //バーコードの付加情報の描画
            if (barcode.getRawValue() != null) {
                drawText(canvas, barcode.getRawValue(), 12, rect);
            }
        }
    }

    //テキストの描画
    private void drawText(Canvas canvas, String text, float fontSize, Rect rect) {
        if (text == null) return;
        paint.setColor(COLOR_WHITE);
        paint.setTextSize(fontSize*density);
        Paint.FontMetrics metrics = paint.getFontMetrics();
        canvas.save();
        canvas.clipRect(rect);
        float sw = paint.measureText(text);
        if (rect.width() > sw) {
            canvas.drawText(text, rect.left+(rect.width()-sw)/2, rect.top-metrics.ascent, paint);
        } else {
            canvas.drawText(text, rect.left, rect.top-metrics.ascent, paint);
        }
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
}