import UIKit
import CoreML
import Vision

//画風変換
class ViewController: UIViewController,
    UINavigationControllerDelegate,
    UIImagePickerControllerDelegate {
    //UI
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var lblText: UILabel!
    @IBOutlet weak var segmentControl: UISegmentedControl!

    //(1)モデルの生成
    var model = StyleTransfer()
    
    //イメージの保持
    var image: UIImage! = nil


//====================
//ライフサイクル
//====================
    //ビュー表示時に呼ばれる
    override func viewDidAppear(_ animated: Bool) {
        //アクションシートの表示
        if self.imageView.image == nil {
            showActionSheet()
        }
    }
    
    
//====================
//イベント
//====================
    //画面タッチ時に呼ばれる
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        showActionSheet()
    }
    
    //セグメントコントロール値変更時に呼ばれる
    @IBAction func onValueChanged(sender: UISegmentedControl){
        //予測
        self.imageView.image = self.image
        let index = self.segmentControl.selectedSegmentIndex-1
        if index >= 0 {
            predict(self.image, styleIndex: index)
        }
    }


//====================
//アクションシート
//====================
    //アクションシートの表示
    func showActionSheet() {
        let actionSheet = UIAlertController(title: nil, message: nil,
            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "カメラ", style: .default) {
            action in
            self.openPicker(sourceType: .camera)
        })
        actionSheet.addAction(UIAlertAction(title: "フォトライブラリ", style: .default) {
            action in
            self.openPicker(sourceType: .photoLibrary)
        })
        actionSheet.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    
//====================
//アラート
//====================
    //アラートの表示
    func showAlert(_ text: String!) {
        let alert = UIAlertController(title: text, message: nil,
            preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK",
            style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
   
   
//====================
//イメージピッカー
//====================
    //イメージピッカーのオープン
    func openPicker(sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = self
        self.present(picker, animated: true, completion: nil)
    }

    //イメージピッカーのイメージ取得時に呼ばれる
    func imagePickerController(_ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        //イメージの取得
        var image = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        
        //画像向きの補正
        let size = image.size
        UIGraphicsBeginImageContext(size)
        image.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        //イメージの指定
        self.imageView.image = image
        
        //クローズ
        picker.presentingViewController!.dismiss(animated:true, completion:nil)

        //イメージの表示
        self.image = image
        self.segmentControl.selectedSegmentIndex = 0
        self.segmentControl.isEnabled = true
    }
    
    //イメージピッカーのキャンセル時に呼ばれる
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        //クローズ
        picker.presentingViewController!.dismiss(animated:true, completion:nil)
    }
    
    
//====================
//画風変換
//====================
    //(2)予測
    func predict(_ image: UIImage, styleIndex: Int) {
        self.image = image
        self.segmentControl.isEnabled = true
        DispatchQueue.global(qos: .default).async {
            //スタイル種別の指定
            let styleArray = try! MLMultiArray(
                shape: [2] as [NSNumber],
                dataType: MLMultiArrayDataType.double)
            for i in 0..<2 {
                styleArray[i] = 0.0
            }
            styleArray[styleIndex] = 1.0

            //画風変換の実行
            let resultImage = self.stylizeImage(image: image, styleArray: styleArray)

            //UIの更新
            DispatchQueue.main.async {
                self.imageView.image = resultImage
            }
        }
    }
    
    //(3)画風変換の実行
    func stylizeImage(image: UIImage, styleArray: MLMultiArray) -> UIImage! {
        //写真サイズを入力画像サイズにリサイズ
        let inputImage = self.resizeImage(image, size: CGSize(width:256, height:256))!

        //UIImageをCVPixelBufferに変換
        let pixelBuffer = self.uiImage2pixelBuffer(inputImage, width: 256, height: 256)!
        
        //モデルの予測の実行
        let output = try? model.prediction(image: pixelBuffer, index: styleArray)
        
        //CVPixelBufferをUIImageに変換
        let outputImage = UIImage(
            ciImage: CIImage(cvPixelBuffer: (output?.stylizedImage)!),
            scale: 1.0, orientation: image.imageOrientation)
        
        //出力画像サイズを写真サイズにリサイズ
        return resizeImage(outputImage, size: image.size)
    }
    
    //イメージのリサイズ
    func resizeImage(_ image: UIImage, size: CGSize) -> UIImage! {
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        UIGraphicsGetCurrentContext()
        image.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let resizeImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return resizeImage
    }
    
    //UIImageをCVPixelBufferに変換
    func uiImage2pixelBuffer(_ image: UIImage, width: Int, height: Int) -> CVPixelBuffer! {
        //UIImageをCIImageに変換
        let ciImage = CIImage(image: image)!

        //CVPixelBufferの生成
        var pixelBuffer: CVPixelBuffer?
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        CVPixelBufferCreate(kCFAllocatorDefault, width, height,
            kCVPixelFormatType_32BGRA, attrs, &pixelBuffer)

        //CVPixelBufferにCIImageを描画
        let context = CIContext()
        context.render(ciImage, to: pixelBuffer!)
        return pixelBuffer!
    }
}
