import UIKit
import AVFoundation
import Vision

//物体移動トラッキング
class ViewController: UIViewController,
    AVCaptureVideoDataOutputSampleBufferDelegate,
    UIGestureRecognizerDelegate {
    //UI
    @IBOutlet weak var drawView: DrawView!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    //(3)シーケンスリクエストハンドラの生成
    var handler = VNSequenceRequestHandler()

    
//====================
//ライフサイクル
//====================
    //ロード時に呼ばれる
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //タップジェスチャーの追加
        let tapGesture = UITapGestureRecognizer(
            target: self, action: #selector(ViewController.onTapped))
        tapGesture.delegate = self
        self.view.addGestureRecognizer(tapGesture)
        
        //ロングプレスジェスチャーの開始
        let longPressGesture = UILongPressGestureRecognizer(
            target: self, action: #selector(ViewController.onLongPressed))
        longPressGesture.delegate = self
        self.view.addGestureRecognizer(longPressGesture)
    }
    
    //ビュー表示時に呼ばれる
    override func viewDidAppear(_ animated: Bool) {
        //カメラキャプチャの開始
        startCapture()
    }
    
    
 //====================
 //イベント
 //====================
    //(2)タップ時に呼ばれる
    @objc func onTapped(_ sender: UITapGestureRecognizer) {
        //画面の座標系のターゲット領域
        let position = sender.location(in: self.drawView)
        var rect = CGRect(
            x: position.x-50, y: position.y+50,
            width: 100, height: 100)

        //画面の座標系を検出結果の座標系に変換
        rect = self.drawView.inversConvertRect(rect)
        if (rect == CGRect.zero) {return}

        //VNDetectedObjectObservationの生成
        self.drawView.target = VNDetectedObjectObservation(boundingBox: rect)
    }
 
    //(3)ロングプレス時に呼ばれる
    @objc func onLongPressed(_ sender: Any) {
        DispatchQueue.main.async {
            //ターゲットの解除
            self.drawView.target = nil
            
            //UIの更新
            self.drawView.setNeedsDisplay()
        }
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
//カメラキャプチャ
//====================
    //カメラキャプチャの開始
    func startCapture() {
        //セッションの初期化
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSession.Preset.photo

        //入力の指定
        let captureDevice: AVCaptureDevice! = self.device(false)
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else {return}
        guard captureSession.canAddInput(input) else {return}
        captureSession.addInput(input)
        
        //出力の指定
        let output: AVCaptureVideoDataOutput = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "VideoQueue"))
        guard captureSession.canAddOutput(output) else {return}
        captureSession.addOutput(output)
        let videoConnection = output.connection(with: AVMediaType.video)
        videoConnection!.videoOrientation = .portrait

        //プレビューの指定
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewLayer.frame = self.drawView.frame
        self.view.layer.insertSublayer(previewLayer, at: 0)
        
        //カメラキャプチャの開始
        captureSession.startRunning()
    }
    
    //デバイスの取得
    func device(_ frontCamera: Bool) -> AVCaptureDevice! {
        let position: AVCaptureDevice.Position = frontCamera ? .front : .back
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera],
            mediaType: AVMediaType.video,
            position: AVCaptureDevice.Position.unspecified)
        let devices = deviceDiscoverySession.devices
        for device in devices {
            if device.position == position {
                return device
            }
        }
        return nil
    }

    //カメラキャプチャの取得時に呼ばれる
    func captureOutput(_ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection) {
        predict(sampleBuffer)
    }
    
    
//====================
//物体移動トラッキング
//====================
    //(1)予測
    func predict(_ sampleBuffer: CMSampleBuffer) {
        //画像サイズの指定
        DispatchQueue.main.async {
            let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
            self.drawView.setImageSize(CGSize(
                width: CGFloat(CVPixelBufferGetWidth(imageBuffer!)),
                height: CGFloat(CVPixelBufferGetHeight(imageBuffer!))))
        }

        //リクエストの生成
        if (self.drawView.target == nil) {return}
        let request = VNTrackObjectRequest(
            detectedObjectObservation: self.drawView.target) {
            request, error in
            //エラー処理
            if error != nil {
                self.showAlert(error!.localizedDescription)
                return
            }
            
            DispatchQueue.main.async {
                //検出情報の取得
                self.drawView.target = (request.results!.first! as!
                    VNDetectedObjectObservation)
                
                //UIの更新
                self.drawView.setNeedsDisplay()
            }
        }
        
        //位置精度を優先
        request.trackingLevel = .accurate

        //CMSampleBufferをCVPixelBufferに変換
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
 
        //シーケンスリクエストハンドラの実行
        guard (try? handler.perform([request], on: pixelBuffer)) != nil else {return}
    }
}
