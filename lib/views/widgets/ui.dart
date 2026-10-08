import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// 흰 배경 + 테두리 카드 (화면 설계의 기본 카드).
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 16,
    this.color,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: p.border),
    );
    return Material(
      color: color ?? p.surface,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// 작은 둥근 라벨 (예: '한자 병기 켜짐', '명사').
class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.onTap, this.fontSize = 12});

  final String text;
  final VoidCallback? onTap;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: p.accentTint,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Text(
            text,
            style: AppText.ui(
              context,
              fontSize,
              weight: FontWeight.w500,
              color: p.accentStrong,
            ),
          ),
        ),
      ),
    );
  }
}

/// 화면 제목 줄 (AppBar 대신 본문 맨 위에 둔다).
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: AppText.title(context))),
        ?trailing,
      ],
    );
  }
}
