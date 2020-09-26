import UIKit
import Firebase //(1)

//AppDelegate
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    //アプリ起動時に呼ばれる
    func application(_ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions:
        [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        //(2)Firebaseの設定
        FirebaseApp.configure()
        return true
    }
}
