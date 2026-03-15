<div align="center">

# Whisper GGML

_OpenAI Whisper ASR (Automatic Speech Recognition) for Flutter using [Whisper.cpp](https://github.com/ggerganov/whisper.cpp)._

<p align="center">
  <a href="https://pub.dev/packages/whisper_ggml">
     <img src="https://img.shields.io/badge/pub-1.7.0-blue?logo=dart" alt="pub">
  </a>
  <a href="https://buymeacoffee.com/sk3llo" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" height="21" width="114"></a>
</p>
</div>


## Supported platforms


| Platform  | Supported |
|-----------|-----------|
| Android   | ✅        |
| iOS       | ✅        |
| MacOS     | ✅        |


## Features



- Automatic Speech Recognition integration for Flutter apps.

- Supports automatic model downloading and initialization. Can be configured to work fully offline by using `assets` models (see example folder).

- Seamless iOS and Android support with optimized performance.

- Can be configured to use specific language ("en", "fr", "de", etc) or auto-detect ("auto").

- Utilizes [CORE ML](https://github.com/ggml-org/whisper.cpp/tree/master?tab=readme-ov-file#core-ml-support) for enhanced processing on iOS devices.

- Accepts already prepared Whisper-compatible WAV input directly without bundling FFmpeg.



## Installation



To use this library in your Flutter project, follow these steps:



1. Add the library to your Flutter project's `pubspec.yaml`:

```yaml
dependencies:
  whisper_ggml: ^1.7.0
```

2. Run `flutter pub get` to install the package.



## Usage



To integrate Whisper ASR in your Flutter app:



1. Import the package:

```dart
import 'package:whisper_ggml/whisper_ggml.dart';
```



2. Pick your model. Smaller models are more performant, but the accuracy may be lower. Recommended models are `tiny` and `small`.

```dart
final model = WhisperModel.tiny;
```

3. Declare `WhisperController` and use it for transcription:

```dart
Future<TranscribeResult?> transcribeFile(String audioPath) async {
  final controller = WhisperController();

  return controller.transcribe(
    model: model, // Selected WhisperModel
    audioPath: audioPath, // Path to a 16 kHz 16-bit WAV file
    lang: 'en', // Language to transcribe
  );
}
```

4. Use the `result` variable to access the transcription result:

```dart
void handleResult(TranscribeResult? result) {
  if (result?.transcription.text != null) {
    print(result!.transcription.text);
  }
}
```



## Notes

Transcription processing time is about `5x` times faster when running in release mode.

- `audioPath` must already point to a Whisper-compatible WAV file.
- The package no longer converts compressed formats such as `.m4a`, `.mp3`, or `.aac` internally.
- For best results, record or convert audio to `16 kHz`, `16-bit`, mono WAV before calling `transcribe`.
