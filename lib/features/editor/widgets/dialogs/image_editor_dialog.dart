import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../app/theme/forma_colors.dart';

class ImageEditorDialog extends StatefulWidget {
  final String? initialImageBase64;
  final ValueChanged<String> onApply;

  const ImageEditorDialog({
    super.key,
    required this.initialImageBase64,
    required this.onApply,
  });

  static Future<void> show(
    BuildContext context, {
    required String? initialImageBase64,
    required ValueChanged<String> onApply,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => ImageEditorDialog(
        initialImageBase64: initialImageBase64,
        onApply: onApply,
      ),
    );
  }

  @override
  State<ImageEditorDialog> createState() => _ImageEditorDialogState();
}

class _ImageEditorDialogState extends State<ImageEditorDialog> {
  String? _currentBase64;
  ui.Image? _decodedImage;
  double _rotationDegrees = 0.0;
  bool _flipH = false;
  bool _flipV = false;
  double _brightness = 0.0; // -0.5 to 0.5
  double _contrast = 1.0;   // 0.5 to 1.5
  double _saturation = 1.0; // 0.0 to 2.0
  String _cropRatio = 'Free'; // 'Free', '1:1', '16:9', '4:3'
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _currentBase64 = widget.initialImageBase64;
    _decodeCurrent();
  }

  void _decodeCurrent() {
    if (_currentBase64 == null || _currentBase64!.isEmpty) return;
    try {
      final clean = _currentBase64!.contains(',')
          ? _currentBase64!.split(',').last
          : _currentBase64!;
      final bytes = base64Decode(clean);
      ui.decodeImageFromList(bytes, (img) {
        if (mounted) setState(() => _decodedImage = img);
      });
    } catch (_) {}
  }

  Future<void> _pickNewImage() async {
    try {
      final picked = await FilePicker.pickFile(type: FileType.image);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final b64 = base64Encode(bytes);
        setState(() {
          _currentBase64 = b64;
          _rotationDegrees = 0;
          _flipH = false;
          _flipV = false;
        });
        _decodeCurrent();
      }
    } catch (_) {}
  }

  Future<void> _applyAndSave() async {
    if (_decodedImage == null) return;
    setState(() => _isProcessing = true);

    try {
      final recorder = ui.PictureRecorder();
      final origW = _decodedImage!.width.toDouble();
      final origH = _decodedImage!.height.toDouble();

      // Compute cropped dimensions
      double targetW = origW;
      double targetH = origH;
      if (_cropRatio == '1:1') {
        final side = math.min(origW, origH);
        targetW = side;
        targetH = side;
      } else if (_cropRatio == '16:9') {
        targetW = origW;
        targetH = origW * 9.0 / 16.0;
        if (targetH > origH) {
          targetH = origH;
          targetW = origH * 16.0 / 9.0;
        }
      } else if (_cropRatio == '4:3') {
        targetW = origW;
        targetH = origW * 3.0 / 4.0;
        if (targetH > origH) {
          targetH = origH;
          targetW = origH * 4.0 / 3.0;
        }
      }

      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, targetW, targetH));
      canvas.save();

      // Center transform
      canvas.translate(targetW / 2, targetH / 2);
      if (_rotationDegrees != 0) {
        canvas.rotate(_rotationDegrees * math.pi / 180.0);
      }
      canvas.scale(_flipH ? -1.0 : 1.0, _flipV ? -1.0 : 1.0);
      canvas.translate(-targetW / 2, -targetH / 2);

      // Color filter for brightness & contrast
      final paint = Paint()..filterQuality = FilterQuality.high;
      if (_brightness != 0 || _contrast != 1.0 || _saturation != 1.0) {
        // Skia color matrix for brightness & contrast
        final c = _contrast;
        final b = _brightness * 255;
        final s = _saturation;
        final matrix = <double>[
          c * (0.213 + 0.787 * s), c * (0.715 - 0.715 * s), c * (0.072 - 0.072 * s), 0, b,
          c * (0.213 - 0.213 * s), c * (0.715 + 0.285 * s), c * (0.072 - 0.072 * s), 0, b,
          c * (0.213 - 0.213 * s), c * (0.715 - 0.715 * s), c * (0.072 + 0.928 * s), 0, b,
          0, 0, 0, 1, 0,
        ];
        paint.colorFilter = ColorFilter.matrix(matrix);
      }

      final srcRect = Rect.fromCenter(
        center: Offset(origW / 2, origH / 2),
        width: targetW,
        height: targetH,
      );
      final dstRect = Rect.fromLTWH(0, 0, targetW, targetH);
      canvas.drawImageRect(_decodedImage!, srcRect, dstRect, paint);
      canvas.restore();

      final picture = recorder.endRecording();
      final renderedImg = await picture.toImage(targetW.toInt(), targetH.toInt());
      final byteData = await renderedImg.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        final newBase64 = base64Encode(byteData.buffer.asUint8List());
        widget.onApply(newBase64);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adjusting image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 520,
        constraints: const BoxConstraints(maxHeight: 700),
        decoration: BoxDecoration(
          color: isDark ? FormaColors.darkSurface : FormaColors.lightSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? FormaColors.darkBorder : FormaColors.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 12),
              child: Row(
                children: [
                  const Icon(Icons.crop_rotate_rounded, color: FormaColors.primaryBlue, size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Image Editor (Crop, Rotate, Filters)',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Image Preview Canvas
            Expanded(
              child: Container(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                child: Center(
                  child: _decodedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Transform.rotate(
                            angle: _rotationDegrees * math.pi / 180.0,
                            child: Transform.scale(
                              scaleX: _flipH ? -1.0 : 1.0,
                              scaleY: _flipV ? -1.0 : 1.0,
                              child: Container(
                                constraints: const BoxConstraints(maxHeight: 280, maxWidth: 440),
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: ColorFiltered(
                                  colorFilter: ColorFilter.matrix([
                                    _contrast * (0.213 + 0.787 * _saturation), _contrast * (0.715 - 0.715 * _saturation), _contrast * (0.072 - 0.072 * _saturation), 0, _brightness * 255,
                                    _contrast * (0.213 - 0.213 * _saturation), _contrast * (0.715 + 0.285 * _saturation), _contrast * (0.072 - 0.072 * _saturation), 0, _brightness * 255,
                                    _contrast * (0.213 - 0.213 * _saturation), _contrast * (0.715 - 0.715 * _saturation), _contrast * (0.072 + 0.928 * _saturation), 0, _brightness * 255,
                                    0, 0, 0, 1, 0,
                                  ]),
                                  child: RawImage(
                                    image: _decodedImage,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.image_not_supported_outlined, size: 48, color: Colors.grey),
                            const SizedBox(height: 8),
                            const Text('No Image Loaded', style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _pickNewImage,
                              icon: const Icon(Icons.file_upload_outlined, size: 16),
                              label: const Text('Choose Image'),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const Divider(height: 1),

            // Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  // Transformation & Aspect Ratio Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Crop Aspect Ratio
                      Row(
                        children: [
                          const Text('Crop:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 6),
                          for (final ratio in ['Free', '1:1', '16:9', '4:3'])
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: ChoiceChip(
                                label: Text(ratio, style: const TextStyle(fontSize: 10)),
                                selected: _cropRatio == ratio,
                                onSelected: (_) => setState(() => _cropRatio = ratio),
                              ),
                            ),
                        ],
                      ),

                      // Rotate & Flip buttons
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.rotate_left_rounded, size: 20),
                            tooltip: 'Rotate Left 90°',
                            onPressed: () => setState(() => _rotationDegrees = (_rotationDegrees - 90) % 360),
                          ),
                          IconButton(
                            icon: const Icon(Icons.rotate_right_rounded, size: 20),
                            tooltip: 'Rotate Right 90°',
                            onPressed: () => setState(() => _rotationDegrees = (_rotationDegrees + 90) % 360),
                          ),
                          IconButton(
                            icon: const Icon(Icons.flip_rounded, size: 20),
                            tooltip: 'Flip Horizontal',
                            onPressed: () => setState(() => _flipH = !_flipH),
                          ),
                          IconButton(
                            icon: const Icon(Icons.swap_vert_rounded, size: 20),
                            tooltip: 'Flip Vertical',
                            onPressed: () => setState(() => _flipV = !_flipV),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Sliders: Brightness, Contrast, Saturation
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Brightness (${(_brightness * 100).toInt()})', style: const TextStyle(fontSize: 10)),
                            Slider(
                              value: _brightness,
                              min: -0.5,
                              max: 0.5,
                              onChanged: (v) => setState(() => _brightness = v),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Contrast (${(_contrast * 100).toInt()}%)', style: const TextStyle(fontSize: 10)),
                            Slider(
                              value: _contrast,
                              min: 0.5,
                              max: 1.5,
                              onChanged: (v) => setState(() => _contrast = v),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Saturation (${(_saturation * 100).toInt()}%)', style: const TextStyle(fontSize: 10)),
                            Slider(
                              value: _saturation,
                              min: 0.0,
                              max: 2.0,
                              onChanged: (v) => setState(() => _saturation = v),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickNewImage,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Replace Image'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FormaColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _isProcessing ? null : _applyAndSave,
                    child: _isProcessing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Apply Changes',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
