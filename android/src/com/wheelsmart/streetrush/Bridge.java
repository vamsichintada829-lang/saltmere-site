package com.wheelsmart.streetrush;

import android.app.Activity;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.content.Intent;
import android.webkit.JavascriptInterface;

/** Lets the game page share the team code (WhatsApp etc.) and copy it to the clipboard. */
public class Bridge implements Runnable {
    private final Activity act;
    private String pending;
    private boolean copy;

    public Bridge(Activity act) { this.act = act; }

    @JavascriptInterface
    public void share(String text) { pending = text; copy = false; act.runOnUiThread(this); }

    @JavascriptInterface
    public void copy(String text) { pending = text; copy = true; act.runOnUiThread(this); }

    @Override
    public void run() {
        String text = pending;
        if (text == null) return;
        if (copy) {
            ClipboardManager cm = (ClipboardManager) act.getSystemService(Context.CLIPBOARD_SERVICE);
            if (cm != null) cm.setPrimaryClip(ClipData.newPlainText("Street Rush team code", text));
        } else {
            Intent send = new Intent(Intent.ACTION_SEND);
            send.setType("text/plain");
            send.putExtra(Intent.EXTRA_TEXT, text);
            act.startActivity(Intent.createChooser(send, "Invite a friend"));
        }
    }
}
