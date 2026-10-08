import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 화면 설계(말씀한자 화면 설계 · 00 스타일 가이드)의 색상.
/// 위젯에서는 `context.palette` 로 꺼내 쓴다. 다크 모드 값은 같은 역할로 맞춘 것.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.accent,
    required this.onAccent,
    required this.accentStrong,
    required this.accentText,
    required this.accentTint,
    required this.gold,
    required this.goldStrong,
    required this.goldTint,
    required this.ink,
    required this.muted,
    required this.background,
    required this.surface,
    required this.border,
    required this.divider,
    required this.outline,
    required this.correct,
    required this.correctTint,
    required this.correctText,
    required this.wrong,
    required this.wrongTint,
    required this.wrongText,
  });

  /// 주 버튼, 선택 상태 (Primary)
  final Color accent;
  final Color onAccent;

  /// 강조 텍스트 (Primary Dark)
  final Color accentStrong;

  /// 구절 표시, 링크
  final Color accentText;

  /// 칩, 탭 배경 (Primary Tint)
  final Color accentTint;

  /// 한자어 하이라이트 글자 / 눌렀을 때 / 배경
  final Color gold;
  final Color goldStrong;
  final Color goldTint;

  /// 본문 (Ink) / 보조 텍스트 (Muted)
  final Color ink;
  final Color muted;

  /// 화면 배경 / 카드 배경
  final Color background;
  final Color surface;

  final Color border;
  final Color divider;

  /// 보조 버튼 테두리, 꺼진 스위치
  final Color outline;

  /// 퀴즈 정답 (파랑) / 오답 (주황)
  final Color correct;
  final Color correctTint;
  final Color correctText;
  final Color wrong;
  final Color wrongTint;
  final Color wrongText;

  static const light = AppPalette(
    accent: Color(0xFF5B4B8A),
    onAccent: Color(0xFFFFFFFF),
    accentStrong: Color(0xFF3F3266),
    accentText: Color(0xFF5B4B8A),
    accentTint: Color(0xFFECE8F6),
    gold: Color(0xFF8A6408),
    goldStrong: Color(0xFF6B4D05),
    goldTint: Color(0xFFFBF3DC),
    ink: Color(0xFF1F1B2D),
    muted: Color(0xFF5E5873),
    background: Color(0xFFF6F5FA),
    surface: Color(0xFFFFFFFF),
    border: Color(0xFFE4E1EC),
    divider: Color(0xFFEFEDF4),
    outline: Color(0xFFC9C4D6),
    correct: Color(0xFF1D5C99),
    correctTint: Color(0xFFE6F0FA),
    correctText: Color(0xFF123F6B),
    wrong: Color(0xFFA0420F),
    wrongTint: Color(0xFFFCEDE3),
    wrongText: Color(0xFF7A300A),
  );

  static const dark = AppPalette(
    accent: Color(0xFF7B69B5),
    onAccent: Color(0xFFFFFFFF),
    accentStrong: Color(0xFFD4CAF5),
    accentText: Color(0xFFB7A8EC),
    accentTint: Color(0xFF2E2747),
    gold: Color(0xFFE2B85A),
    goldStrong: Color(0xFFF0CD7E),
    goldTint: Color(0xFF3A3018),
    ink: Color(0xFFEDEAF5),
    muted: Color(0xFFB3ADC6),
    background: Color(0xFF141220),
    surface: Color(0xFF1F1B2D),
    border: Color(0xFF37324A),
    divider: Color(0xFF2C2840),
    outline: Color(0xFF4A4560),
    correct: Color(0xFF8EC1F0),
    correctTint: Color(0xFF15304A),
    correctText: Color(0xFFCFE5FA),
    wrong: Color(0xFFF0A57A),
    wrongTint: Color(0xFF4A2414),
    wrongText: Color(0xFFFAD9C4),
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(AppPalette? other, double t) =>
      other == null || t < 0.5 ? this : other;
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}

/// 타이포그래피 (스타일 가이드).
///
/// | 용도       | 글꼴                     | 크기                |
/// |-----------|--------------------------|---------------------|
/// | 한자       | Noto Serif KR Bold        | 40–72 (목록은 24–28) |
/// | 성경 본문   | Noto Serif KR Medium      | 16–18, 행간 1.9      |
/// | 화면 제목   | Noto Sans KR Bold         | 22                  |
/// | UI         | Noto Sans KR              | 12–16               |
class AppText {
  AppText._();

  static TextStyle hanja(BuildContext context, double size) => AppTheme.serif(
    TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w700,
      height: 1.2,
      color: context.palette.ink,
    ),
  );

  static TextStyle scripture(BuildContext context, {double size = 16}) =>
      AppTheme.serif(
        TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w500,
          height: 1.9,
          letterSpacing: -0.2,
          color: context.palette.ink,
        ),
      );

  static TextStyle title(BuildContext context) => Theme.of(context)
      .textTheme
      .titleLarge!
      .copyWith(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.4);

  /// UI 텍스트. [size] 12–16.
  static TextStyle ui(
    BuildContext context,
    double size, {
    FontWeight weight = FontWeight.w400,
    Color? color,
  }) => Theme.of(context).textTheme.bodyMedium!.copyWith(
    fontSize: size,
    fontWeight: weight,
    height: 1.4,
    color: color ?? context.palette.ink,
  );
}

class AppTheme {
  AppTheme._();

  /// 테스트에서는 false 로 둔다 (google_fonts 가 네트워크에서 글꼴을 받지 못해 실패한다).
  static bool useGoogleFonts = true;

