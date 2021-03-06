import UIKit
import FirebaseMLVision

//描画ビュー
class DrawView: UIView {
    //定数
    let COLOR_BLUE: UIColor = UIColor(red: 0.0, green: 0.0, blue: 255.0, alpha: 0.3)
    let COLOR_WHITE: UIColor = UIColor.white

    //プロパティ
    var imageRect: CGRect = CGRect.zero
    var imageScale: CGFloat = 1
    var texts: VisionText! = nil

    //初期化
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    //初期化
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }

    //画像サイズの指定
    func setImageSize(_ imageSize: CGSize) {
        //画像の表示領域の計算（AspectFit）
        let scale: CGFloat =
            (self.frame.width/imageSize.width < self.frame.height/imageSize.height) ?
            self.frame.width/imageSize.width :
            self.frame.height/imageSize.height
        let dw: CGFloat = imageSize.width*scale
        let dh: CGFloat = imageSize.height*scale
        self.imageRect = CGRect(
            x: (self.frame.width-dw)/2,
            y: (self.frame.height-dh)/2,
            width: dw, height: dh)
        self.imageScale = scale
    }

    //(3)検出結果の描画
    override func draw(_ rect: CGRect) {
        if texts == nil {return}

        //グラフィックスコンテキストの生成
        let context = UIGraphicsGetCurrentContext()!
        
        //テキスト検出の描画
        for block in self.texts.blocks {
            for line in block.lines {
                for element in line.elements {
                    //領域の描画
                    let rect = convertRect(element.frame)
                    context.setFillColor(COLOR_BLUE.cgColor)
                    context.fill(rect)

                    //テキストの描画
                    drawText(context, text: element.text,
                        fontSize: 12, rect: rect)
                }
            }
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
    
    //検出結果の座標系を画面の座標系に変換
    func convertRect(_ rect:CGRect) -> CGRect {
        return CGRect(
            x: Int(imageRect.minX+rect.minX*imageScale),
            y: Int(imageRect.minY+rect.minY*imageScale),
            width: Int(rect.width*imageScale),
            height: Int(rect.height*imageScale))
    }
}
