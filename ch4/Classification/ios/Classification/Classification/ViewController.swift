import UIKit

//分類
class ViewController: UIViewController {
    //ビュー表示時に呼ばれる
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //予測
        let model = Classification()
        let prediction = try! model.prediction(
            cap_shape: "x",
            cap_surface: "s",
            cap_color: "n",
            bruises: "t",
            odor: "p",
            gill_attachment: "f",
            gill_spacing: "c",
            gill_size: "n",
            gill_color: "k",
            stalk_shape: "e",
            stalk_root: "e",
            stalk_surface_above_ring: "s",
            stalk_surface_below_ring: "s",
            stalk_color_above_ring: "w",
            stalk_color_below_ring: "w",
            veil_type: "p",
            veil_color: "w",
            ring_number: "o",
            ring_type: "p",
            spore_print_color: "k",
            population: "s",
            habitat: "u")
        print("Prediction : \(prediction.label)")
    }
}

