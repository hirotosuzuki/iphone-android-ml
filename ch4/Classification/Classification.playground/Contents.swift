import CreateML
import SpriteKit
import PlaygroundSupport

//データセットの読み込み
let url = Bundle.main.url(forResource: "agaricus-lepiota", withExtension: "csv")!
let data = try MLDataTable(contentsOf: url)
print(data)

//訓練データと評価データの分割
let (train_data, test_data) = data.randomSplit(by: 0.8, seed: 5)


//学習
let classifier = try MLClassifier(trainingData: train_data,
    targetColumn: "label")


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
    shortDescription: "毒キノコ予測モデル",
    version: "1.0")

//モデルの保存先の作成
let directory = playgroundSharedDataDirectory.appendingPathComponent(
    "Classification.mlmodel")

//モデルの保存
try classifier.write(to: directory, metadata: metadata)
