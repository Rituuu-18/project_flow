import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/dashboard_design.dart';
import 'evalio_logo_svg.dart';

class CleanHeader extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final showSearch = width >= DashboardDesign.mobileBreakpoint;
    final isDark = DashboardDesign.isDark(context);

    final logoWidget = SvgPicture.string(
      EvalioLogoSvg.getLogo(isDark: isDark),
      height: 35,
      fit: BoxFit.contain,
    );

    if (width < 700) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: DashboardDesign.canvas(context),
          border: Border(
            bottom: BorderSide(color: DashboardDesign.border(context)),
          ),
        ),
        child: SizedBox(
          height: 72,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: logoWidget,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: _HeaderIconButton(
                    tooltip: 'Toggle theme',
                    icon: isDark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    onPressed: onToggleTheme,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final double searchWidth;
    if (width >= DashboardDesign.desktopBreakpoint) {
      searchWidth = 310;
    } else if (width >= 850) {
      searchWidth = 250;
    } else {
      searchWidth = 160;
    }

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
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Stack(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: logoWidget,
                ),
                Positioned.fill(
                  child: Row(
                    children: [
                      if (width >= 980) ...[
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(
                              color: DashboardDesign.border(context),
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: SvgPicture.string(
                            EvalioLogoSvg.getMonogram(isDark: false),
                            width: 40,
                            height: 40,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Design reviews',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: DashboardDesign.text(context),
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                            if (width >= DashboardDesign.desktopBreakpoint)
                              Text(
                                'A clear record of decisions, evidence, and approvals.',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: DashboardDesign.mutedText(context),
                                  fontSize: 12,
                                  height: 1.25,
                                ),
                              ),
                          ],
                        ),
                      ],
                      const Spacer(),
                      if (showSearch)
                        SizedBox(
                          width: searchWidth,
                          child: DashboardSearchField(
                            controller: searchController,
                            onChanged: onSearchChanged,
                          ),
                        ),
                      const SizedBox(width: 10),
                      _HeaderIconButton(
                        tooltip: 'Toggle theme',
                        icon: isDark
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                        onPressed: onToggleTheme,
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

class DashboardSearchField extends StatelessWidget {
  const DashboardSearchField({
    required this.controller,
    required this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
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
        hintText: 'Search reviews...',
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
