import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_io/io.dart';
import 'package:whisper_ggml/src/models/requests/transcribe_request.dart';
import 'package:whisper_ggml/src/models/requests/transcribe_request_dto.dart';
import 'package:whisper_ggml/src/models/requests/version_request.dart';
import 'package:whisper_ggml/src/models/responses/whisper_transcribe_response.dart';
import 'package:whisper_ggml/src/models/responses/whisper_version_response.dart';
import 'package:whisper_ggml/src/models/whisper_dto.dart';
import 'package:whisper_ggml/src/models/whisper_model.dart';

export 'models/_models.dart';

/// Native request type
typedef WReqNative = Pointer<Utf8> Function(Pointer<Utf8> body);

/// Entry point
class Whisper {
  /// [model] is required
  /// [modelDir] is path where downloaded model will be stored.
  /// Default to library directory
  const Whisper({required this.model, this.modelDir});

  /// model used for transcription
  final WhisperModel model;

  /// override of model storage path
  final String? modelDir;

  DynamicLibrary _openLib() {
    if (Platform.isAndroid) {
      return DynamicLibrary.open('libwhisper.so');
    } else {
      return DynamicLibrary.process();
    }
  }

  Future<Map<String, dynamic>> _request({
    required WhisperRequestDto whisperRequest,
  }) async {
    return Isolate.run(() async {
      final data = whisperRequest.toRequestString().toNativeUtf8();
      final res = _openLib()
          .lookupFunction<WReqNative, WReqNative>('request')
          .call(data);

      final result = json.decode(res.toDartString()) as Map<String, dynamic>;

      malloc.free(data);
      return result;
    });
  }

  /// Transcribe audio file to text
  Future<WhisperTranscribeResponse> transcribe({
    required TranscribeRequest transcribeRequest,
    required String modelPath,
  }) async {
    try {
      final audioPath = transcribeRequest.audio.trim();
      if (audioPath.isEmpty) {
        throw ArgumentError.value(
          transcribeRequest.audio,
          'transcribeRequest.audio',
          'Audio path must not be empty.',
        );
      }

      final audioFile = File(audioPath);
      if (!audioFile.existsSync()) {
        throw ArgumentError.value(
          audioPath,
          'transcribeRequest.audio',
          'Audio file does not exist.',
        );
      }

      final lowerCaseAudioPath = audioPath.toLowerCase();
      if (audioPath.contains('.') && !lowerCaseAudioPath.endsWith('.wav')) {
        throw ArgumentError.value(
          audioPath,
          'transcribeRequest.audio',
          'Whisper expects an already converted 16 kHz 16-bit WAV file.',
        );
      }

      final result = await _request(
        whisperRequest: TranscribeRequestDto.fromTranscribeRequest(
          transcribeRequest.copyWith(audio: audioPath),
          modelPath,
        ),
      );

      if (result['text'] == null) {
        throw Exception(result['message']);
      }
      return WhisperTranscribeResponse.fromJson(result);
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }

  /// Get whisper version
  Future<String?> getVersion() async {
    final result = await _request(
      whisperRequest: const VersionRequest(),
    );

    final response = WhisperVersionResponse.fromJson(result);
    return response.message;
  }
}
