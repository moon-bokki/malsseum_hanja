import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../providers.dart';
import '../../viewmodels/wordbook_viewmodel.dart';
import '../widgets/ui.dart';

const _appVersion = '1.0.0';

class MyPageScreen extends ConsumerStatefulWidget {
  const MyPageScreen({super.key});

  @override
  ConsumerState<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends ConsumerState<MyPageScreen> {
  bool _dailyVerse = true;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final words = ref.watch(wordbookViewModelProvider).value ?? const [];
    final correct = words.fold<int>(0, (sum, w) => sum + w.correctCount);
    final wrong = words.fold<int>(0, (sum, w) => sum + w.wrongCount);
    final push = ref.watch(pushNotificationServiceProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            const ScreenHeader(title: '마이페이지'),
            const SizedBox(height: 16),
            SurfaceCard(
              radius: 18,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: p.accentTint,
                    foregroundColor: p.accentStrong,
                    child: const Icon(Icons.person_outline, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '익명 사용자',
                          style: AppText.ui(
                            context,
                            16,
                            weight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          AppConfig.useFirebase
                              ? '학습 기록이 클라우드(Firestore)에 저장됩니다'
                              : '학습 기록이 이 기기에만 저장됩니다',
                          style: AppText.ui(context, 12, color: p.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _StatCard(
                  label: '저장한 한자어',
                  value: '${words.length}',
                  color: p.accentStrong,
                ),
                const SizedBox(width: 10),
                _StatCard(label: '퀴즈 정답', value: '$correct', color: p.correct),
                const SizedBox(width: 10),
                _StatCard(label: '퀴즈 오답', value: '$wrong', color: p.wrong),
              ],
            ),
            const SizedBox(height: 16),
            SurfaceCard(
              radius: 18,
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                    child: Text(
                      '알림',
                      style: AppText.ui(
                        context,
                        13,
                        weight: FontWeight.w700,
                        color: p.muted,
                      ),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    title: Text(
                      '오늘의 말씀 알림',
                      style: AppText.ui(context, 15, weight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      push == null ? 'Firebase 설정 후 사용할 수 있습니다' : '매일 아침 7시',
                      style: AppText.ui(context, 12, color: p.muted),
                    ),
                    value: _dailyVerse,
                    onChanged: push == null
                        ? null
                        : (v) async {
                            await push.setDailyVerseEnabled(v);
                            setState(() => _dailyVerse = v);
                          },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SurfaceCard(
              radius: 18,
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _InfoRow(
                    label: '저장소',
                    value: AppConfig.useFirebase ? 'Firestore' : '기기 메모리',
                  ),
                  const _InfoRow(label: '성경 본문', value: '개역한글'),
                  const _InfoRow(label: '사전', value: '국립국어원 표준국어대사전'),
                  const _InfoRow(label: '앱 버전', value: _appVersion, last: true),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '성경전서 개역한글판 © 대한성서공회 1961',
              textAlign: TextAlign.center,
              style: AppText.ui(context, 12, color: p.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SurfaceCard(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: Column(
          children: [
            Text(
              value,
              style: AppText.ui(
                context,
                26,
                weight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: AppText.ui(context, 12, color: context.palette.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.last = false});

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: p.divider)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppText.ui(context, 14))),
          Text(value, style: AppText.ui(context, 14, color: p.muted)),
        ],
      ),
    );
  }
}
