import UIKit
import CoreML
import Vision

//画像類似検索
class ViewController: UIViewController,
    UINavigationControllerDelegate,
    UIImagePickerControllerDelegate,
    UIGestureRecognizerDelegate {
    //UI
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var lblText: UILabel!
    
    //(1)モデルの生成
    var model = try! VNCoreMLModel(for: ImageSimilarity().model)


//====================
//ライフサイクル
//====================
    //ロード完了時に呼ばれる
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
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
        picker.presentingViewController!.dismiss(animated:true, completion:nil);

        //予測
        predict(image);
    }
    
    //イメージピッカーのキャンセル時に呼ばれる
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        //クローズ
        picker.presentingViewController!.dismiss(animated:true, completion:nil)
    }
    
    
//====================
//画像類似検索
//====================
    //(2)予測
    func predict(_ image: UIImage) {
        DispatchQueue.global(qos: .default).async {
            //リクエストの生成
            let request = VNCoreMLRequest(model: self.model) {
                request, error in
                //エラー処理
                if error != nil {
                    self.showAlert(error!.localizedDescription)
                    return
                }

                //検出結果の取得
                guard let results = request.results as?
                    [VNCoreMLFeatureValueObservation] else {return}
                let distances = results.first!.featureValue.multiArrayValue!

                //MLMultiArrayを[Double]に変換
                var distanceArray = [Double]()
                let count = distances.shape[0].intValue
                for r in 0..<count {
                    distanceArray.append(Double(truncating: distances[r]))
                }

                //類似距離順にソート
                let sorted = distanceArray.enumerated().sorted(by: {$0.element < $1.element})
                var text: String = "\n"
                for i in 0..<min(3, sorted.count) { //上位3件
                    let distance = sorted[i].element //類似距離
                    let identifier = sorted[i].offset //画像ID
                    text += String(format:"%d : %.2f\n", identifier, distance)
                }

                //UIの更新
                DispatchQueue.main.async {
                    self.lblText.text = text
                }
            }
            
            //入力画像のリサイズ指定
            request.imageCropAndScaleOption = VNImageCropAndScaleOption.centerCrop

            //UIImageをCIImageに変換
            let ciImage = CIImage(image: image)!
            
            //画像の向きの取得
            let orientation = CGImagePropertyOrientation(
                rawValue: UInt32(image.imageOrientation.rawValue))!

            //ハンドラの生成と実行
            let handler = VNImageRequestHandler(ciImage: ciImage, orientation:orientation)
            guard (try? handler.perform([request])) != nil else {return}
        }
    }
}
