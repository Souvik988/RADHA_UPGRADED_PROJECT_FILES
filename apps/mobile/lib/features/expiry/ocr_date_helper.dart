import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

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
  /// Returns `null` if the user cancels.
  static Future<OcrDateResult?> extractDates(
    BuildContext context,
    WidgetRef ref,
  ) async {
    // For now we take a photo through a simple image picker approach.
    // In production this would use a dedicated capture UI with live preview.
    // To keep this implementation focused on the OCR logic we use a file path
    // placeholder — the real capture flow can be wired in a follow-up.
    final imagePath = await _captureImage(context);
    if (imagePath == null) return null;

    // Try on-device recognition first.
    final localResult = await _runLocalOcr(imagePath);
    if (localResult != null) return localResult;

    // Fallback to cloud endpoint.
    return _runCloudFallback(imagePath, ref);
  }

  /// Stub for image capture. In production, replace with camera plugin flow.
  static Future<String?> _captureImage(BuildContext context) async {
    // Use a dialog to inform the user. A real implementation would open
    // camera_android / camera_ios.
    // For the skeleton we show a file picker or cancel.
    if (!context.mounted) return null;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Capture expiry label'),
        content: const Text(
          'Point your camera at the manufacturing and expiry dates on '
          'the product label.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Open camera'),
          ),
        ],
      ),
    );

    if (confirmed != true) return null;

    // Placeholder: in a real build this would return the captured file path.
    // Returning null here means OCR won't run without a real camera capture.
    return null;
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
