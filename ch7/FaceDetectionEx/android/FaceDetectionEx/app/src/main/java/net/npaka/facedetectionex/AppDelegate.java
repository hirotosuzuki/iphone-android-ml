package net.npaka.facedetectionex;
import android.Manifest;
import android.app.Activity;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.support.v4.app.ActivityCompat;
import android.support.v4.content.PermissionChecker;
import android.view.Window;

//AppDelegate
public class AppDelegate extends Activity {
    //パーミッション
    private final static int REQUEST_PERMISSONS = 0;
    private final static String[] PERMISSIONS = {
        Manifest.permission.CAMERA};
    private boolean permissionGranted = false;

    //ビューコントローラ
    private ViewController viewController;


//====================
//ライフサイクル
//====================
    //アプリ起動時に呼ばれる
    @Override
    public void onCreate(Bundle bundle) {
        super.onCreate(bundle);
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        viewController = new ViewController(this);
        setContentView(viewController);

        //ユーザーの利用許可の確認
        checkPermissions();
    }

    //アプリ再開時に呼ばれる
    protected void onRestart() {
        super.onRestart();
        if (this.permissionGranted) {
            this.viewController.startCamera();
        }
    }

    //アプリ停止時に呼ばれる
    protected void onStop() {
        super.onStop();
        this.viewController.stopCamera();
    }


//====================
//パーミッション
//====================
    //ユーザーの利用許可の確認
    private void checkPermissions() {
        //許可
        if (isGranted()) {
            this.permissionGranted = true;
            this.viewController.initCapture();
        }
        //未許可
        else {
            //許可ダイアログの表示
            ActivityCompat.requestPermissions(this, PERMISSIONS,
                REQUEST_PERMISSONS);
        }
    }

    //ユーザーの利用許可が済かどうかの取得
    private boolean isGranted() {
        for (int i  = 0; i < PERMISSIONS.length; i++) {
            if (PermissionChecker.checkSelfPermission(
                AppDelegate.this, PERMISSIONS[i]) !=
                PackageManager.PERMISSION_GRANTED) {
                return false;
            }
        }
        return true;
    }

    //許可ダイアログ選択時に呼ばれる
    @Override
    public void onRequestPermissionsResult(int requestCode,
        String permissions[], int[] results) {
        if (requestCode == REQUEST_PERMISSONS) {
            this.permissionGranted = true;
            this.viewController.initCapture();
        } else {
            super.onRequestPermissionsResult(
                requestCode, permissions, results);
        }
    }
}