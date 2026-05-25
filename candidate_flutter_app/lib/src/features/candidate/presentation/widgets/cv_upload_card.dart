import 'package:flutter/material.dart';

import 'panel_card.dart';

class CvUploadCard extends StatelessWidget {
  const CvUploadCard({
    super.key,
    required this.extracting,
    required this.progress,
    required this.onUpload,
    required this.uploaded,
    this.fileName,
    this.onPreview,
  });

  final String? fileName;
  final bool uploaded;
  final bool extracting;
  final double progress;
  final VoidCallback onUpload;
  final VoidCallback? onPreview;

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.upload_file_rounded,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Upload CV / Resume',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(fileName ?? 'Supported formats: PDF, DOC, DOCX'),
          if (extracting) ...[
            const SizedBox(height: 14),
            LinearProgressIndicator(value: progress <= 0 ? null : progress),
            const SizedBox(height: 8),
            const Text('Uploading CV and extracting skills...'),
          ],
          if (fileName != null && !extracting) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    fileName!,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                if (onPreview != null)
                  IconButton(
                    tooltip: 'Preview CV',
                    onPressed: onPreview,
                    icon: const Icon(Icons.visibility_rounded),
                  ),
              ],
            ),
            Text(
              uploaded ? 'Upload successful' : 'Previously uploaded CV',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: extracting ? null : onUpload,
            icon: Icon(
              fileName == null
                  ? Icons.cloud_upload_rounded
                  : Icons.swap_horiz_rounded,
            ),
            label: Text(fileName == null ? 'Upload resume' : 'Replace resume'),
          ),
        ],
      ),
    );
  }
}
