import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/hanja_origin.dart';
import '../widgets/ui.dart';

/// 한자 한 글자의 구성원리(자원 풀이)를 아래에서 올라오는 창으로 보여 준다.
Future<void> showHanjaOriginSheet(
  BuildContext context, {
  required HanjaOrigin origin,
  String hunEum = '',
}) {
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      maxWidth: 560,
    ),
    builder: (_) => HanjaOriginSheet(origin: origin, hunEum: hunEum),
  );
}

class HanjaOriginSheet extends StatelessWidget {
  const HanjaOriginSheet({super.key, required this.origin, this.hunEum = ''});

  final HanjaOrigin origin;
  final String hunEum;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(origin.char, style: AppText.hanja(context, 44)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '구성원리',
                        style: AppText.ui(context, 13, color: p.muted),
                      ),
                      if (hunEum.isNotEmpty)
                        Text(
                          hunEum,
                          style: AppText.ui(
                            context,
                            18,
                            weight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
                if (origin.type.isNotEmpty) Pill(origin.type, fontSize: 13),
              ],
            ),
            const SizedBox(height: 16),
            for (final paragraph in origin.text.split('\n'))
              if (paragraph.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    paragraph.trim(),
                    style: AppText.ui(context, 15).copyWith(height: 1.7),
                  ),
                ),
            const SizedBox(height: 8),
            // 삽화·옛 글자 이미지는 네이버가 외부 사용을 막고 있어 원래 페이지에서 본다.
            OutlinedButton.icon(
              onPressed: () => launchUrl(
                origin.naverUrl,
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: Text(
                origin.pictures.isEmpty ? '네이버 한자사전에서 보기' : '네이버 한자사전에서 그림 보기',
              ),
            ),
            if (origin.pictures.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                origin.pictures.join(' · '),
                textAlign: TextAlign.center,
                style: AppText.ui(context, 12, color: p.muted),
              ),
            ],
            const SizedBox(height: 16),
            Text(origin.credit, style: AppText.ui(context, 12, color: p.muted)),
          ],
        ),
      ),
    );
  }
}
