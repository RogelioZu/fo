import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Pantalla de búsqueda de Finding Out.
/// Dos estados: inicial (recientes + categorías) y activo (resultados).
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;

  bool _isSearching = false;
  bool _isLoading = false;
  String _query = '';

  // Resultados
  List<Map<String, dynamic>> _people = [];
  List<Map<String, dynamic>> _events = [];

  // Búsquedas recientes (mock local por ahora)
  final List<String> _recentSearches = [
    'Lollapalooza 2024',
    'Zdenko',
    'Conciertos en CDMX',
  ];

  static const _categories = [
    {'icon': LucideIcons.music, 'label': 'Música'},
    {'icon': LucideIcons.palette, 'label': 'Arte'},
    {'icon': LucideIcons.utensils, 'label': 'Comida'},
    {'icon': LucideIcons.dumbbell, 'label': 'Deportes'},
    {'icon': LucideIcons.ticket, 'label': 'Festivales'},
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    final text = _controller.text.trim();
    _debounce?.cancel();

    if (text.isEmpty) {
      setState(() {
        _isSearching = false;
        _query = '';
        _people = [];
        _events = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _query = text;
    });

    _debounce = Timer(const Duration(milliseconds: 400), () {
      _performSearch(text);
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;

      // Buscar personas
      final peopleRes = await supabase
          .from('profiles')
          .select('id, full_name, username, avatar_url')
          .or('full_name.ilike.%$query%,username.ilike.%$query%')
          .limit(10);

      // Buscar eventos
      final eventsRes = await supabase
          .from('events')
          .select('id, title, address, image_url, date, category')
          .ilike('title', '%$query%')
          .limit(10);

      if (!mounted) return;
      setState(() {
        _people = List<Map<String, dynamic>>.from(peopleRes);
        _events = List<Map<String, dynamic>>.from(eventsRes);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _clearSearch() {
    _controller.clear();
    _focusNode.unfocus();
  }

  void _removeRecent(int index) {
    setState(() => _recentSearches.removeAt(index));
  }

  void _clearAllRecent() {
    setState(() => _recentSearches.clear());
  }

  void _searchFromRecent(String text) {
    _controller.text = text;
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header ───
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                0,
              ),
              child: Text(
                _isSearching ? 'Resultados' : 'Explora',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.black,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ─── Search bar ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _SearchBar(
                controller: _controller,
                focusNode: _focusNode,
                isSearching: _isSearching,
                onClear: _clearSearch,
                onBack: _clearSearch,
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ─── Content ───
            Expanded(
              child: _isSearching
                  ? _ResultsView(
                      isLoading: _isLoading,
                      query: _query,
                      people: _people,
                      events: _events,
                    )
                  : _InitialView(
                      recentSearches: _recentSearches,
                      onTapRecent: _searchFromRecent,
                      onRemoveRecent: _removeRecent,
                      onClearAll: _clearAllRecent,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Search Bar
// ──────────────────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.isSearching,
    required this.onClear,
    required this.onBack,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSearching;
  final VoidCallback onClear;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          // Leading icon: search o back arrow
          GestureDetector(
            onTap: isSearching ? onBack : null,
            child: Icon(
              isSearching ? LucideIcons.arrowLeft : LucideIcons.search,
              size: 18,
              color: isSearching ? AppColors.black : AppColors.gray400,
            ),
          ),
          const SizedBox(width: 10),
          // Input
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: AppColors.black,
              ),
              decoration: InputDecoration(
                hintText: 'Busca eventos, personas...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: AppColors.gray400,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          // Clear button
          if (isSearching)
            GestureDetector(
              onTap: onClear,
              child: const Icon(
                LucideIcons.x,
                size: 18,
                color: AppColors.gray400,
              ),
            ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Initial View (recientes + categorías)
// ──────────────────────────────────────────────────────────────────────────────

class _InitialView extends StatelessWidget {
  const _InitialView({
    required this.recentSearches,
    required this.onTapRecent,
    required this.onRemoveRecent,
    required this.onClearAll,
  });

  final List<String> recentSearches;
  final ValueChanged<String> onTapRecent;
  final ValueChanged<int> onRemoveRecent;
  final VoidCallback onClearAll;

  static const _categories = [
    {'icon': LucideIcons.music, 'label': 'Música'},
    {'icon': LucideIcons.palette, 'label': 'Arte'},
    {'icon': LucideIcons.utensils, 'label': 'Comida'},
    {'icon': LucideIcons.dumbbell, 'label': 'Deportes'},
    {'icon': LucideIcons.ticket, 'label': 'Festivales'},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: 120,
      ),
      children: [
        // ─── Búsquedas recientes ───
        if (recentSearches.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Búsquedas recientes',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
              GestureDetector(
                onTap: onClearAll,
                child: Text(
                  'Borrar todo',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6366F1),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...List.generate(recentSearches.length, (i) {
            return _RecentSearchItem(
              text: recentSearches[i],
              onTap: () => onTapRecent(recentSearches[i]),
              onRemove: () => onRemoveRecent(i),
            );
          }),
          const SizedBox(height: 28),
        ],

        // ─── Categorías populares ───
        Text(
          'Categorías populares',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _categories.map((cat) {
            return _CategoryChip(
              icon: cat['icon'] as IconData,
              label: cat['label'] as String,
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Recent Search Item
// ──────────────────────────────────────────────────────────────────────────────

class _RecentSearchItem extends StatelessWidget {
  const _RecentSearchItem({
    required this.text,
    required this.onTap,
    required this.onRemove,
  });

  final String text;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            const Icon(LucideIcons.history, size: 18, color: AppColors.gray400),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ),
            GestureDetector(
              onTap: onRemove,
              child: const Icon(
                LucideIcons.x,
                size: 18,
                color: AppColors.gray200,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Category Chip
// ──────────────────────────────────────────────────────────────────────────────

class _CategoryChip extends StatefulWidget {
  const _CategoryChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  State<_CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<_CategoryChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 60),
      reverseDuration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scaleCtrl.forward(),
      onTapUp: (_) => _scaleCtrl.reverse(),
      onTapCancel: () => _scaleCtrl.reverse(),
      onTap: () {
        HapticFeedback.selectionClick();
        // TODO: filtrar por categoría
      },
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.gray100,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 16, color: const Color(0xFF6366F1)),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Results View
// ──────────────────────────────────────────────────────────────────────────────

class _ResultsView extends StatelessWidget {
  const _ResultsView({
    required this.isLoading,
    required this.query,
    required this.people,
    required this.events,
  });

  final bool isLoading;
  final String query;
  final List<Map<String, dynamic>> people;
  final List<Map<String, dynamic>> events;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.black,
          strokeWidth: 2,
        ),
      );
    }

    final hasPeople = people.isNotEmpty;
    final hasEvents = events.isNotEmpty;

    if (!hasPeople && !hasEvents) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.searchX, size: 40, color: AppColors.gray200),
            const SizedBox(height: AppSpacing.ms),
            Text(
              'Sin resultados para "$query"',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.gray400,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: 120,
      ),
      children: [
        // ─── Personas ───
        if (hasPeople) ...[
          _SectionHeader(title: 'Personas', onSeeAll: () {}),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: people.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (_, i) => _PersonAvatar(person: people[i]),
            ),
          ),
          const SizedBox(height: 28),
        ],

        // ─── Eventos ───
        if (hasEvents) ...[
          _SectionHeader(title: 'Eventos relacionados', onSeeAll: () {}),
          const SizedBox(height: AppSpacing.md),
          ...events.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _EventCard(event: e),
            ),
          ),
        ],
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Section Header (Personas / Eventos + Ver todos)
// ──────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onSeeAll});

  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.black,
          ),
        ),
        GestureDetector(
          onTap: onSeeAll,
          child: Text(
            'Ver todos',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6366F1),
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Person Avatar
// ──────────────────────────────────────────────────────────────────────────────

class _PersonAvatar extends StatelessWidget {
  const _PersonAvatar({required this.person});

  final Map<String, dynamic> person;

  @override
  Widget build(BuildContext context) {
    final name =
        person['full_name'] as String? ?? person['username'] as String? ?? '?';
    final avatarUrl = person['avatar_url'] as String?;

    return SizedBox(
      width: 80,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE0E7FF), width: 2),
              image: avatarUrl != null && avatarUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(avatarUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: avatarUrl == null || avatarUrl.isEmpty
                  ? AppColors.gray100
                  : null,
            ),
            child: avatarUrl == null || avatarUrl.isEmpty
                ? const Icon(LucideIcons.user, color: AppColors.gray400)
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Event Card
// ──────────────────────────────────────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final Map<String, dynamic> event;

  @override
  Widget build(BuildContext context) {
    final title = event['title'] as String? ?? '';
    final address = event['address'] as String? ?? '';
    final date = event['date'] as String? ?? '';
    final imageUrl = event['image_url'] as String?;

    // Formatear subtítulo
    final subtitle = [
      if (address.isNotEmpty) address,
      if (date.isNotEmpty) date,
    ].join(' • ');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            offset: const Offset(0, 2),
            blurRadius: 10,
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Imagen del evento
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: AppColors.gray100,
              image: imageUrl != null && imageUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imageUrl == null || imageUrl.isEmpty
                ? const Icon(LucideIcons.calendar, color: AppColors.gray400)
                : null,
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.gray400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
