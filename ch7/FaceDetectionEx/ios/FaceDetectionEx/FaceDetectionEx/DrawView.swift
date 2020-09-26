import UIKit
import FirebaseMLVision

//描画ビュー
class DrawView: UIView {
    //定数
    let COLOR_BLUE: UIColor = UIColor(red: 0.0, green: 0.0, blue: 255.0, alpha: 0.5)
    let COLOR_WHITE: UIColor = UIColor.white

    //プロパティ
    var imageRect: CGRect = CGRect.zero
    var imageScale: CGFloat = 1
    var faces: [VisionFace]! = nil

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
        self.imageScale = scale
    }

    //(5)検出結果の描画
    override func draw(_ rect: CGRect) {
        if self.faces == nil {return}
        
        //グラフィックスコンテキストの生成
        let context = UIGraphicsGetCurrentContext()!
        
        //顔検出の描画
        for face in self.faces {
            //領域の描画
            let rect = convertRect(face.frame)
            context.setStrokeColor(COLOR_BLUE.cgColor)
            context.setLineWidth(2)
            context.stroke(rect)

            //ランドマークの描画
            context.setFillColor(COLOR_WHITE.cgColor)
            drawLandmark(context, face: face, type: .leftEye)
            drawLandmark(context, face: face, type: .rightEye)
            drawLandmark(context, face: face, type: .mouthLeft)
            drawLandmark(context, face: face, type: .mouthRight)
            drawLandmark(context, face: face, type: .mouthBottom)

            //笑顔確率の表示
            if face.hasSmilingProbability {
                let text = String(format:"%d%%",Int(face.smilingProbability*100))
                drawText(context, text: text, rect: rect)
            }
        }
    }
    
    //ランドマークの描画
    func drawLandmark(_ context: CGContext, face: VisionFace, type: FaceLandmarkType) {
        if let landmark = face.landmark(ofType: type) {
            let point = convertPoint(CGPoint(
                x: landmark.position.x.intValue,
                y: landmark.position.y.intValue))
            context.fillEllipse(in: CGRect(
                x: point.x-3,
                y: point.y-3,
                width: 6, height: 6))
        }
    }
    
    //テキストの描画
    func drawText(_ context: CGContext, text: String, rect: CGRect) {
        //背景
        let textRect = CGRect(x: rect.minX, y: rect.minY-16,
            width: rect.width, height: 16)
        context.setFillColor(COLOR_BLUE.cgColor)
        context.fill(textRect)

        //テキスト
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attributes = [
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16),
            NSAttributedString.Key.foregroundColor: UIColor.white
        ]
        let attributedString = NSAttributedString(
            string: text, attributes: attributes)
        attributedString.draw(in: textRect)
    }
    
    //検出結果の座標系を画面の座標系に変換
    func convertRect(_ rect: CGRect) -> CGRect {
        return CGRect(
            x: Int(imageRect.minX+rect.minX*imageScale),
            y: Int(imageRect.minY+rect.minY*imageScale),
            width: Int(rect.width*imageScale),
            height: Int(rect.height*imageScale))
    }

    //検出結果の座標系を画面の座標系に変換
    func convertPoint(_ point: CGPoint) -> CGPoint {
        return CGPoint(
            x: Int(imageRect.minX+point.x*imageScale),
            y: Int(imageRect.minY+point.y*imageScale))
    }
}
