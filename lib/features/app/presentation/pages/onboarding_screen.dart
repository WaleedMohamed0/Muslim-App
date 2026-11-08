import 'package:flutter/material.dart';
import 'package:muslim/features/app/presentation/widgets/onboarding_page_view.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onComplete});

  final Future<void> Function() onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pages = <OnboardingPageData>[
    OnboardingPageData(
      icon: Icons.menu_book_rounded,
      eyebrow: 'الْقُرْآن الكريم',
      title: 'عِش مع القرآن كل يوم',
      description: 'اقرأ المصحف، وابحث عن الآيات، واستمع إلى التلاوة وتدبّر معانيها.',
      features: ['مصحف للقراءة', 'بحث وتفسير', 'تلاوات صوتية', 'علاماتك محفوظة'],
    ),
    OnboardingPageData(
      icon: Icons.mosque_rounded,
      eyebrow: 'مواقيت الصَّلَاة والأذان',
      title: 'كن قريبًا من صلاتك أينما كنت',
      description: 'تابع مواقيت الصلاة المحلية، واضبط تنبيهات وأصوات الأذان كما تحب.',
      features: ['مواقيت محلية', 'تذكير الصلاة', 'أذان بإعدادات مرنة', 'يعمل دون اتصال'],
    ),
    OnboardingPageData(
      icon: Icons.self_improvement_rounded,
      eyebrow: 'ذِكْرٌ وطمأنينة',
      title: 'اجعل للذِّكر مكانًا في يومك',
      description: 'أذكارك اليومية، وتسبيحك، وتذكير بالصلاة على النبي ﷺ، في رفقة واحدة.',
      features: ['الأذكار اليومية', 'التسبيح', 'الصلاة على النبي ﷺ', 'القِبلة وأسماء الله'],
    ),
    OnboardingPageData(
      icon: Icons.auto_stories_rounded,
      eyebrow: 'زادك الإيماني',
      title: 'خطوات صغيرة لأثرٍ كبير',
      description: 'تعلّم من قصص الأنبياء والسيرة، وتقدّم في عبادتك وخطتك لقراءة القرآن.',
      features: ['القصص والسيرة', 'أركان الإسلام والإيمان', 'تعلّم الوضوء والصلاة', 'أحكام المسافر', 'خطة الختمة'],
    ),
  ];

  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isFinishing = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_isFinishing) return;
    setState(() => _isFinishing = true);
    await widget.onComplete();
  }

  Future<void> _next() async {
    if (_currentPage == _pages.length - 1) {
      await _finish();
      return;
    }
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
            isDark ? theme.scaffoldBackgroundColor : colors.primaryContainer,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(24, 12, 24, 20),
            child: Column(
              children: [
                Row(
                  textDirection: TextDirection.ltr,
                  children: [
                    Container(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        12,
                        7,
                        12,
                        7,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isDark
                                ? colors.primaryContainer.withValues(alpha: .72)
                                : colors.surface,
                        borderRadius: BorderRadius.circular(999),
                        border:
                            isDark
                                ? null
                                : Border.all(
                                  color: colors.primary.withValues(alpha: .18),
                                ),
                      ),
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(
                          'مرحبًا بك في مُسلم',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colors.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _isFinishing ? null : _finish,
                      style: TextButton.styleFrom(
                        foregroundColor: colors.primary,
                        backgroundColor: colors.primary.withValues(
                          alpha: isDark ? .2 : .1,
                        ),
                        minimumSize: const Size(88, 48),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 11,
                        ),
                        textStyle: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                        shape: const StadiumBorder(),
                        side: BorderSide(
                          color: colors.primary.withValues(
                            alpha: isDark ? .5 : .38,
                          ),
                        ),
                        tapTargetSize: MaterialTapTargetSize.padded,
                      ),
                      child: const Text('تخطي'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? colors.surfaceContainerHighest.withValues(
                                alpha: .7,
                              )
                              : colors.surface,
                      borderRadius: BorderRadius.circular(999),
                      border:
                          isDark
                              ? null
                              : Border.all(
                                color: colors.outlineVariant.withValues(
                                  alpha: .9,
                                ),
                              ),
                    ),
                    child: Text(
                      '${_currentPage + 1}/${_pages.length}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Directionality(
                    // Keep page order aligned with the left-to-right dots,
                    // while each page's Arabic content stays RTL.
                    textDirection: TextDirection.ltr,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _pages.length,
                      onPageChanged:
                          (index) => setState(() => _currentPage = index),
                      itemBuilder:
                          (context, index) => Directionality(
                            textDirection: TextDirection.rtl,
                            child: OnboardingPageView(
                              data: _pages[index],
                              pageNumber: index + 1,
                            ),
                          ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  textDirection: TextDirection.ltr,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      margin: const EdgeInsetsDirectional.symmetric(
                        horizontal: 4,
                      ),
                      width: index == _currentPage ? 24 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color:
                            index == _currentPage
                                ? colors.primary
                                : isDark
                                ? colors.outlineVariant
                                : colors.onSurfaceVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: _isFinishing ? null : _next,
                        icon: Icon(
                          _currentPage == _pages.length - 1
                              ? Icons.check_rounded
                              : Icons.arrow_back_rounded,
                        ),
                        label: Text(
                          _currentPage == _pages.length - 1
                              ? 'ابدأ الآن'
                              : 'التالي',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

