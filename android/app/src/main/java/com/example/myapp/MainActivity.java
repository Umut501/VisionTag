// android/app/src/main/java/com/example/myapp/MainActivity.java
package com.example.myapp;

import android.Manifest;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.speech.RecognitionListener;
import android.speech.RecognizerIntent;
import android.speech.SpeechRecognizer;
import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "speech_to_text";
    private static final int REQUEST_RECORD_AUDIO_PERMISSION = 200;
    
    private SpeechRecognizer speechRecognizer;
    private Intent speechRecognizerIntent;
    private MethodChannel methodChannel;
    private boolean isListening = false;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        
        methodChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL);
        methodChannel.setMethodCallHandler(this::onMethodCall);
        
        setupSpeechRecognizer();
    }

    private void setupSpeechRecognizer() {
        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this);
        speechRecognizerIntent = new Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH);
        speechRecognizerIntent.putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM);
        speechRecognizerIntent.putExtra(RecognizerIntent.EXTRA_LANGUAGE, Locale.getDefault());
        speechRecognizerIntent.putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true);
        speechRecognizerIntent.putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1);

        speechRecognizer.setRecognitionListener(new RecognitionListener() {
            @Override
            public void onReadyForSpeech(Bundle bundle) {
                Map<String, Object> arguments = new HashMap<>();
                arguments.put("status", "listening");
                methodChannel.invokeMethod("onStatusChanged", arguments);
            }

            @Override
            public void onBeginningOfSpeech() {
                isListening = true;
            }

            @Override
            public void onRmsChanged(float rmsdB) {
                // Audio level changes - can be used for visual feedback
            }

            @Override
            public void onBufferReceived(byte[] buffer) {
                // Raw audio buffer - not needed for basic implementation
            }

            @Override
            public void onEndOfSpeech() {
                isListening = false;
            }

            @Override
            public void onError(int error) {
                String errorMessage = getErrorMessage(error);
                Map<String, Object> arguments = new HashMap<>();
                arguments.put("error", errorMessage);
                methodChannel.invokeMethod("onError", arguments);
                isListening = false;
            }

            @Override
            public void onResults(Bundle results) {
                ArrayList<String> matches = results.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION);
                float[] confidenceScores = results.getFloatArray(SpeechRecognizer.CONFIDENCE_SCORES);
                
                if (matches != null && !matches.isEmpty()) {
                    String recognizedText = matches.get(0);
                    float confidence = (confidenceScores != null && confidenceScores.length > 0) 
                        ? confidenceScores[0] : 0.0f;
                    
                    Map<String, Object> arguments = new HashMap<>();
                    arguments.put("recognizedWords", recognizedText);
                    arguments.put("finalResult", true);
                    arguments.put("confidence", confidence);
                    methodChannel.invokeMethod("onSpeechResult", arguments);
                }
                isListening = false;
            }

            @Override
            public void onPartialResults(Bundle results) {
                ArrayList<String> matches = results.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION);
                if (matches != null && !matches.isEmpty()) {
                    String partialText = matches.get(0);
                    
                    Map<String, Object> arguments = new HashMap<>();
                    arguments.put("recognizedWords", partialText);
                    arguments.put("finalResult", false);
                    arguments.put("confidence", 0.5);
                    methodChannel.invokeMethod("onSpeechResult", arguments);
                }
            }

            @Override
            public void onEvent(int eventType, Bundle params) {
                // Additional events - not needed for basic implementation
            }
        });
    }

    private void onMethodCall(MethodCall call, MethodChannel.Result result) {
        switch (call.method) {
            case "initialize":
                if (checkPermission()) {
                    result.success(SpeechRecognizer.isRecognitionAvailable(this));
                } else {
                    requestPermission();
                    result.success(false);
                }
                break;
                
            case "startListening":
                if (checkPermission() && !isListening) {
                    String localeId = call.argument("localeId");
                    if (localeId != null) {
                        speechRecognizerIntent.putExtra(RecognizerIntent.EXTRA_LANGUAGE, localeId);
                    }
                    
                    Integer listenFor = call.argument("listenFor");
                    if (listenFor != null) {
                        speechRecognizerIntent.putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS, listenFor);
                    }
                    
                    speechRecognizer.startListening(speechRecognizerIntent);
                    result.success(null);
                } else {
                    result.error("PERMISSION_DENIED", "Microphone permission not granted or already listening", null);
                }
                break;
                
            case "stopListening":
                if (isListening) {
                    speechRecognizer.stopListening();
                }
                result.success(null);
                break;
                
            default:
                result.notImplemented();
                break;
        }
    }

    private boolean checkPermission() {
        return ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) 
               == PackageManager.PERMISSION_GRANTED;
    }

    private void requestPermission() {
        ActivityCompat.requestPermissions(this, 
            new String[]{Manifest.permission.RECORD_AUDIO}, 
            REQUEST_RECORD_AUDIO_PERMISSION);
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        
        if (requestCode == REQUEST_RECORD_AUDIO_PERMISSION) {
            if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                // Permission granted, can now use speech recognition
                Map<String, Object> arguments = new HashMap<>();
                arguments.put("status", "available");
                methodChannel.invokeMethod("onStatusChanged", arguments);
            } else {
                // Permission denied
                Map<String, Object> arguments = new HashMap<>();
                arguments.put("error", "Microphone permission denied");
                methodChannel.invokeMethod("onError", arguments);
            }
        }
    }

    private String getErrorMessage(int error) {
        switch (error) {
            case SpeechRecognizer.ERROR_AUDIO:
                return "Audio recording error";
            case SpeechRecognizer.ERROR_CLIENT:
                return "Client side error";
            case SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS:
                return "Insufficient permissions";
            case SpeechRecognizer.ERROR_NETWORK:
                return "Network error";
            case SpeechRecognizer.ERROR_NETWORK_TIMEOUT:
                return "Network timeout";
            case SpeechRecognizer.ERROR_NO_MATCH:
                return "No speech input matched";
            case SpeechRecognizer.ERROR_RECOGNIZER_BUSY:
                return "Recognition service busy";
            case SpeechRecognizer.ERROR_SERVER:
                return "Server error";
            case SpeechRecognizer.ERROR_SPEECH_TIMEOUT:
                return "No speech input detected";
            default:
                return "Unknown error";
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (speechRecognizer != null) {
            speechRecognizer.destroy();
        }
    }
}