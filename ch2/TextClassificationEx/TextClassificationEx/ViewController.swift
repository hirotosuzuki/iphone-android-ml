import UIKit
import CoreML
import Vision
import NaturalLanguage

//テキスト分類
class ViewController: UIViewController,
    UITextViewDelegate {
    //UI
    @IBOutlet weak var textView: UITextField!
    @IBOutlet weak var lblText: UILabel!

    //モデルの生成
    let model = TextClassification()


//====================
//ライフサイクル
//====================
    //ロード完了時に呼ばれる
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //UI
        self.textView.layer.borderColor = UIColor.black.cgColor
        self.textView.layer.borderWidth = 1.0
        self.textView.layer.cornerRadius = 8.0
        self.textView.layer.masksToBounds = true
    }
    
    
//====================
//テキストビュー
//====================
    //テキスト入力開始時に呼ばれる
    func textViewDidBeginEditing(_ textView: UITextView) {
        self.lblText.text = ""
    }
    
    //テキスト入力完了時に呼ばれる
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange,
        replacementText text: String) -> Bool {
        if text == "\n" {
            self.textView.resignFirstResponder()

            //テキスト分類
            if self.textView.text != nil && !self.textView.text!.isEmpty {
                predict(textView.text!)
            }
            return false;
        }
        return true;
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
//テキスト分類
//====================
    //(2)予測
    func predict(_ text: String) {
        DispatchQueue.global(qos: .default).async {
            //テキストをBag-of-wordsに変換
            let bagOfWords: [String: Double] = self.bagOfWords(text)
            
            //予測
            let prediction = try? self.model.prediction(text: bagOfWords)
     
            //UIの更新
            DispatchQueue.main.async {
                if prediction != nil {
                    self.lblText.text =
                        (prediction!.label == 0) ? "\nITライフハック\n" : "\nスポーツ\n"
                }
            }
        }
    }

    //(3)テキストをBag-of-wordsに変換
    func bagOfWords(_ text: String) -> [String: Double] {
        //結果変数の準備
        var bagOfWords = [String: Double]()
        
        //トークン化の準備
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        
        //トークン化の実行
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) {
            tokenRange, _ in
            
            //トークン化した単語
            let word = String(text[tokenRange])
            if (word.count == 1) {
            } else if bagOfWords[word] != nil {
                bagOfWords[word]! += 1
            } else {
                bagOfWords[word] = 1
            }
            return true
        }
        return bagOfWords
    }
}
