import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:js_util' as js_util;

class WebSpeechService {
  static void speak(String text, {Function()? onEnd}) {
    try {
      final utterance = html.SpeechSynthesisUtterance(text);
      utterance.rate = 0.9;
      utterance.pitch = 1.0;
      utterance.volume = 1.0;
      if (onEnd != null) {
        utterance.onEnd.listen((_) => onEnd());
      }
      html.window.speechSynthesis!.speak(utterance);
    } catch (e) {
      print('TTS error: $e');
    }
  }

  static void stopSpeaking() {
    try {
      html.window.speechSynthesis!.cancel();
    } catch (e) {
      print('Stop TTS error: $e');
    }
  }

  static void startListening({
    required Function(String) onResult,
    required Function(String) onError,
  }) {
    try {
      final recognitionConstructor = js_util.getProperty(
        html.window,
        'webkitSpeechRecognition',
      ) ?? js_util.getProperty(html.window, 'SpeechRecognition');

      if (recognitionConstructor == null) {
        onError('Speech recognition not supported in this browser');
        return;
      }

      final recognition = js_util.callConstructor(recognitionConstructor, []);
      
      js_util.setProperty(recognition, 'lang', 'en-US');
      js_util.setProperty(recognition, 'interimResults', false);
      js_util.setProperty(recognition, 'maxAlternatives', 1);
      js_util.setProperty(recognition, 'continuous', false);

      js_util.setProperty(recognition, 'onresult', js.allowInterop((event) {
        try {
          final results = js_util.getProperty(event, 'results');
          final length = js_util.getProperty(results, 'length') as int;
          
          if (length > 0) {
            final lastResult = js_util.callMethod(results, 'item', [length - 1]);
            final alternative = js_util.callMethod(lastResult, 'item', [0]);
            final transcript = js_util.getProperty(alternative, 'transcript') as String;
            onResult(transcript);
          }
        } catch (e) {
          onError('Failed to get transcript: $e');
        }
      }));

      js_util.setProperty(recognition, 'onerror', js.allowInterop((event) {
        final error = js_util.getProperty(event, 'error');
        onError('Speech recognition error: $error');
      }));

      js_util.callMethod(recognition, 'start', []);
    } catch (e) {
      onError('Speech recognition failed: $e');
    }
  }
}
