import UIKit
import FirebaseMLVision

//テキスト認識
class ViewController: UIViewController,
    UINavigationControllerDelegate,
    UIImagePickerControllerDelegate {
    //UI
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var drawView: DrawView!
    @IBOutlet weak var segmentControl: UISegmentedControl!

    //情報
    var isCloud: Bool = false
    //var textDetector: VisionTextRecognizer!
    //var cloudTextDetector: VisionCloudTextDetector!


//====================
//ライフサイクル
//====================
    //ビュー表示時に呼ばれる
    override func viewDidAppear(_ animated: Bool) {
        //(1)オンデバイスAPIのテキスト認識の検出器の生成
        //textDetector = Vision.vision().textDetector()

        //(4)クラウドAPIのテキスト認識の検出器の生成
        //cloudTextDetector = Vision.vision().cloudTextDetector()

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
        
        //画像の向きの補正
        let size = image.size
        UIGraphicsBeginImageContext(size)
        image.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        //イメージの指定
        self.imageView.image = image
        
        //クローズ
        picker.presentingViewController!.dismiss(animated:true, completion:nil)

        //予測
        if self.segmentControl.selectedSegmentIndex == 0 {
            detectText(image)
        } else {
            detectCloudText(image)
        }
    }
    
    //イメージピッカーのキャンセル時に呼ばれる
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        //クローズ
        picker.presentingViewController!.dismiss(animated:true, completion:nil)
    }
    
    
//====================
//テキスト認識
//====================
    //オンデバイスAPIのテキスト認識
    func detectText(_ image: UIImage) {
        //画像サイズの指定
        self.drawView.setImageSize(image.size)
        
        DispatchQueue.global(qos: .default).async {
            //VisionImageの生成
            let visionImage = VisionImage(image: image)
            let imageMetadata = VisionImageMetadata()
            imageMetadata.orientation = self.image2orientation(image)
            visionImage.metadata = imageMetadata

            //(1)テキスト認識の検出器の生成
            let textRecognizer = Vision.vision().onDeviceTextRecognizer()

            //(2)テキスト認識の実行
            textRecognizer.process(visionImage) {
                texts, error in
                //エラー処理
                if error != nil {
                    self.showAlert(error!.localizedDescription)
                    return
                }

                DispatchQueue.main.async {
                    //検出結果の取得
                    self.drawView.texts = texts

                    //UIの更新
                    self.drawView.setNeedsDisplay()
                }
            }
        }
    }

    //クラウドAPIのテキスト認識
    func detectCloudText(_ image: UIImage) {
        //画像サイズの指定
        self.drawView.setImageSize(image.size)
        
        DispatchQueue.global(qos: .default).async {
            //VisionImageの生成
            let visionImage = VisionImage(image: image)
            let imageMetadata = VisionImageMetadata()
            imageMetadata.orientation = self.image2orientation(image)
            visionImage.metadata = imageMetadata
            
            //(4)テキスト認識の検出器の生成
            let textRecognizer = Vision.vision().cloudTextRecognizer()
            
            //(5)テキスト認識の実行
            textRecognizer.process(visionImage) {
                texts, error in
                //エラー処理
                if error != nil {
                    self.showAlert(error!.localizedDescription)
                    return
                }

                DispatchQueue.main.async {
                    //検出結果の取得
                    self.drawView.texts = texts
                    
                    //UIの更新
                    self.drawView.setNeedsDisplay()
                }
            }
        }
    }

    //UIImage→VisionDetectorImageOrientation
    func image2orientation(_ image: UIImage) -> VisionDetectorImageOrientation {
        switch image.imageOrientation {
        case .up:
            return .topLeft
        case .down:
            return .bottomRight
        case .left:
            return .leftBottom
        case .right:
            return .rightTop
        case .upMirrored:
            return .topRight
        case .downMirrored:
            return .bottomLeft
        case .leftMirrored:
            return .leftTop
        case .rightMirrored:
            return .rightBottom
        }
    }
}
