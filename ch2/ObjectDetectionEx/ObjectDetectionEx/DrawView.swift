import UIKit
import Vision

//描画ビュー
class DrawView: UIView {
    //定数
    let COLOR_BLUE: UIColor = UIColor.blue
    let COLOR_WHITE: UIColor = UIColor.white

    //プロパティ
    var imageRect: CGRect = CGRect.zero
    var objects: [VNRecognizedObjectObservation]!

    //画像サイズの指定
    func setImageSize(_ imageSize: CGSize) {
        //(3)画像の表示領域の計算（AspectFit）
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
    }
    
    //(4)検出結果の描画
    override func draw(_ rect: CGRect) {
        if self.objects == nil {return}
        
        //グラフィックスコンテキストの生成
        let context = UIGraphicsGetCurrentContext()!

        //Non-maximum suppressionの適用
        objects = nonMmaximumSuppression(objects)

        //検出結果の描画
        for object in objects {
            //領域の描画
            let rect = convertRect(object.boundingBox)
            context.setStrokeColor(COLOR_BLUE.cgColor)
            context.setLineWidth(2)
            context.stroke(rect)

            //ラベルの表示
            let label = object.labels.first!.identifier
            drawText(context, text: label, rect: rect)
        }
    }
    
    //(5)検出結果の座標系を画面の座標系に変換
    func convertRect(_ rect:CGRect) -> CGRect {
        return CGRect(
            x: self.imageRect.minX + rect.minX * self.imageRect.width,
            y: self.imageRect.minY + (1 - rect.maxY) * self.imageRect.height,
            width: rect.width * self.imageRect.width,
            height: rect.height * self.imageRect.height)
    }
    
    //テキストの描画
    func drawText(_ context: CGContext, text: String, rect: CGRect) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attributes = [
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16),
            NSAttributedString.Key.foregroundColor: UIColor.white
        ]
        let attributedString = NSAttributedString(
            string: text, attributes: attributes)
        context.setFillColor(COLOR_BLUE.cgColor)
        let textRect = CGRect(x: rect.minX, y: rect.minY-16, width: rect.width, height: 16)
        context.fill(textRect)
        attributedString.draw(in: textRect)
    }
    
    //(6)IoU値の計算
    func IoU(_ a: CGRect, _ b: CGRect) -> Float {
        let intersection = a.intersection(b)
        let union = a.union(b)
        return Float((intersection.width * intersection.height) /
            (union.width * union.height))
    }

    //(7)Non-maximum suppressionの適用
    func nonMmaximumSuppression(_ objects : [VNRecognizedObjectObservation])
         -> [VNRecognizedObjectObservation] {
        let nms_threshold: Float = 0.3 //IoU値の閾値
        var results: [VNRecognizedObjectObservation] = [] //結果配列
        var keep = [Bool](repeating: true, count: objects.count) //保持フラグ

        //信頼度順（高い順）でソート
        let orderedObjects = objects.sorted {$0.confidence > $1.confidence}
        
        for i in 0..<orderedObjects.count {
            if keep[i] {
                //信頼度順に結果配列に追加
                results.append(orderedObjects[i])
                
                //信頼度順にIoU値の閾値以上の領域を抑制
                let bbox1 = orderedObjects[i].boundingBox
                for j in (i+1)..<orderedObjects.count {
                    if keep[j] {
                        let bbox2 = orderedObjects[j].boundingBox
                        if IoU(bbox1, bbox2) > nms_threshold {
                            keep[j] = false
                        }
                    }
                }
            }
        }
        return results
    }
}
