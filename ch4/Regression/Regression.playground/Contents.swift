import CreateML
import SpriteKit
import PlaygroundSupport

//データセットの読み込み
let url = Bundle.main.url(forResource: "winequality-red", withExtension: "csv")!
let data = try MLDataTable(contentsOf: url)
print(data)

//訓練データと評価データの分割
let (train_data, test_data) = data.randomSplit(by: 0.8, seed: 5)


//学習
let regressor = try MLRegressor(trainingData: train_data,
    targetColumn: "quality")


//訓練データのRMSE
print("Training RMSE: ", regressor.trainingMetrics.rootMeanSquaredError)

//検証データのRMSE
print("Validation RMSE: ", regressor.validationMetrics.rootMeanSquaredError)


//評価
let evaluation = regressor.evaluation(on: test_data)

//評価データのRMSE
print("Evaluation RMSE: ", evaluation.rootMeanSquaredError)


//モデルのメタデータの作成
let metadata = MLModelMetadata(
    author: "npaka",
    shortDescription: "赤ワイン品質予測モデル",
    version: "1.0")

//モデルの保存先の作成
let directory = playgroundSharedDataDirectory.appendingPathComponent(
    "Regression.mlmodel")

//モデルの保存
try regressor.write(to: directory, metadata: metadata)
