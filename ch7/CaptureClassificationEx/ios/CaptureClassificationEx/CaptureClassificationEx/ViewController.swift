import UIKit
import AVFoundation
import FirebaseMLVision

//ラベリング（動画）
class ViewController: UIViewController,
    AVCaptureVideoDataOutputSampleBufferDelegate {
    //UI
    @IBOutlet weak var lblText:UILabel!
    @IBOutlet weak var drawView: UIView!
    var previewLayer: AVCaptureVideoPreviewLayer!


//====================
//ライフサイクル
//====================
    //ビュー表示時に呼ばれる
    override func viewDidAppear(_ animated: Bool) {
        //カメラキャプチャの開始
        startCapture()
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
    //(1)カメラキャプチャの開始
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
        //予測
        detecteImage(sampleBuffer)
    }
    
    
//====================
//画像分類（カメラ映像）
//====================
    //オンデバイスAPIの画像分類（カメラ映像）
    func detecteImage(_ sampleBuffer: CMSampleBuffer) {
        //VisionImageの生成(2)
        let visionImage = VisionImage(buffer: sampleBuffer)
        
        //画像分類のオプションの生成
        let options = VisionLabelDetectorOptions(
            confidenceThreshold: 0.75)
        
        //画像分類の検出器の生成
        let labelDetector = Vision.vision().labelDetector(options: options)

        //画像分類の実行
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
                    label.label, Int(100*label.confidence))
            }

            //UIの更新
            DispatchQueue.main.async {
                self.lblText.text = text
            }
        }
    }
}
