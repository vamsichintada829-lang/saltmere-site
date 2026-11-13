package com.wheelsmart.streetrush;

import android.app.Activity;
import android.graphics.Color;
import android.os.Build;
import android.os.Bundle;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.webkit.ValueCallback;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

public class MainActivity extends Activity implements ValueCallback {
    private WebView web;

    @Override
    protected void onCreate(Bundle state) {
        super.onCreate(state);
        Window w = getWindow();
        w.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON | WindowManager.LayoutParams.FLAG_FULLSCREEN);
        if (Build.VERSION.SDK_INT >= 28) {
            w.getAttributes().layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES;
        }
        web = new WebView(this);
        web.setBackgroundColor(Color.rgb(6, 8, 11));
        WebSettings s = web.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        s.setMediaPlaybackRequiresUserGesture(false);
        s.setAllowFileAccess(true);
        s.setSupportZoom(false);
        s.setBuiltInZoomControls(false);
        s.setLoadWithOverviewMode(true);
        s.setUseWideViewPort(true);
        web.setOverScrollMode(View.OVER_SCROLL_NEVER);
        web.setVerticalScrollBarEnabled(false);
        web.setHorizontalScrollBarEnabled(false);
        web.setWebViewClient(new WebViewClient());
        web.setWebChromeClient(new WebChromeClient());
        setContentView(web);
        hideSystemBars();
        web.loadUrl("file:///android_asset/index.html");
    }

    private void hideSystemBars() {
        web.setSystemUiVisibility(View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY | View.SYSTEM_UI_FLAG_FULLSCREEN
            | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION | View.SYSTEM_UI_FLAG_LAYOUT_STABLE
            | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN);
    }

    @Override
    public void onWindowFocusChanged(boolean hasFocus) {
        super.onWindowFocusChanged(hasFocus);
        if (hasFocus) hideSystemBars();
    }

    @Override
    public void onBackPressed() {
        // In a race: open the in-game menu. On the menu: leave the app.
        web.evaluateJavascript(
            "(function(){var m=document.getElementById('menu');if(m&&m.hidden){window.dispatchEvent(new KeyboardEvent('keydown',{code:'Escape'}));return 'menu';}return 'exit';})()",
            this);
    }

    @Override
    public void onReceiveValue(Object value) {
        if (value == null || String.valueOf(value).contains("exit")) finish();
    }

    @Override
    protected void onPause() { super.onPause(); web.onPause(); web.pauseTimers(); }

    @Override
    protected void onResume() { super.onResume(); web.resumeTimers(); web.onResume(); hideSystemBars(); }

    @Override
    protected void onDestroy() { web.destroy(); super.onDestroy(); }
}
