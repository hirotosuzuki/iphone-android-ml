import UIKit
import AVFoundation
import FirebaseMLVision

//顔検出
class ViewController: UIViewController,
    AVCaptureVideoDataOutputSampleBufferDelegate {
    //UI
    @IBOutlet weak var drawView: DrawView!
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
        //予測
        detecteFace(sampleBuffer)
    }
    
    
//====================
//顔検出
//====================
    //オンデバイスAPIの顔検出
    func detecteFace(_ sampleBuffer: CMSampleBuffer) {
        //(1)画面サイズの指定
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        self.drawView.setImageSize(CGSize(
            width: CGFloat(CVPixelBufferGetWidth(imageBuffer!)),
            height: CGFloat(CVPixelBufferGetHeight(imageBuffer!))))
        
        //VisionImageの生成
        let visionImage = VisionImage(buffer: sampleBuffer)

        //(2)顔検出のオプションの生成
        let options = VisionFaceDetectorOptions()
        options.landmarkType = .all
        options.classificationType = .all
        options.modeType = .accurate
    
        //(3)顔検出の検出器の生成
        let faceDetector = Vision.vision().faceDetector(options: options)
        
        //(4)顔検証の実行
        faceDetector.detect(in: visionImage) {
            faces, error in
            //エラー処理
            if error != nil {
                self.showAlert(error!.localizedDescription)
                return
            }
            
            DispatchQueue.main.async {
                //検出結果の取得
                self.drawView.faces = faces
                
                //UIの更新
                self.drawView.setNeedsDisplay()
            }
        }
    }
}