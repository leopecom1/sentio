import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sentio_app/config/theme.dart';
import 'package:sentio_app/config/constants.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  String _selectedCategory = 'all';

  final _categories = [
    {'id': 'all', 'label': 'Todas'},
    {'id': 'breathing', 'label': 'Respiración'},
    {'id': 'pause', 'label': 'Pausas'},
    {'id': 'anxiety', 'label': 'Ansiedad'},
    {'id': 'entrepreneur', 'label': 'Emprendedor'},
  ];

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'breathing':
        return Icons.air_rounded;
      case 'pause':
        return Icons.pause_circle_outline_rounded;
      case 'anxiety':
        return Icons.self_improvement_rounded;
      case 'entrepreneur':
        return Icons.rocket_launch_outlined;
      default:
        return Icons.spa_outlined;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'breathing':
        return SentioColors.accent;
      case 'pause':
        return SentioColors.primary;
      case 'anxiety':
        return SentioColors.warning;
      case 'entrepreneur':
        return SentioColors.secondary;
      default:
        return SentioColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final allFiltered = _selectedCategory == 'all'
        ? SentioConstants.tools
        : SentioConstants.tools
            .where((t) => t['category'] == _selectedCategory)
            .toList();
    final featuredTool = _selectedCategory == 'all'
        ? SentioConstants.tools.where((t) => t['featured'] == true).firstOrNull
        : null;
    final filteredTools = featuredTool != null
        ? allFiltered.where((t) => t['id'] != featuredTool['id']).toList()
        : allFiltered;

    return Scaffold(
      backgroundColor: SentioColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  if (context.canPop())
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: SentioColors.textPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                  Text(
                    'Herramientas',
                    style: GoogleFonts.manrope(
                      fontSize: 28,
                      color: SentioColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Acciones concretas para momentos difíciles.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: SentioColors.textSecondary,
                    ),
              ),
            ),
            const SizedBox(height: 16),
            // Category filters
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat['id'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat['id']!),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? SentioColors.primary
                            : SentioColors.card,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          cat['label']!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected
                                ? Colors.white
                                : SentioColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            // Tools list (featured + grid)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                physics: const BouncingScrollPhysics(),
                children: [
                  if (featuredTool != null) ...[
                    _buildFeaturedCard(featuredTool),
                    const SizedBox(height: 20),
                  ],
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    itemCount: filteredTools.length,
                    itemBuilder: (context, index) {
                      final tool = filteredTools[index];
                  final color = _getCategoryColor(tool['category']);
                  final icon = _getCategoryIcon(tool['category']);

                  return GestureDetector(
                    onTap: () => context.push('/tool/${tool['id']}'),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: SentioColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(icon, color: color, size: 24),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            tool['title'],
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tool['description'],
                            style: TextStyle(
                              fontSize: 12,
                              color: SentioColors.textTertiary,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              tool['duration'],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedCard(Map<String, dynamic> tool) {
    const color = Color(0xFFFF6B9D);
    return GestureDetector(
      onTap: () => context.push('/tool/${tool['id']}'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.18),
              SentioColors.primary.withValues(alpha: 0.12),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 24,
              spreadRadius: -4,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 16,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.white, size: 11),
                            const SizedBox(width: 3),
                            Text(
                              'DESTACADO',
                              style: GoogleFonts.manrope(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        tool['duration'],
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tool['title'],
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: SentioColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tool['description'],
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: SentioColors.textSecondary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color),
          ],
        ),
      ),
    );
  }
}
