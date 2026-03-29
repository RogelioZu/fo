import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/datasources/events_remote_datasource.dart';
import '../../data/models/event_model.dart';

// ─── Data classes ─────────────────────────────────────────────────────────────

class _EventCategory {
  final String id;
  final String label;
  final IconData icon;
  const _EventCategory(this.id, this.label, this.icon);
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  int _step = 0;
  final _pageController = PageController();
  final _datasource = EventsRemoteDatasource();
  bool _isPublishing = false;

  // Step 1 – Basic
  File? _coverImage;
  final _titleController = TextEditingController();
  int _selectedCategory = 0;

  // Step 2 – When & Where
  DateTime _selectedDate = DateTime.now();
  int _selectedTimeSlot = 0;
  TimeOfDay? _customTime;
  final _locationController = TextEditingController();
  double? _locationLat;
  double? _locationLng;

  // Step 3 – Details
  final _descController = TextEditingController();
  final Set<int> _selectedTags = {0};
  bool _isPublic = true;
  bool _allowComments = true;
  bool _isFree = true;
  final _capacityController = TextEditingController();
  final _priceController = TextEditingController();
  final _ticketNameController = TextEditingController(text: 'General Admission');
  final _ticketQtyController = TextEditingController();

  // ── Categories ──────────────────────────────────────────────────────────────

  static const _categories = [
    _EventCategory('music', 'Music', LucideIcons.music),
    _EventCategory('sports', 'Sports', LucideIcons.dumbbell),
    _EventCategory('art', 'Art', LucideIcons.palette),
    _EventCategory('food', 'Food', LucideIcons.utensils),
    _EventCategory('tech', 'Tech', LucideIcons.monitor),
    _EventCategory('theater', 'Theater', LucideIcons.mic),
    _EventCategory('photo', 'Photo', LucideIcons.camera),
    _EventCategory('gaming', 'Gaming', LucideIcons.gamepad2),
  ];

  // ── Time options ─────────────────────────────────────────────────────────────

  static const _timeSlots = ['19:00', '20:00', '21:00', 'Other'];

  // ── Suggested tags ──────────────────────────────────────────────────────────

  static const _tagOptions = ['+ festival', '+ summer', '+ live music'];

