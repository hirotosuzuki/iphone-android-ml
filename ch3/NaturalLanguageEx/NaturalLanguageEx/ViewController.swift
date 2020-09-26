import UIKit
import CoreML
import Vision
import NaturalLanguage //(1)

//自然言語処理
class ViewController: UIViewController, UITextViewDelegate {
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var lblText: UILabel!
    @IBOutlet weak var segmentedControl: UISegmentedControl!


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
        
        //自然言語処理の実行
        analyze()
    }
    
    
//====================
//イベント
//====================
    //セグメントコントロール変更時に呼ばれる
    @IBAction func onValueChanged(sender: UISegmentedControl) {
        //自然言語処理の実行
        analyze()
    }
    
    //テキストビュー完了時に呼ばれる
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange,
        replacementText text: String) -> Bool {
        if text == "\n" {
            self.textView.resignFirstResponder()

            //自然言語処理の実行
            analyze()
            return false;
        }
        return true;
    }
    
   
//====================
//自然言語処理
//====================
    //自然言語処理の実行
    func analyze() {
        if self.textView.text == nil || self.textView.text!.isEmpty {return}
        if self.segmentedControl.selectedSegmentIndex == 0 {
            self.language(self.textView.text!)
        } else if self.segmentedControl.selectedSegmentIndex == 1 {
            self.tokenize(self.textView.text!)
        } else if self.segmentedControl.selectedSegmentIndex == 2 {
            self.tagging(self.textView.text!)
        } else if self.segmentedControl.selectedSegmentIndex == 3 {
            self.lemmaization(self.textView.text!)
        } else if self.segmentedControl.selectedSegmentIndex == 4 {
            self.namedEntry(self.textView.text!)
        }
    }

    //(2)言語判定
    func language(_ text: String) {
        //言語判定の実行
        let tagger = NLTagger(tagSchemes: [.language])
        tagger.string = text
        let language = tagger.dominantLanguage!.rawValue
        
        //対応しているタグスキームの取得
        let schemes = NLTagger.availableTagSchemes(
            for: .word, language: NLLanguage(rawValue: language))
        var schemesText = "Schemes :\n"
        for scheme in schemes {
            schemesText += "    \(scheme.rawValue)\n"
        }

        //UIの更新
        self.lblText.text = "Language : \(language)\n\n\(schemesText)"
    }
    
    //(3)トークン化
    func tokenize(_ text: String) {
        self.lblText.text = ""
        
        //トークン化の準備
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        
        //トークン化の実行
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) {
            tokenRange, _ in
            self.lblText.text = self.lblText.text!+text[tokenRange]+"\n"
            return true
        }
    }
    
    //(4)品詞タグ付け
    func tagging(_ text: String) {
        self.lblText.text = ""
        
        //品詞タグ付けの準備
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text
        
        //品詞タグ付けの実行
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace]
        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
            unit: .word, scheme: .lexicalClass, options: options) {
            tag, tokenRange in
            self.lblText.text =
                self.lblText.text!+text[tokenRange]+" : "+tag!.rawValue+"\n"
            return true
        }
    }
    
    //(5)レンマ化
    func lemmaization(_ text: String) {
        self.lblText.text = ""
        
        //レンマ化の準備
        let tagger = NLTagger(tagSchemes: [.lemma])
        tagger.string = text
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace]
        
        //レンマ化の実行
        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
            unit: .word, scheme: .lemma, options: options) {
            tag, tokenRange in
            if tag != nil {
                self.lblText.text =
                    self.lblText.text!+text[tokenRange]+" : "+tag!.rawValue+"\n"
            }
            return true
        }
    }
    
    //(6)固有表現抽出
    func namedEntry(_ text: String) {
        self.lblText.text = ""
        
        //固有表現抽出の準備
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
        
        //固有表現抽出の実行
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word,
            scheme: .nameType, options: options) {
            tag, tokenRange in
            let tags: [NLTag] = [.personalName, .placeName, .organizationName]
            if let tag = tag, tags.contains(tag) {
                self.lblText.text =
                    self.lblText.text!+text[tokenRange]+" : "+tag.rawValue+"\n"
            }
            return true
        }
    }
}