  /// 성경 본문과 한자 (Noto Serif KR).
  static TextStyle serif(TextStyle style) =>
      useGoogleFonts ? GoogleFonts.notoSerifKr(textStyle: style) : style;

  /// 화면을 그리기 전에 글꼴을 받아 둔다. 늦게 받으면 웹에서 칩 글자가 잘린다.
  static Future<void> preloadFonts() async {
    if (!useGoogleFonts) return;
    try {
      await GoogleFonts.pendingFonts([
        for (final w in [FontWeight.w400, FontWeight.w500, FontWeight.w700])
          GoogleFonts.notoSansKr(fontWeight: w),
        for (final w in [FontWeight.w500, FontWeight.w700])
          GoogleFonts.notoSerifKr(fontWeight: w),
      ]).timeout(const Duration(seconds: 8));
    } catch (_) {
      // 오프라인 등: 기기 기본 글꼴로 그린다.
    }
  }

  /// UI 글꼴 (Noto Sans KR) 을 모든 텍스트 스타일에 입힌다.
  static TextTheme _sans(TextTheme t) {
    if (!useGoogleFonts) return t;
    TextStyle? s(TextStyle? style) =>
        style == null ? null : GoogleFonts.notoSansKr(textStyle: style);
    return t.copyWith(
      displayLarge: s(t.displayLarge),
      displayMedium: s(t.displayMedium),
      displaySmall: s(t.displaySmall),
      headlineLarge: s(t.headlineLarge),
      headlineMedium: s(t.headlineMedium),
      headlineSmall: s(t.headlineSmall),
      titleLarge: s(t.titleLarge),
      titleMedium: s(t.titleMedium),
      titleSmall: s(t.titleSmall),
      bodyLarge: s(t.bodyLarge),
      bodyMedium: s(t.bodyMedium),
      bodySmall: s(t.bodySmall),
      labelLarge: s(t.labelLarge),
      labelMedium: s(t.labelMedium),
      labelSmall: s(t.labelSmall),
    );
  }

  static ThemeData light() => _build(AppPalette.light, Brightness.light);

  static ThemeData dark() => _build(AppPalette.dark, Brightness.dark);

  static ThemeData _build(AppPalette p, Brightness brightness) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppPalette.light.accent,
          brightness: brightness,
        ).copyWith(
          primary: p.accent,
          onPrimary: p.onAccent,
          secondaryContainer: p.accentTint,
          onSecondaryContainer: p.accentStrong,
          surface: p.surface,
          onSurface: p.ink,
          onSurfaceVariant: p.muted,
          outline: p.outline,
          outlineVariant: p.border,
        );

    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    final text = _sans(base.textTheme)
        .apply(bodyColor: p.ink, displayColor: p.ink);

    final shape14 = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
    final buttonText = text.titleSmall?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w700,
    );

    return base.copyWith(
      extensions: [p],
      textTheme: text,
      scaffoldBackgroundColor: p.background,
      dividerTheme: DividerThemeData(color: p.divider, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: p.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        toolbarHeight: 64,
        titleTextStyle: text.titleLarge?.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: p.accentTint,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => text.labelSmall?.copyWith(
            fontSize: 12,
            color: s.contains(WidgetState.selected) ? p.accentStrong : p.muted,
            fontWeight: s.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w400,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: 22,
            color: s.contains(WidgetState.selected) ? p.accentStrong : p.muted,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.accentTint,
        selectedColor: p.accent,
        disabledColor: p.surface,
        showCheckmark: false,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        // 선택된 칩(보라 배경)은 흰 글자. ChoiceChip·FilterChip 모두 이 색을 상태별로 쓴다.
        labelStyle: text.labelLarge?.copyWith(
          fontSize: 13,
          color: WidgetStateColor.resolveWith((s) {
            if (s.contains(WidgetState.selected)) return p.onAccent;
            if (s.contains(WidgetState.disabled)) return p.outline;
            return p.accentStrong;
          }),
        ),
        secondaryLabelStyle: text.labelLarge?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: p.onAccent,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.accent,
          foregroundColor: p.onAccent,
          minimumSize: const Size(64, 52),
          shape: shape14,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.ink,
          backgroundColor: p.surface,
          minimumSize: const Size(64, 48),
          side: BorderSide(color: p.outline),
          shape: shape14,
          textStyle: buttonText?.copyWith(fontWeight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: p.accentText),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((s) {
          final on = s.contains(WidgetState.selected);
          if (s.contains(WidgetState.disabled)) {
            return on ? p.accent.withValues(alpha: 0.35) : p.border;
          }
          return on ? p.accent : p.outline;
        }),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.accent,
        linearTrackColor: p.border,
      ),
      searchBarTheme: SearchBarThemeData(
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: WidgetStatePropertyAll(p.surface),
        constraints: const BoxConstraints(minHeight: 46),
        side: WidgetStatePropertyAll(BorderSide(color: p.border)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        hintStyle: WidgetStatePropertyAll(
          text.bodyLarge?.copyWith(fontSize: 15, color: p.muted),
        ),
        textStyle: WidgetStatePropertyAll(
          text.bodyLarge?.copyWith(fontSize: 15),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: const Color(0x7A1F1B2D),
        dragHandleColor: p.outline,
        dragHandleSize: const Size(40, 4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dataTableTheme: DataTableThemeData(
        headingTextStyle: text.labelMedium?.copyWith(
          color: p.muted,
          fontWeight: FontWeight.w700,
        ),
        dividerThickness: 1,
      ),
    );
  }
}
