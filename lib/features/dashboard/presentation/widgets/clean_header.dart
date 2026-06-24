import 'package:flutter/material.dart';

import '../theme/dashboard_design.dart';

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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: DashboardDesign.canvas(context),
        border: Border(
          bottom: BorderSide(color: DashboardDesign.border(context)),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: DashboardDesign.maxContentWidth,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: width < 700 ? 18 : 28),
            child: Row(
              children: [
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
                  child: Image.asset(
                    'assets/evalio_logo.jpeg',
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Icon(
                        Icons.insights_rounded,
                        size: 20,
                        color: DashboardDesign.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
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
                ),
                if (showSearch) ...[
                  const SizedBox(width: 24),
                  SizedBox(
                    width: width >= DashboardDesign.desktopBreakpoint
                        ? 310
                        : 250,
                    child: DashboardSearchField(
                      controller: searchController,
                      onChanged: onSearchChanged,
                    ),
                  ),
                ],
                const SizedBox(width: 10),
                _HeaderIconButton(
                  tooltip: 'Toggle theme',
                  icon: DashboardDesign.isDark(context)
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  onPressed: onToggleTheme,
                ),
              ],
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
