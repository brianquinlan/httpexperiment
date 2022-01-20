package com.example.platformhttp;

import java.util.concurrent.Semaphore;

import androidx.annotation.NonNull;
import com.android.volley.RequestQueue;
import com.android.volley.Response;
import com.android.volley.Request;
import com.android.volley.toolbox.Volley;
import com.android.volley.toolbox.StringRequest;
import com.android.volley.VolleyError;
import com.android.volley.AuthFailureError;

import com.android.volley.toolbox.BasicNetwork;
import com.android.volley.toolbox.HurlStack;
import com.android.volley.toolbox.NoCache;
import com.android.volley.Network;
import io.flutter.plugin.common.StandardMethodCodec;
import java.util.Map;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.BinaryMessenger;

/** PlatformhttpPlugin */
public class PlatformhttpPlugin implements FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native
  /// Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine
  /// and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel channel;
  private RequestQueue queue;

  /*
   * private class R extends Request<T> {
   * private final Map<String, String> headers;
   * 
   * }
   */
  public PlatformhttpPlugin() {
    Network network = new BasicNetwork(new HurlStack());
    queue = new RequestQueue(new NoCache(), network);
    queue.start();

    // queue = Volley.newRequestQueue(this);
  }

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
//    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "platformhttp");
BinaryMessenger messenger = flutterPluginBinding.getBinaryMessenger();
BinaryMessenger.TaskQueue taskQueue =
    messenger.makeBackgroundTaskQueue();
channel =
    new MethodChannel(
        messenger,
        "platformhttp",
        StandardMethodCodec.INSTANCE,
        taskQueue);
channel.setMethodCallHandler(this);
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    if (call.method.equals("request")) {
      final Semaphore s = new Semaphore(0);
      final StringBuilder t = new StringBuilder();
      StringRequest stringRequest = new StringRequest(call.argument("url"),
          new Response.Listener<String>() {
            @Override
            public void onResponse(String response) {
              t.append(response);
              s.release();
            }
          }, new Response.ErrorListener() {
            @Override
            public void onErrorResponse(VolleyError error) {
              t.append(error.toString());
              s.release();
            }
          })
          {     
            @Override
            public Map<String, String> getHeaders() throws AuthFailureError { 
              if (call.hasArgument​("headers")) {
                Map<String, String> headers = (Map<String, String>) call.argument("headers");
                return headers;
              }
                return super.getHeaders();
            }

            @Override
            public int getMethod() {
              switch ((String) call.argument("method")) {
                case "GET":
                  return Request.Method.GET;
                default:
                  throw new UnsupportedOperationException((String) call.argument("method"));
              }
            }
        };

      // Add the request to the RequestQueue.
      queue.add(stringRequest);
      try {
        s.acquire();
      } catch (InterruptedException e) {
      }
      result.success(t.toString());

    } else {
      result.notImplemented();
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }
}
