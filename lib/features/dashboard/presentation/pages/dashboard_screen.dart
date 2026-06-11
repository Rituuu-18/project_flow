import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import 'package:engineering_werk/features/reviews/domain/entities/design_review.dart';
import 'package:engineering_werk/features/reviews/presentation/providers/design_review_provider.dart';
import 'package:engineering_werk/core/utils/enums.dart';
import 'package:engineering_werk/features/settings/presentation/providers/theme_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reviewsAsync = ref.watch(designReviewsStreamProvider);
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark || 
                 (themeMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(isDark),
                    const SizedBox(height: 32),
                    _buildMainSearchField(isDark),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF006D6A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => _showAddReviewDialog(context, isDark),
                        child: const Text(
                          '+ New Design Review',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            reviewsAsync.when(
              data: (reviews) {
                final filtered = reviews.where((r) {
                  final sq = _searchController.text.toLowerCase();
                  if (sq.isEmpty) return true;
                  return r.name.toLowerCase().contains(sq);
                }).toList();

                if (filtered.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Text(
                        _searchController.text.isEmpty 
                            ? 'No Design Reviews yet.\nClick the button above to start one.'
                            : 'No results matching your search.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[400], fontSize: 16),
                      ),
                    ),
                  );
                }

                final active = filtered.where((r) => r.status != ProjectStatus.completed).toList();
                final completed = filtered.where((r) => r.status == ProjectStatus.completed).toList();

                final averageProgress = active.isEmpty 
                    ? 0.0 
                    : active.fold(0.0, (sum, r) => sum + r.progress) / active.length;

                return SliverList(
                  delegate: SliverChildListDelegate([
                    _buildMainProgressCard(active, isDark),
                    _buildListSection(
                      title: 'Active Design Reviews',
                      subtitle: 'PROJECT COMPLETION ${(averageProgress * 100).toInt()}%',
                      items: active,
                      isDark: isDark,
                    ),
                    if (completed.isNotEmpty)
                      _buildListSection(
                        title: 'Completed Design Reviews',
                        subtitle: 'COMPLETED',
                        items: completed,
                        isDark: isDark,
                      ),
                    const SizedBox(height: 60),
                  ]),
                );
              },
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
              error: (err, stack) => SliverFillRemaining(child: Center(child: Text('Error: $err'))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Image.asset(
                    'assets/logo.jpeg',
                    height: 32,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.broken_image_outlined,
                      color: Color(0xFF006D6A),
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'Design reviews',
                      style: TextStyle(
                        fontSize: 28, 
                        fontWeight: FontWeight.bold, 
                        color: isDark ? Colors.white : const Color(0xFF1F2937),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
              icon: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                color: isDark ? Colors.yellow[600] : Colors.grey[700],
              ),
              style: IconButton.styleFrom(
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[100],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Track active reviews, open completed records,\nand start a new design review from one place.',
          style: TextStyle(fontSize: 15, color: isDark ? Colors.grey[400] : Colors.grey[600], height: 1.5),
        ),
      ],
    );
  }

  Widget _buildMainSearchField(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.transparent : Colors.grey[200]!),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          hintText: 'Search projects...',
          hintStyle: TextStyle(fontSize: 16, color: isDark ? Colors.grey[500] : Colors.grey[400]),
          prefixIcon: Icon(Icons.search, color: isDark ? Colors.grey[500] : Colors.grey[400]),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: InputBorder.none,
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildListSection({
    required String title, 
    required String subtitle, 
    required List<DesignReview> items,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title, 
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1F2937)),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle, 
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.grey[500] : Colors.grey[400], letterSpacing: 1.2),
          ),
          const SizedBox(height: 20),
          ...items.map((item) => _buildReviewCard(item, isDark)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildReviewCard(DesignReview review, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: InkWell(
        onTap: () {
          if (!context.mounted) return;
          context.push('/project/${review.id}');
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  height: 160,
                  color: const Color(0xFF006D6A).withValues(alpha: 0.05),
                  child: Image.asset(
                    review.imageUrl ?? 'assets/pump-housing.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_outlined, color: isDark ? Colors.grey[600] : Colors.grey[400], size: 32),
                          const SizedBox(height: 8),
                          Text(
                            'Project preview image', 
                            style: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[400], fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildActionButton(review, isDark),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      review.name,
                      style: TextStyle(
                        fontSize: 22, 
                        fontWeight: FontWeight.bold, 
                        color: isDark ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
                  ),
                  if (review.owner.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Owner: ${review.owner}',
                            style: TextStyle(
                              fontSize: 15, 
                              color: isDark ? Colors.grey[300] : Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  Text(
                    '${(review.progress * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF006D6A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: review.progress,
                  minHeight: 6,
                  backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF006D6A)),
                ),
              ),
              const SizedBox(height: 20),
              _buildStatusDropdown(review, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(DesignReview review, bool isDark) {
    return PopupMenuButton<String>(
      onSelected: (val) => _handleMenuAction(val, review),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'upload', child: Text('Upload Image')),
        const PopupMenuItem(value: 'prepare_slide', child: Text('Prepare slide')),
        const PopupMenuItem(value: 'copy', child: Text('Copy')),
        const PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
      offset: const Offset(0, 48),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
        ),
        child: Text(
          '...', 
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
        ),
      ),
    );
  }

  Widget _buildStatusDropdown(DesignReview review, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ProjectStatus>(
          value: review.status,
          isDense: true,
          dropdownColor: isDark ? Colors.grey[850] : Colors.white,
          icon: Icon(Icons.arrow_drop_down, color: isDark ? Colors.grey[400] : Colors.grey[600]),
          style: TextStyle(fontSize: 15, color: isDark ? Colors.white : Colors.black87),
          items: const [
            DropdownMenuItem(value: ProjectStatus.active, child: Text('In Progress')),
            DropdownMenuItem(value: ProjectStatus.reviewPending, child: Text('Review Pending')),
            DropdownMenuItem(value: ProjectStatus.completed, child: Text('Completed')),
          ],
          onChanged: (val) {
            if (val != null) {
              ref.read(designReviewNotifierProvider.notifier).updateReview(review.copyWith(status: val));
            }
          },
        ),
      ),
    );
  }

  void _showAddReviewDialog(BuildContext context, bool isDark) {
    final nameController = TextEditingController();
    final ownerController = TextEditingController();
    final disciplineController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'CREATE DESIGN REVIEW',
                      style: TextStyle(
                        fontSize: 11, 
                        fontWeight: FontWeight.bold, 
                        color: isDark ? Colors.grey[400] : Colors.grey[600], 
                        letterSpacing: 1.2,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, size: 20, color: isDark ? Colors.grey[400] : Colors.grey[500]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'New Design Review',
                  style: TextStyle(
                    fontSize: 26, 
                    fontWeight: FontWeight.bold, 
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Add a design review name, owner, and discipline. New reviews start in progress by default with no image required.',
                  style: TextStyle(
                    fontSize: 15, 
                    color: isDark ? Colors.grey[400] : Colors.grey[600], 
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                _buildFieldLabel('DESIGN REVIEW NAME', isDark),
                _buildTextField(nameController, 'e.g. Gearbox Cover Rev A', isDark),
                const SizedBox(height: 20),
                _buildFieldLabel('OWNER', isDark),
                _buildTextField(ownerController, 'Owner', isDark),
                const SizedBox(height: 20),
                _buildFieldLabel('DISCIPLINE', isDark),
                _buildTextField(disciplineController, 'Discipline', isDark),
                const SizedBox(height: 36),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel', 
                        style: TextStyle(
                          color: isDark ? Colors.grey[300] : Colors.black87, 
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006D6A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          final review = DesignReview(
                            id: const Uuid().v4(),
                            name: nameController.text,
                            owner: ownerController.text,
                            discipline: disciplineController.text,
                            createdAt: DateTime.now(),
                            lastUpdated: DateTime.now(),
                          );
                          await ref.read(designReviewNotifierProvider.notifier).createReview(review);
                          if (context.mounted) Navigator.pop(context);
                        }
                      },
                      child: const Text('Create', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11, 
          fontWeight: FontWeight.bold, 
          color: isDark ? Colors.grey[400] : Colors.grey[700], 
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, bool isDark) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[400], fontSize: 16),
        filled: true,
        fillColor: isDark ? const Color(0xFF111827) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF006D6A), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
      ),
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    );
  }

  void _handleMenuAction(String action, DesignReview review) async {
    if (action == 'upload') {
      final picker = ImagePicker();
      final notifier = ref.read(designReviewNotifierProvider.notifier);
      final file = await picker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        await notifier.updateReview(review.copyWith(imageUrl: file.path));
      }
    } else if (action == 'prepare_slide') {
      // TODO: Implement prepare slide logic
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prepare slide clicked')),
        );
      }
    } else if (action == 'copy') {
      final newReview = review.copyWith(
        id: const Uuid().v4(),
        name: 'Copy of ${review.name}',
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      );
      await ref.read(designReviewNotifierProvider.notifier).createReview(newReview);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review copied successfully')),
        );
      }
    } else if (action == 'delete') {
      await ref.read(designReviewNotifierProvider.notifier).deleteReview(review.id);
    }
  }

  Widget _buildMainProgressCard(List<DesignReview> activeReviews, bool isDark) {
    if (activeReviews.isEmpty) return const SizedBox.shrink();
    final averageProgress = activeReviews.fold(0.0, (sum, r) => sum + r.progress) / activeReviews.length;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3FBFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey[800]! : const Color(0xFFCCE2E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PROJECT COMPLETION',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey[400] : const Color(0xFF006D6A),
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                '${(averageProgress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF006D6A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: averageProgress,
              minHeight: 10,
              backgroundColor: isDark ? Colors.grey[800] : const Color(0xFFE0F2F1),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF006D6A)),
            ),
          ),
        ],
      ),
    );
  }
}