  // ─── Lifecycle ───────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _locationController.dispose();
    _descController.dispose();
    _capacityController.dispose();
    _priceController.dispose();
    _ticketNameController.dispose();
    _ticketQtyController.dispose();
    super.dispose();
  }

  // ─── Navigation ──────────────────────────────────────────────────────────────

  void _goTo(int step) {
    setState(() => _step = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut,
    );
  }

  void _next() {
    HapticFeedback.mediumImpact();
    if (_step < 3) _goTo(_step + 1);
  }

  void _back() {
    HapticFeedback.selectionClick();
    if (_step > 0) {
      _goTo(_step - 1);
    } else {
      context.pop();
    }
  }

  // ─── Image picker ─────────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image != null) setState(() => _coverImage = File(image.path));
  }

  // ─── Location ─────────────────────────────────────────────────────────────────

  Future<void> _useCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final newPerm = await Geolocator.requestPermission();
        if (newPerm == LocationPermission.denied ||
            newPerm == LocationPermission.deniedForever) return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      setState(() {
        _locationLat = position.latitude;
        _locationLng = position.longitude;
      });

      // Reverse geocode para mostrar dirección legible
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final address = [
            p.street,
            p.locality,
            p.administrativeArea,
          ].where((s) => s != null && s.isNotEmpty).join(', ');
          _locationController.text = address;
        }
      } catch (_) {
        _locationController.text =
            '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: $e')),
        );
      }
    }
  }

  // ─── Time picker ──────────────────────────────────────────────────────────────

  Future<void> _pickCustomTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _customTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.black,
              onPrimary: AppColors.white,
              surface: AppColors.white,
              onSurface: AppColors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      setState(() {
        _customTime = time;
        _selectedTimeSlot = _timeSlots.length - 1; // "Other"
      });
    }
  }

  // ─── Build start time from selection ────────────────────────────────────────────

  DateTime _buildStartDateTime() {
    final date = _selectedDate;
    if (_selectedTimeSlot == _timeSlots.length - 1 && _customTime != null) {
      return DateTime(date.year, date.month, date.day,
          _customTime!.hour, _customTime!.minute);
    }
    final parts = _timeSlots[_selectedTimeSlot].split(':');
    final hour = int.tryParse(parts[0]) ?? 19;
    final minute = int.tryParse(parts[1]) ?? 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  // ─── Publish / Save Draft ──────────────────────────────────────────────────────

  Future<void> _publishEvent() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an event title')),
      );
      _goTo(0);
      return;
    }

    setState(() => _isPublishing = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final event = Event(
        creatorId: userId,
        title: _titleController.text.trim(),
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        categoryId: _categories[_selectedCategory].id,
        locationLat: _locationLat,
        locationLng: _locationLng,
        address: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        startDate: _buildStartDateTime(),
        status: 'published',
        tags: _selectedTags
            .map((i) => _tagOptions[i].replaceFirst('+ ', ''))
            .toList(),
        isPublic: _isPublic,
        allowComments: _allowComments,
        isFree: _isFree,
        maxCapacity: _capacityController.text.trim().isNotEmpty
            ? int.tryParse(_capacityController.text.trim())
            : null,
      );

      await _datasource.createEvent(event, coverImage: _coverImage);

      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Event published! 🎉',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error publishing: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  Future<void> _saveAsDraft() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title to save draft')),
      );
      return;
    }

    setState(() => _isPublishing = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final event = Event(
        creatorId: userId,
        title: _titleController.text.trim(),
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        categoryId: _categories[_selectedCategory].id,
        locationLat: _locationLat,
        locationLng: _locationLng,
        address: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        startDate: _buildStartDateTime(),
        status: 'draft',
        tags: _selectedTags
            .map((i) => _tagOptions[i].replaceFirst('+ ', ''))
            .toList(),
        isPublic: _isPublic,
        allowComments: _allowComments,
        isFree: _isFree,
        maxCapacity: _capacityController.text.trim().isNotEmpty
            ? int.tryParse(_capacityController.text.trim())
            : null,
      );

      await _datasource.createEvent(event, coverImage: _coverImage);

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Draft saved',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving draft: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStep1(),
              _buildStep2(),
              _buildStep3(),
              _buildStep4(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Shared widgets ──────────────────────────────────────────────────────────

  Widget _progressBar() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          children: List.generate(4, (i) {
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 4,
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                decoration: BoxDecoration(
                  color: i <= _step ? AppColors.black : AppColors.gray200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
      );

  Widget _navRow(String stepText, {bool isFirst = false}) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 12,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: _back,
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.gray100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isFirst ? LucideIcons.x : LucideIcons.arrowLeft,
                  size: 18,
                  color: AppColors.black,
                ),
              ),
            ),
            Text(
              'Create Event',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.black,
              ),
            ),
            Text(
              stepText,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.gray400,
              ),
            ),
          ],
        ),
      );

  Widget _continueBtn(VoidCallback onTap) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          12,
          AppSpacing.lg,
          20,
        ),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.black,
              borderRadius: AppRadius.pillRadius,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Continue',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  LucideIcons.arrowRight,
                  color: AppColors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      );

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
      );

  // ─── STEP 1 – Basic ──────────────────────────────────────────────────────────

  Widget _buildStep1() {
    return Column(
      children: [
        _progressBar(),
        _navRow('1 of 4', isFirst: true),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create something\namazing ✨',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.black,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg20),
                _photoUpload(),
                const SizedBox(height: AppSpacing.lg20),
                _titleInput(),
                const SizedBox(height: AppSpacing.lg20),
                _categorySection(),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ),
        _continueBtn(_next),
      ],
    );
  }

  Widget _photoUpload() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _coverImage == null ? const Color(0xFFFAFAFA) : null,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.gray200, width: 2),
          image: _coverImage != null
              ? DecorationImage(
                  image: FileImage(_coverImage!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: _coverImage == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: AppColors.gray100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.camera,
                      size: 24,
                      color: AppColors.gray500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Add a cover photo',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Events with photos get 5x more views',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.gray400,
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }

  Widget _titleInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label("What's your event called?"),
        const SizedBox(height: 6),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _titleController,
          builder: (context, val, _) => Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.black, width: 1.5),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _titleController,
                    maxLength: 80,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: AppColors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'E.g. Summer Music Festival',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 15,
                        color: AppColors.gray400,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      counterText: '',
                    ),
                  ),
                ),
                Text(
                  '${val.text.length}/80',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.gray200,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _categorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Category'),
        const SizedBox(height: 10),
        _categoryRow(0, 4),
        const SizedBox(height: 8),
        _categoryRow(4, 8),
      ],
    );
  }

  Widget _categoryRow(int from, int to) {
    return Row(
      children: List.generate(to - from, (idx) {
        final i = from + idx;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < to - 1 ? 8 : 0),
            child: _categoryChip(i),
          ),
        );
      }),
    );
  }

  Widget _categoryChip(int i) {
    final cat = _categories[i];
    final selected = _selectedCategory == i;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedCategory = i);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.black : AppColors.gray50,
          borderRadius: BorderRadius.circular(12),
          border: selected
              ? null
              : Border.all(color: AppColors.gray200, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              cat.icon,
              size: 20,
              color: selected ? AppColors.white : AppColors.gray500,
            ),
            const SizedBox(height: 4),
            Text(
              cat.label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: selected ? AppColors.white : AppColors.gray500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── STEP 2 – When & Where ────────────────────────────────────────────────────

  Widget _buildStep2() {
    return Column(
      children: [
        _progressBar(),
        _navRow('2 of 4'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'When and\nwhere? 📅',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.black,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg20),
                _dateSection(),
                const SizedBox(height: AppSpacing.lg20),
                _timeSection(),
                const SizedBox(height: AppSpacing.lg20),
                _locationSection(),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ),
        _continueBtn(_next),
      ],
    );
  }

  Widget _dateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Date & Time'),
        const SizedBox(height: 10),
        _calendarCard(),
      ],
    );
  }

  Widget _calendarCard() {
    final year = _selectedDate.year;
    final month = _selectedDate.month;
    final day = _selectedDate.day;
    final firstWeekday = DateTime(year, month, 1).weekday % 7; // Sun=0
    final daysInMonth = DateTime(year, month + 1, 0).day;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.gray200, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Month navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => setState(() {
                  _selectedDate = DateTime(year, month - 1, day.clamp(1, 28));
                }),
                child: const Icon(
                  LucideIcons.chevronLeft,
                  size: 18,
                  color: AppColors.black,
                ),
              ),
              Text(
                '${_monthName(month)} $year',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() {
                  _selectedDate = DateTime(year, month + 1, day.clamp(1, 28));
                }),
                child: const Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Day headers
          Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.gray400,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          // Days grid
          ..._calendarRows(year, month, day, firstWeekday, daysInMonth),
        ],
      ),
    );
  }

  List<Widget> _calendarRows(
    int year,
    int month,
    int selectedDay,
    int startOffset,
    int daysInMonth,
  ) {
    final List<int?> cells = [
      ...List.filled(startOffset, null),
      ...List.generate(daysInMonth, (i) => i + 1),
    ];
    while (cells.length % 7 != 0) { cells.add(null); }

    final List<Widget> rows = [];
    for (int r = 0; r < cells.length ~/ 7; r++) {
      final rowCells = cells.sublist(r * 7, r * 7 + 7);
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: rowCells.map((d) {
              if (d == null) return const Expanded(child: SizedBox(height: 32));
              final isSelected = d == selectedDay;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _selectedDate = DateTime(year, month, d);
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 32,
                    decoration: isSelected
                        ? const BoxDecoration(
                            color: AppColors.black,
                            shape: BoxShape.circle,
                          )
                        : null,
                    child: Center(
                      child: Text(
                        '$d',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.normal,
                          color:
                              isSelected ? AppColors.white : AppColors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      );
    }
    return rows;
  }

  String _monthName(int m) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return names[m - 1];
  }

  Widget _timeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Start time'),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(_timeSlots.length, (i) {
              final selected = _selectedTimeSlot == i;
              return Padding(
                padding: EdgeInsets.only(
                  right: i < _timeSlots.length - 1 ? 8 : 0,
                ),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    if (i == _timeSlots.length - 1) {
                      _pickCustomTime();
                    } else {
                      setState(() => _selectedTimeSlot = i);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.black : AppColors.gray100,
                      borderRadius: AppRadius.pillRadius,
                    ),
                    child: Text(
                      i == _timeSlots.length - 1 && _customTime != null
                          ? _customTime!.format(context)
                          : _timeSlots[i],
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: selected ? AppColors.white : AppColors.black,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _locationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Location'),
        const SizedBox(height: 8),
        // Search bar
        Container(
          decoration: BoxDecoration(
            color: AppColors.gray100,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(LucideIcons.search, size: 16, color: AppColors.gray400),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _locationController,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.black,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search for an address or place...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.gray400,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Use current location
        GestureDetector(
          onTap: _useCurrentLocation,
          child: Row(
            children: [
              Icon(LucideIcons.crosshair, size: 16, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(
                'Use my current location',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Map preview placeholder
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 110,
            color: AppColors.gray100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Grid lines to suggest a map
                CustomPaint(
                  size: const Size(double.infinity, 110),
                  painter: _MapGridPainter(),
                ),
                // Pin
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.mapPin,
                    size: 14,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── STEP 3 – Details ─────────────────────────────────────────────────────────

  Widget _buildStep3() {
    return Column(
      children: [
        _progressBar(),
        _navRow('3 of 4'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tell us\nmore 📝',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.black,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg20),
                _descriptionSection(),
                const SizedBox(height: AppSpacing.lg20),
                _tagsSection(),
                const SizedBox(height: AppSpacing.lg20),
                _settingsCard(),
                const SizedBox(height: AppSpacing.lg20),
                _capacityInput(),
                const SizedBox(height: AppSpacing.lg20),
                _pricingCard(),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ),
        _continueBtn(_next),
      ],
    );
  }

  Widget _descriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Description'),
        const SizedBox(height: 8),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _descController,
          builder: (context, val, _) => Container(
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gray200, width: 1.5),
            ),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Column(
              children: [
                Expanded(
                  child: TextField(
                    controller: _descController,
                    maxLength: 500,
                    maxLines: null,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.black,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'Tell people what to expect, what to bring, the vibe...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.gray400,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      counterText: '',
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    '${val.text.length}/500',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.gray200,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _tagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Tags'),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(_tagOptions.length, (i) {
              final selected = _selectedTags.contains(i);
              return Padding(
                padding: EdgeInsets.only(
                  right: i < _tagOptions.length - 1 ? 6 : 0,
                ),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => selected
                        ? _selectedTags.remove(i)
                        : _selectedTags.add(i));
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.black : AppColors.gray100,
                      borderRadius: AppRadius.pillRadius,
                    ),
                    child: Text(
                      _tagOptions[i],
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: selected ? AppColors.white : AppColors.black,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _settingsCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray200, width: 1),
      ),
      child: Column(
        children: [
          _toggleRow(
            icon: LucideIcons.globe,
            title: 'Public event',
            subtitle: 'Anyone can see it',
            value: _isPublic,
            onChanged: (v) => setState(() => _isPublic = v),
          ),
          Container(height: 1, color: AppColors.gray200),
          _toggleRow(
            icon: LucideIcons.messageCircle,
            title: 'Allow comments',
            subtitle: 'Attendees can comment',
            value: _allowComments,
            onChanged: (v) => setState(() => _allowComments = v),
          ),
        ],
      ),
    );
  }

  Widget _pricingCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Pricing'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.gray50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.gray200, width: 1),
          ),
          child: Column(
            children: [
              _toggleRow(
                icon: LucideIcons.ticket,
                title: 'Free event',
                subtitle: 'No ticket required',
                value: _isFree,
                onChanged: (v) => setState(() => _isFree = v),
              ),
              if (!_isFree) ...[
                Container(height: 1, color: AppColors.gray200),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Ticket details'),
                      const SizedBox(height: 10),
                      _ticketField(
                        controller: _ticketNameController,
                        hint: 'Ticket name (e.g. General)',
                        icon: LucideIcons.tag,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _ticketField(
                              controller: _priceController,
                              hint: 'Price',
                              icon: LucideIcons.dollarSign,
                              keyboardType: TextInputType.number,
                              prefix: '\$ ',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _ticketField(
                              controller: _ticketQtyController,
                              hint: 'Quantity',
                              icon: LucideIcons.hash,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'More ticket types can be added after publishing',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.gray400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _ticketField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? prefix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gray200, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.gray400),
          const SizedBox(width: 8),
          if (prefix != null)
            Text(prefix, style: GoogleFonts.inter(fontSize: 14, color: AppColors.gray500)),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.black),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.gray400),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _capacityInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Maximum attendees (optional)'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.gray200, width: 1.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Icon(LucideIcons.users, size: 16, color: AppColors.gray400),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _capacityController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.inter(fontSize: 15, color: AppColors.black),
                  decoration: InputDecoration(
                    hintText: 'e.g. 100',
                    hintStyle: GoogleFonts.inter(fontSize: 15, color: AppColors.gray400),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _toggleRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.gray500),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.gray400,
                    ),
                  ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.white,
            activeTrackColor: AppColors.black,
            inactiveThumbColor: AppColors.white,
            inactiveTrackColor: AppColors.gray200,
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ],
      ),
    );
  }

  // ─── STEP 4 – Preview ─────────────────────────────────────────────────────────

  Widget _buildStep4() {
    final title = _titleController.text.isEmpty
        ? 'Summer Music Festival'
        : _titleController.text;
    final catLabel = _categories[_selectedCategory].label;
    final timeLabel = (_selectedTimeSlot == _timeSlots.length - 1 && _customTime != null)
        ? _customTime!.format(context)
        : _timeSlots[_selectedTimeSlot];
    final dateStr =
        '${_selectedDate.day} ${_monthName(_selectedDate.month).substring(0, 3)} · $timeLabel';
    final location = _locationController.text.isEmpty
        ? 'Location TBD'
        : _locationController.text;

    return Column(
      children: [
        _progressBar(),
        _navRow('4 of 4'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Looking\ngreat! 🎉',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.black,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Review how others will see it before publishing',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.gray500,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg20),
                _previewCard(title, catLabel, dateStr, location),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => _goTo(0),
                      child: Text(
                        '← Edit title',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.gray400,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _goTo(2),
                      child: Text(
                        'Edit details →',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.gray400,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      LucideIcons.cloud,
                      size: 14,
                      color: AppColors.gray400,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Draft saved automatically',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.gray400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ),
        _publishButtons(),
      ],
    );
  }

  Widget _previewCard(
    String title,
    String catLabel,
    String dateStr,
    String location,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.gray200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.card),
            ),
            child: _coverImage != null
                ? Image.file(
                    _coverImage!,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Container(
                    height: 160,
                    color: AppColors.gray100,
                    child: const Center(
                      child: Icon(
                        LucideIcons.image,
                        size: 48,
                        color: AppColors.gray400,
                      ),
                    ),
                  ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentBg,
                    borderRadius: AppRadius.pillRadius,
                  ),
                  child: Text(
                    catLabel.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      LucideIcons.calendar,
                      size: 14,
                      color: AppColors.gray500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateStr,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      LucideIcons.mapPin,
                      size: 14,
                      color: AppColors.gray500,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.gray500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _publishButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        8,
        AppSpacing.lg,
        20,
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _isPublishing ? null : _publishEvent,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.black, Color(0xFF1A1A1A)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: AppRadius.pillRadius,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isPublishing)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: AppColors.white,
                        strokeWidth: 2,
                      ),
                    )
                  else ...[
                    const Icon(LucideIcons.zap, color: AppColors.white, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Publish Event',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _isPublishing ? null : _saveAsDraft,
            child: Container(
              height: 44,
              alignment: Alignment.center,
              child: Text(
                'Save as draft',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gray400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Map grid painter ─────────────────────────────────────────────────────────

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD1D5DB)
      ..strokeWidth = 1;

    // Horizontal streets
    for (double y = 20; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Vertical streets
    for (double x = 30; x < size.width; x += 44) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
