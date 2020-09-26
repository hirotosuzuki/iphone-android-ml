import UIKit
import Vision

//描画ビュー
class DrawView: UIView {
    //定数
    let COLOR_BLUE: UIColor = UIColor(red: 0.0, green: 0.0, blue: 255.0, alpha: 0.5)
    let COLOR_WHITE: UIColor = UIColor.white

    //プロパティ
    var imageRect: CGRect = CGRect.zero
    
    //ターゲットの保持
    var target: VNDetectedObjectObservation! = nil

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

    //(4)検出結果の描画
    override func draw(_ rect: CGRect) {
        if self.target == nil {return}
        
        //グラフィックスコンテキストの生成
        let context = UIGraphicsGetCurrentContext()!

        //領域の描画
        let rect = convertRect(self.target.boundingBox)
        context.setStrokeColor(COLOR_BLUE.cgColor)
        context.setLineWidth(6)
        context.stroke(rect)
    }

    //検出領域の座標系を画面の座標系に変換
    func convertRect(_ rect:CGRect) -> CGRect {
        return CGRect(
            x: self.imageRect.minX + rect.minX * self.imageRect.width,
            y: self.imageRect.minY + (1 - rect.maxY) * self.imageRect.height,
            width: rect.width * self.imageRect.width,
            height: rect.height * self.imageRect.height)
    }
    
    //画面の座標系を検出領域の座標系に変換
    func inversConvertRect(_ rect:CGRect) -> CGRect {
        if (self.imageRect == CGRect.zero) {return CGRect.zero}
        return CGRect(
            x: (rect.minX - self.imageRect.minX) / self.imageRect.width,
            y: 1 - (rect.minY - self.imageRect.minY) / self.imageRect.height,
            width: rect.width / self.imageRect.width,
            height: rect.height / self.imageRect.height)
    }
}
