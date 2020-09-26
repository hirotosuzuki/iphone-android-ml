import UIKit

//回帰
class ViewController: UIViewController {

    //ビューロード時に呼ばれる
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //予測
        let model = Regression()
        let prediction = try! model.prediction(
            fixed_acidity: 7.4,
            volatile_acidity: 0.7,
            citric_acid: 0,
            residual_sugar: 1.9,
            chlorides: 0.076,
            free_sulfur_dioxide: 11,
            total_sulfur_dioxide: 34,
            density: 0.9978,
            pH: 3.51,
            sulphates: 0.56,
            alcohol: 9.4)
        print("Prediction : \(prediction.quality)")
    }
}

