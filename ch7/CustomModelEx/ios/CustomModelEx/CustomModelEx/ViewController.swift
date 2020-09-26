import UIKit
import FirebaseMLModelInterpreter

//カスタムモデル
class ViewController: UIViewController,
    UINavigationControllerDelegate,
    UIImagePickerControllerDelegate,
    UIGestureRecognizerDelegate {
    //UI
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var lblText: UILabel!
    
    //情報
    var labels: [String]! = nil
    var interpreter: ModelInterpreter! = nil
    

//====================
//ライフサイクル
//====================
    //ビューロード時に呼ばれる
    override func viewDidLoad() {
        //モデルの初期化
        initModel()
    }
    
    //モデルの初期化
    func initModel() {
        //(1)ラベルの読み込み
        let filePath = Bundle.main.path(forResource: "labels", ofType: "txt")!
        let text = try? String(contentsOfFile: filePath, encoding: String.Encoding.utf8)
        labels = text?.components(separatedBy: "\n")
        
        //(2)クラウドモデルの自動更新の条件の生成
        let conditions = ModelDownloadConditions(
            isWiFiRequired: true,
            canDownloadInBackground: true)
        
        //(3)クラウドモデルソースの登録
        let cloudModelSource = CloudModelSource(
            modelName: "mobilenet",
            enableModelUpdates: true,
            initialConditions: conditions,
            updateConditions: conditions
        )
        if !ModelManager.modelManager()
            .register(cloudModelSource) {return}
        
        //(4)ローカルモデルソースの登録
        let modelPath = Bundle.main.path(
            forResource: "mobilenet_quant_v1_224",
            ofType: "tflite")
        let localModelSource = LocalModelSource(
            modelName: "local_mobilenet",
            path: modelPath!)
        if !ModelManager.modelManager()
            .register(localModelSource) {return}
        
        //(5)カスタムモデルの検出器の生成
        let options = ModelOptions(
            cloudModelName: "mobilenet",
            localModelName: "local_mobilenet"
        )
        self.interpreter = ModelInterpreter.modelInterpreter(options: options)
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
        let size = image.size;
        UIGraphicsBeginImageContext(size);
        image.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext();

        //イメージの指定
        self.imageView.image = image
        
        //クローズ
        picker.presentingViewController!.dismiss(animated:true, completion:nil)

        //予測
        predict(image)
    }
    
    //イメージピッカーのキャンセル時に呼ばれる
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        //クローズ
        picker.presentingViewController!.dismiss(animated:true, completion:nil)
    }
    
    
//====================
//予測
//====================
    //予測
    func predict(_ image: UIImage!) {
        DispatchQueue.global(qos: .default).async {
            //(6)モデルの入力形式と出力形式の指定
            let ioOptions = ModelInputOutputOptions()
            do {
                try ioOptions.setInputFormat(index: 0, type: .uInt8, dimensions: [1, 224, 224, 3])
                try ioOptions.setOutputFormat(index: 0, type: .uInt8, dimensions: [1, 1001])
            } catch let error as NSError {
                print(error.localizedDescription)
                return
            }
            
            //(7)モデルの入力データの指定
            let data: Data = self.image2inputData(image,
                size: CGSize(width:224, height:224))!
            let input = ModelInputs()
            do {
                try input.addInput(data)
            } catch let error as NSError {
                print(error.localizedDescription)
                return
            }
            
            //(9)予測の実行
            self.interpreter.run(inputs: input, options: ioOptions) {
                outputs, error in
                //エラー処理
                if error != nil {
                    self.showAlert(error!.localizedDescription)
                    return
                }

                //検出結果の取得
                let outputs = try? outputs?.output(index: 0)
                if (outputs == nil) {return}
                
                //outputsをenumerateに変換
                let inArray = (outputs as! NSArray)[0] as! NSArray
                let count = inArray.count
                var outArray = [UInt8]()
                for r in 0..<count {
                    outArray.append(UInt8(truncating: inArray[r] as! NSNumber))
                }
                let enumerate = outArray.enumerated()

                //信頼度順にソート
                let sorted = enumerate.sorted(by: {$0.element > $1.element})
                var text: String = "\n"
                for i in 0..<min(3, sorted.count) { //上位3件
                    let index = sorted[i].offset //Index
                    let accuracy = Int(Float(sorted[i].element)*100.0/255.0) //信頼度
                    text += String(format:"%@ : %d%%\n", self.labels[index], accuracy)
                }
                
                //UIの更新
                DispatchQueue.main.async {
                    self.lblText.text = text
                }
            }
        }
    }
    
    //(8)UIImageを多次元配列に変換
    func image2inputData(_ image: UIImage, size: CGSize) -> Data? {
        let cgImage = image.cgImage!
        
        //CGImageのリサイズとRGBAのDataへの変換
        let rgbaData = self.cgImage2rgbaData(cgImage, size: size)!

        //RGBAのDataをRGBのDataに変換
        let count = Int(size.width)*Int(size.height)*3*1
        var rgbData = [UInt8](repeating: 0, count: count)
        var pixelIndex = 0
        for pixel in rgbaData.enumerated() {
            if (pixel.offset % 4) == 3 {continue}
            rgbData[pixelIndex] = pixel.element
            pixelIndex += 1
        }
        let inputData = Data(bytes: rgbData)
        return inputData
    }
  
    //CGImageのリサイズとRGBAのDataへの変換
    func cgImage2rgbaData(_ image: CGImage, size: CGSize) -> Data? {
        let bitmapInfo = CGBitmapInfo(rawValue:
            CGBitmapInfo.byteOrder32Big.rawValue | //32bitのbig endian
            CGImageAlphaInfo.premultipliedLast.rawValue //Aが最下位bit
        )
        let context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: image.bitsPerComponent,
            bytesPerRow: 4*Int(size.width),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: bitmapInfo.rawValue)
        if (context == nil) {return nil}
        context!.draw(image, in: CGRect(x: 0, y: 0,
            width: Int(size.width), height: Int(size.height)))
        return context!.makeImage()?.dataProvider?.data as Data?
    }
}
