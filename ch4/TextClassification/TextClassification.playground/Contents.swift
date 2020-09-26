import CreateML
import SpriteKit
import PlaygroundSupport

//データセットの作成
var label = 0
var labels: [String] = []
var texts: [String] = []
let paths: [String] = [//★環境にあわせてパスを変更してください
    "/Users/furukawahidekazu/Documents/store/book/MLPhone/sample/ch4/TextClassification.playground/Resources/text/it-life-hack",
    "/Users/furukawahidekazu/Documents/store/book/MLPhone/sample/ch4/TextClassification.playground/Resources/text/sports-watch"]
for path in paths {
    let files = try FileManager.default.contentsOfDirectory(atPath: path)
    var count = 0;
    for file in files {
        //テキストの読み込み
        var text = try! String(contentsOfFile: path+"/"+file,
            encoding: String.Encoding.utf8)
        text = text.components(separatedBy: "\n")[3] //タイトルのみ抽出
        
        //テキストとラベルの追加
        texts.append(text)
        labels.append(String(label))
        
        //最大400
        count = count + 1
        if (count >= 400) {break}
    }
    label += 1
}
let dic: [String: MLDataValueConvertible] = [
    "text": texts,
    "label": labels
]
let data = try MLDataTable(dictionary: dic)
print(data)

//訓練データと評価データの分割
let (train_data, test_data) = data.randomSplit(by: 0.8, seed: 5)


//学習
let classifier = try MLTextClassifier(
    trainingData: train_data, textColumn: "text", labelColumn: "label")


//訓練データの正解率
let trainAccuracy = (1.0 - classifier.trainingMetrics.classificationError) * 100.0
print("Training Accuracy: ", trainAccuracy)

//検証データの正解率
let validAccuracy = (1.0 - classifier.validationMetrics.classificationError) * 100.0
print("Validation Accuracy: ", validAccuracy)


//評価
let evaluation = classifier.evaluation(on: test_data)

//評価データの正解率
let evalAccuracy = (1.0 - evaluation.classificationError) * 100.0
print("Evaluation Accuracy: ", evalAccuracy)


//モデルのメタデータの作成
let metadata = MLModelMetadata(
    author: "npaka",
    shortDescription: "ニュースカテゴリ予測モデル",
    version: "1.0")

//モデルの保存先の作成
let directory = playgroundSharedDataDirectory.appendingPathComponent(
    "TextClassification.mlmodel")

//モデルの保存
try classifier.write(to: directory, metadata: metadata)
