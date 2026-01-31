package br.app.omny.driver

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.app.PictureInPictureParams
import android.util.Rational
import android.content.Context
import android.content.res.Configuration
import android.os.Build
import android.os.LocaleList
import java.util.Locale

class MainActivity: FlutterFragmentActivity() {

    var pip = 0;

    override fun attachBaseContext(newBase: Context) {
        val locale = Locale("pt", "BR")
        Locale.setDefault(locale)
        val config = Configuration(newBase.resources.configuration)
        config.setLocale(locale)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            config.setLocales(LocaleList(locale))
        }
        super.attachBaseContext(newBase.createConfigurationContext(config))
    }

    private val channel = "flutter.app/awake"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel).setMethodCallHandler {
      call, result ->
      // This method is invoked on the main thread.
      // TODO
      if(call.method == "keepon"){
          getWindow().addFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
      }
      if(call.method == "keepoff"){
          getWindow().clearFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
      }
      if(call.method == "awakeapp"){
          awakeapp()
      }
      if(call.method == "pipmode"){
         pipmode()
      }
      if(call.method == "login"){
          pip = 1;
      }
      if(call.method == "logout"){
          pip = 0;
      }
    }
    }

     override fun onUserLeaveHint(){
     if(pip == 1){
         pipmode()
     }
    }

    private fun awakeapp(){
        val bringToForegroundIntent = Intent(this,MainActivity::class.java);
startActivity(bringToForegroundIntent);
    }



        private fun pipmode(){
        val rational = Rational(50,
            75)   
 

    val params = PictureInPictureParams.Builder()
            .setAspectRatio(rational)
            .build()
 
    enterPictureInPictureMode(params)
    }

}
