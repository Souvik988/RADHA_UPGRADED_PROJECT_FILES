import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/network/api_client.dart';

/// Result of OCR date extraction — may contain one or both dates.
class OcrDateResult {
  const OcrDateResult({this.mfgDate, this.expiryDate});

  final DateTime? mfgDate;
  final DateTime? expiryDate;
}

/// Helper that runs on-device ML Kit text recognition to extract MFG/EXP
/// dates from a captured image. Falls back to the backend OCR endpoint
/// (BE-45) when local confidence is low or extraction fails.
class OcrDateHelper {
  OcrDateHelper._();

  /// Minimum confidence threshold for on-device OCR. If the average block
  /// confidence drops below this we escalate to cloud fallback.
  static const double _confidenceThreshold = 0.6;

  /// Launches the camera, performs OCR, and returns parsed dates.
  /// Returns `null` if the user cancels or no date could be read.
  static Future<OcrDateResult?> extractDates(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final imagePath = await captureAndExtractPath();
    if (imagePath == null || !context.mounted) return null;

    // On-device recognition first (free, offline). Cloud fallback on a miss.
    final localResult = await _runLocalOcr(imagePath);
    if (localResult != null) return localResult;
    return _runCloudFallback(imagePath, ref);
  }

  /// Opens the native camera and returns the captured file path (or null if
  /// cancelled). The OS camera handles autofocus + automatic flash in low
  /// light, so a date on a glossy/dim pack still captures cleanly.
  static Future<String?> captureAndExtractPath() async {
    final XFile? file = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1600,
    );
    return file?.path;
  }

  /// Runs Google ML Kit text recognition on a captured image file.
  static Future<OcrDateResult?> _runLocalOcr(String imagePath) async {
    final textRecognizer = TextRecognizer();
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognized = await textRecognizer.processImage(inputImage);

      // Check average confidence across text lines.
      // Note: google_mlkit_text_recognition exposes confidence at the line
      // level, not block level. We average across all lines.
      double totalConfidence = 0;
      int lineCount = 0;
      for (final block in recognized.blocks) {
        for (final line in block.lines) {
          if (line.confidence != null) {
            totalConfidence += line.confidence!;
            lineCount++;
          }
        }
      }

      final avgConfidence = lineCount > 0 ? totalConfidence / lineCount : 0.0;
      if (avgConfidence < _confidenceThreshold) return null;

      // Attempt to parse dates from the full recognized text.
      final fullText = recognized.text;
      return _parseDatesFromText(fullText);
    } catch (_) {
      return null;
    } finally {
      textRecognizer.close();
    }
  }

  /// Calls the cloud OCR fallback endpoint (BE-45) with the image bytes.
  static Future<OcrDateResult?> _runCloudFallback(
    String imagePath,
    WidgetRef ref,
  ) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final base64Image = Uri.dataFromBytes(
        bytes,
        mimeType: 'image/jpeg',
      ).toString();

      final client = ref.read(apiClientProvider);
      final response = await client.ocrFallback({'image': base64Image});

      return _parseDatesFromText(response.text);
    } catch (_) {
      return null;
    }
  }

  /// Extracts MFG and EXP dates from raw OCR text using common label formats.
  static OcrDateResult? _parseDatesFromText(String text) {
    DateTime? mfgDate;
    DateTime? expiryDate;

    // Common patterns: MFG 01/2024, EXP 06/2025, MFG: 2024-01-15, etc.
    final datePattern = RegExp(
      r'(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2,4})|(\d{4})[/\-.](\d{1,2})[/\-.](\d{1,2})',
    );

    final mfgIndicators = RegExp(
      r'MFG|MFD|MANUFACTURED|PKD|PACKED',
      caseSensitive: false,
    );
    final expIndicators = RegExp(
      r'EXP|EXPIRY|BEST\s*BEFORE|USE\s*BY|BB',
      caseSensitive: false,
    );

    final lines = text.split('\n');
    for (final line in lines) {
      final dateMatch = datePattern.firstMatch(line);
      if (dateMatch == null) continue;

      final parsed = _tryParseMatch(dateMatch);
      if (parsed == null) continue;

      if (mfgIndicators.hasMatch(line)) {
        mfgDate = parsed;
      } else if (expIndicators.hasMatch(line)) {
        expiryDate = parsed;
      } else {
        // If no indicator but we don't have an expiry yet, assume expiry.
        expiryDate ??= parsed;
      }
    }

    if (mfgDate == null && expiryDate == null) return null;
    return OcrDateResult(mfgDate: mfgDate, expiryDate: expiryDate);
  }

  static DateTime? _tryParseMatch(RegExpMatch match) {
    try {
      // Format: DD/MM/YYYY or DD-MM-YYYY
      if (match.group(1) != null) {
        final day = int.parse(match.group(1)!);
        final month = int.parse(match.group(2)!);
        var year = int.parse(match.group(3)!);
        if (year < 100) year += 2000;
        if (month < 1 || month > 12) return null;
        if (day < 1 || day > 31) return null;
        return DateTime(year, month, day);
      }
      // Format: YYYY-MM-DD
      if (match.group(4) != null) {
        final year = int.parse(match.group(4)!);
        final month = int.parse(match.group(5)!);
        final day = int.parse(match.group(6)!);
        if (month < 1 || month > 12) return null;
        if (day < 1 || day > 31) return null;
        return DateTime(year, month, day);
      }
    } catch (_) {
      // Swallow parse errors — OCR text is inherently noisy.
    }
    return null;
  }
}
