import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/app_messenger.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../theme/dashboard_design.dart';

class CleanHeader extends ConsumerWidget {
  const CleanHeader({
    required this.searchController,
    required this.onSearchChanged,
    required this.onToggleTheme,
    super.key,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final width = MediaQuery.sizeOf(context).width;
    final showSearch = width >= DashboardDesign.mobileBreakpoint;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: DashboardDesign.canvas(context),
        border: Border(
          bottom: BorderSide(color: DashboardDesign.border(context)),
        ),
      ),
      child: SizedBox(
        height: 72,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: DashboardDesign.maxContentWidth,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: width < 700 ? 18 : 28),
              child: Stack(
                children: [
                  // Center-aligned logo with natural aspect ratio and proper fit
                  Align(
                    alignment: Alignment.center,
                    child: Transform.translate(
                      offset: const Offset(-50, 0),
                      child: DashboardDesign.isDark(context)
                          ? ShaderMask(
                              blendMode: BlendMode.srcIn,
                              shaderCallback: (bounds) =>
                                  const LinearGradient(
                                    colors: [
                                      Color(0xFF4D8FFF), // brand-blue highlight
                                      Color(0xFFF4F7F8), // darkText near-white
                                    ],
                                    stops: [0.0, 0.55],
                                  ).createShader(bounds),
                              child: Image.asset(
                                'assets/evalio_logo.png',
                                height: 60,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    Center(
                                  child: Icon(
                                    Icons.insights_rounded,
                                    size: 24,
                                    color: DashboardDesign.primary,
                                  ),
                                ),
                              ),
                            )
                          : Image.asset(
                              'assets/evalio_logo.png',
                              height: 60,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  Center(
                                child: Icon(
                                  Icons.insights_rounded,
                                  size: 24,
                                  color: DashboardDesign.primary,
                                ),
                              ),
                            ),
                    ),
                  ),
                  // Right-aligned actions (Search & Theme Toggle)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showSearch) ...[
                          SizedBox(
                            width: width >= DashboardDesign.desktopBreakpoint
                                ? 240
                                : 180,
                            child: DashboardSearchField(
                              controller: searchController,
                              onChanged: onSearchChanged,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Consumer(builder: (context, ref, child) {
                          final locale = ref.watch(localeProvider);
                          return PopupMenuButton<String>(
                            tooltip: 'Change language',
                            initialValue: locale,
                            onSelected: (value) {
                              ref.read(localeProvider.notifier).setLocale(value);
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(value: 'en', child: Text('English (EN)')),
                              PopupMenuItem(value: 'nl', child: Text('Dutch (NL)')),
                              PopupMenuItem(value: 'de', child: Text('Deutsch (DE)')),
                            ],
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: DashboardDesign.border(context)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                locale.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: DashboardDesign.text(context),
                                ),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          tooltip: user == null ? 'Account' : (user.email ?? 'Account'),
                          onSelected: (value) async {
                            if (value == 'theme') {
                              onToggleTheme();
                            } else if (value == 'pdf') {
                              context.go('/pdfs');
                            } else if (value == 'login') {
                              context.go('/login');
                            } else if (value == 'register') {
                              context.go('/register');
                            } else if (value == 'signout') {
                              await ref.read(authRepositoryProvider).signOut();
                              AppMessenger.info('Signed out.');
                              if (context.mounted) {
                                context.go('/login?reason=auth');
                              }
                            }
                          },
                          itemBuilder: (context) {
                            final isDark = DashboardDesign.isDark(context);
                            final themeItem = PopupMenuItem(
                              value: 'theme',
                              child: Row(
                                children: [
                                  Icon(
                                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                                    size: 18,
                                    color: DashboardDesign.mutedText(context),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(isDark ? 'Light mode' : 'Dark mode'),
                                ],
                              ),
                            );

                            final pdfItem = const PopupMenuItem(
                              value: 'pdf',
                              child: Row(
                                children: [
                                  Icon(Icons.picture_as_pdf_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text('PDFs'),
                                ],
                              ),
                            );

                            if (user == null) {
                              return [
                                const PopupMenuItem(value: 'login', child: Text('Sign in')),
                                const PopupMenuItem(
                                  value: 'register',
                                  child: Text('Create account'),
                                ),
                                const PopupMenuDivider(),
                                pdfItem,
                                themeItem,
                              ];
                            }
                            return [
                              PopupMenuItem(
                                enabled: false,
                                child: Text(user.email ?? 'Signed in'),
                              ),
                              pdfItem,
                              const PopupMenuItem(
                                value: 'signout',
                                child: Text('Sign out'),
                              ),
                              const PopupMenuDivider(),
                              themeItem,
                            ];
                          },
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor:
                                DashboardDesign.primary.withValues(alpha: 0.1),
                            child: Icon(
                              user == null
                                  ? Icons.person_outline_rounded
                                  : Icons.person_rounded,
                              size: 18,
                              color: DashboardDesign.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardSearchField extends ConsumerWidget {
  const DashboardSearchField({
    required this.controller,
    required this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);
    final t = ref.read(localeProvider.notifier).t;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: TextStyle(
        color: DashboardDesign.text(context),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: t('search_reviews'),
        hintStyle: TextStyle(
          color: DashboardDesign.mutedText(context),
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 19,
          color: DashboardDesign.mutedText(context),
        ),
        filled: true,
        fillColor: DashboardDesign.surface(context),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DashboardDesign.controlRadius),
          borderSide: BorderSide(color: DashboardDesign.border(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DashboardDesign.controlRadius),
          borderSide: const BorderSide(
            color: DashboardDesign.primary,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(
        foregroundColor: DashboardDesign.text(context),
        backgroundColor: DashboardDesign.surface(context),
        side: BorderSide(color: DashboardDesign.border(context)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DashboardDesign.controlRadius),
        ),
        fixedSize: const Size(44, 44),
      ),
    );
  }
}
