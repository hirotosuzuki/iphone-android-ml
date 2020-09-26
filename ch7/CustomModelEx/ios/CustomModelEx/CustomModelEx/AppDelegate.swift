import UIKit
import Firebase

//AppDelegate
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    //アプリ起動時に呼ばれる
    func application(_ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions:
        [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        //Firebaseの設定
        FirebaseApp.configure()
        return true
    }
}
