import UIKit
import Vision

//描画ビュー
class DrawView: UIView {
    //定数
    let COLOR_BLUE: UIColor = UIColor(red: 0.0, green: 0.0, blue: 255.0, alpha: 0.5)
    let COLOR_WHITE: UIColor = UIColor.white

    //プロパティ
    var imageRect: CGRect = CGRect.zero
    var barcodes: [VNBarcodeObservation]!

    //画像サイズの指定
    func setImageSize(_ imageSize: CGSize) {
        //画像の表示領域の計算（AspectFill）
        let scale: CGFloat =
            (self.frame.width/imageSize.width > self.frame.height/imageSize.height) ?
            self.frame.width/imageSize.width :
            self.frame.height/imageSize.height
        let dw: CGFloat = imageSize.width*scale
        let dh: CGFloat = imageSize.height*scale
        self.imageRect = CGRect(
            x: (self.frame.width-dw)/2,
            y: (self.frame.height-dh)/2,
            width: dw, height: dh)
    }

    //(3)検出結果の描画
    override func draw(_ rect: CGRect) {
        if self.barcodes == nil {return}
        
        //グラフィックスコンテキストの生成
        let context = UIGraphicsGetCurrentContext()!

        //バーコード検出の描画
        for barcode in barcodes {
            //領域の描画
            let rect = convertRect(barcode.boundingBox)
            context.setFillColor(COLOR_BLUE.cgColor)
            context.fill(rect)
            
            //バーコードの付加情報の描画
            drawText(context, text: barcode.payloadStringValue,
                fontSize: 12, rect: rect)
        }
    }
    
    //テキストの描画
    func drawText(_ context: CGContext, text: String!, fontSize: CGFloat, rect: CGRect) {
        if text == nil {return}
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attributes = [
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: fontSize),
            NSAttributedString.Key.foregroundColor: COLOR_WHITE
        ]
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        attributedString.draw(in: rect)
    }
    
    //検出領域の座標系を画面の座標系に変換
    func convertRect(_ rect:CGRect) -> CGRect {
        return CGRect(
            x: self.imageRect.minX + rect.minX * self.imageRect.width,
            y: self.imageRect.minY + (1 - rect.maxY) * self.imageRect.height,
            width: rect.width * self.imageRect.width,
            height: rect.height * self.imageRect.height)
    }
}
