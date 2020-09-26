import UIKit
import Vision

//描画ビュー
class DrawView: UIView {
    //定数
    let COLOR_BLUE: UIColor = UIColor(red: 0.0, green: 0.0, blue: 255.0, alpha: 0.5)
    let COLOR_WHITE: UIColor = UIColor.white

    //プロパティ
    var imageRect: CGRect = CGRect.zero
    var faces: [VNFaceObservation]!

    //画像サイズの指定
    func setImageSize(_ imageSize: CGSize) {
        //(2)画像の表示領域の計算（AspectFill）
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
        if self.faces == nil {return}
        
        //グラフィックスコンテキストの生成
        let context = UIGraphicsGetCurrentContext()!

        //顔検出の描画
        for face in faces {
            //領域の描画
            let rect = convertRect(face.boundingBox)
            context.setStrokeColor(COLOR_BLUE.cgColor)
            context.setLineWidth(2)
            context.stroke(rect)
            
            //顔のランドマークの描画
            context.setStrokeColor(COLOR_WHITE.cgColor)
            context.setLineWidth(2)
            if face.landmarks != nil {
                drawLandmark(context, region:face.landmarks!.faceContour!, rect: rect)
                drawLandmark(context, region:face.landmarks!.leftEye!, rect: rect)
                drawLandmark(context, region:face.landmarks!.rightEye!, rect: rect)
                drawLandmark(context, region:face.landmarks!.nose!, rect: rect)
                drawLandmark(context, region:face.landmarks!.innerLips!, rect: rect)
            }
        }
    }
    
    //顔のランドマークの描画
    func drawLandmark(_ context: CGContext, region: VNFaceLandmarkRegion2D!, rect: CGRect) {
        let points = region!.normalizedPoints
        context.move(to: convertPoint(points[0], rect:rect))
        for i in 1..<points.count {
            context.addLine(to: convertPoint(points[i], rect:rect))
        }
        context.strokePath()
    }
    
    //検出領域の座標系を画面の座標系に変換
    func convertRect(_ rect:CGRect) -> CGRect {
        return CGRect(
            x: self.imageRect.minX + rect.minX * self.imageRect.width,
            y: self.imageRect.minY + (1 - rect.maxY) * self.imageRect.height,
            width: rect.width * self.imageRect.width,
            height: rect.height * self.imageRect.height)
    }

    //(4)検出結果の座標系を画面の座標系に変換
    func convertPoint(_ point:CGPoint, rect:CGRect) -> CGPoint {
        return CGPoint(
            x: rect.minX + point.x * rect.size.width,
            y: rect.minY + (1 - point.y) * rect.size.height)
    }
}
