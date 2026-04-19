import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_io/io.dart';
import 'package:whisper_ggml/src/models/whisper_model.dart';

import 'models/whisper_result.dart';
import 'whisper.dart';

class WhisperController {
  String _modelPath = '';
  String? _dir;

  Future<void> initModel(WhisperModel model) async {
    _dir ??= await getModelDir();
    _modelPath = '$_dir/ggml-${model.modelName}.bin';
  }

  Future<TranscribeResult?> transcribe({
    required WhisperModel model,
    required String audioPath,
    String lang = 'en',
    bool diarize = false,
    String? initialPrompt,
  }) async {
    await initModel(model);

    final Whisper whisper = Whisper(model: model);
    final DateTime start = DateTime.now();
    const bool translate = false;
    const bool withSegments = false;
    const bool splitWords = false;

    try {
      final WhisperTranscribeResponse transcription = await whisper.transcribe(
        transcribeRequest: TranscribeRequest(
          audio: audioPath,
          initialPrompt: initialPrompt,
          language: lang,
          isTranslate: translate,
          isNoTimestamps: !withSegments,
          splitOnWord: splitWords,
          isRealtime: true,
          diarize: diarize,
        ),
        modelPath: _modelPath,
      );

      final Duration transcriptionDuration = DateTime.now().difference(start);

      return TranscribeResult(
        time: transcriptionDuration,
        transcription: transcription,
      );
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  static Future<String> getModelDir() async {
    final Directory libraryDirectory = Platform.isAndroid
        ? await getApplicationSupportDirectory()
        : await getLibraryDirectory();
    return libraryDirectory.path;
  }

  /// Get local path of model file
  Future<String> getPath(WhisperModel model) async {
    _dir ??= await getModelDir();
    return '$_dir/ggml-${model.modelName}.bin';
  }

  /// Download [model] to [destinationPath]
  Future<String> downloadModel(
    WhisperModel model, {
    void Function(int percent)? onProgress,
  }) async {
    final String modelPath = await getPath(model);
    if (File(modelPath).existsSync()) {
      return modelPath;
    }

    final String temporaryPath = '$modelPath.download';
    final HttpClient client = HttpClient();
    IOSink? sink;

    try {
      final HttpClientRequest request = await client.getUrl(model.modelUri);
      final HttpClientResponse response = await request.close();

      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
          'Failed to download model ${model.modelName}: '
          'HTTP ${response.statusCode}',
          uri: model.modelUri,
        );
      }

      final File temporaryFile = File(temporaryPath);
      if (temporaryFile.existsSync()) {
        await temporaryFile.delete();
      }

      sink = temporaryFile.openWrite();

      final int contentLength = response.contentLength;
      int bytesReceived = 0;
      int lastReportedPercent = 0;

      await for (final List<int> chunk in response) {
        sink.add(chunk);
        bytesReceived += chunk.length;

        if (contentLength > 0) {
          final int percent = ((bytesReceived * 100) / contentLength).floor();
          while (lastReportedPercent + 10 <= percent &&
              lastReportedPercent < 100) {
            lastReportedPercent += 10;
            onProgress?.call(lastReportedPercent);
          }
        }
      }

      await sink.flush();
      await sink.close();
      sink = null;

      final File destinationFile = File(modelPath);
      if (destinationFile.existsSync()) {
        await destinationFile.delete();
      }

      await temporaryFile.rename(modelPath);

      if (contentLength > 0 && lastReportedPercent < 100) {
        onProgress?.call(100);
      }

      return modelPath;
    } catch (_) {
      if (sink != null) {
        await sink.close();
      }

      final File temporaryFile = File(temporaryPath);
      if (temporaryFile.existsSync()) {
        await temporaryFile.delete();
      }
      rethrow;
    } finally {
      client.close(force: true);
    }
  }
}
