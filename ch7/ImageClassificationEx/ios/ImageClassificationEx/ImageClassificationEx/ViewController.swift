import UIKit
import FirebaseMLVision //(3)

//ラベリング（写真）
class ViewController: UIViewController,
    UINavigationControllerDelegate,
    UIImagePickerControllerDelegate {
    //UI
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var lblText: UILabel!
    @IBOutlet weak var segmentControl: UISegmentedControl!


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

        //予測
        if self.segmentControl.selectedSegmentIndex == 0 {
            detectLabels(image)
        } else {
            detectCloudLabels(image)
        }
    }
    
    //イメージピッカーのキャンセル時に呼ばれる
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        //クローズ
        picker.presentingViewController!.dismiss(animated:true, completion:nil)
    }
    
    
//====================
//画像分類（画像）
//====================
    //オンデバイスAPIの画像分類（画像）
    func detectLabels(_ image: UIImage!) {
        DispatchQueue.global(qos: .default).async {
            //(4)VisionImageの生成
            let visionImage = VisionImage(image: image)
            let imageMetadata = VisionImageMetadata()
            imageMetadata.orientation = self.image2orientation(image)
            visionImage.metadata = imageMetadata
            
            //(5)オプションの生成
            let options = VisionLabelDetectorOptions(
                confidenceThreshold: 0.75)
            
            //(6)画像分類の検出器の生成
            let labelDetector = Vision.vision().labelDetector(options: options)

            //(7)画像分類の実行
            labelDetector.detect(in: visionImage) {
                features, error in
                //エラー処理
                if error != nil {
                    self.showAlert(error!.localizedDescription)
                    return
                }

                //検出結果の取得
                var text = "\n"
                for feature in features! {
                    text += String(format:"%@ : %d%%\n",
                        feature.label, Int(100*feature.confidence))
                }

                //UIの更新
                DispatchQueue.main.async {
                    self.lblText.text = text
                }
            }
        }
    }

    //クラウドAPIの画像分類（画像）
    func detectCloudLabels(_ image: UIImage) {
        DispatchQueue.global(qos: .default).async {
            //VisionImageの生成
            let visionImage = VisionImage(image: image)
            let imageMetadata = VisionImageMetadata()
            imageMetadata.orientation = self.image2orientation(image)
            visionImage.metadata = imageMetadata

            //(8)画像分類のオプションの生成
            let options = VisionCloudDetectorOptions()
            options.modelType = .latest
            options.maxResults = 20

            //(9)画像分類の検出器の生成
            let labelDetector = Vision.vision().cloudLabelDetector(options: options)

            //(10)画像分類の実行
            labelDetector.detect(in: visionImage) {
                labels, error in
                //エラー処理
                if error != nil {
                    self.showAlert(error!.localizedDescription)
                    return
                }

                //検出結果の取得
                var text = "\n"
                for label in labels! {
                    text += String(format:"%@ : %d%%\n",
                        label.label!,
                        Int(100*label.confidence!.floatValue))
                }

                //UIの更新
                DispatchQueue.main.async {
                    self.lblText.text = text
                }
            }
        }
    }

    //(4)UIImage→VisionDetectorImageOrientation
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
