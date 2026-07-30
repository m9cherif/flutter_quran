import 'package:flutter/material.dart';
import '../models/surah.dart';
import '../models/hizb_quarter.dart';
import '../mobile/mobile_data_service.dart';

class StartupScreen extends StatefulWidget {
  final MobileDataService dataService;
  final void Function(String page) onNavigate;

  const StartupScreen({
    super.key,
    required this.dataService,
    required this.onNavigate,
  });

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen>
    with SingleTickerProviderStateMixin {
  List<Surah>? _surahs;
  List<HizbQuarter>? _hizbQuarters;
  bool _loading = true;
  int _tab = 0;

  final _searchCtrl = TextEditingController();
  String _query = '';

  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() {
      if (_searchCtrl.text.isEmpty) setState(() => _tab = _tabCtrl.index);
    });
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      widget.dataService.getSurahIndex(),
      widget.dataService.getHizbQuarters(),
    ]);
    if (mounted) setState(() {
      _surahs = results[0] as List<Surah>;
      _hizbQuarters = results[1] as List<HizbQuarter>;
      _loading = false;
    });
  }

  void _onSearch(String q) => setState(() => _query = q.trim());

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  Color _surface(ThemeData t) => t.brightness == Brightness.dark
      ? const Color(0xFF1A1A1A)
      : Colors.white;

  Color _surfaceDim(ThemeData t) => t.brightness == Brightness.dark
      ? const Color(0xFF2A2A2A)
      : const Color(0xFFF0EDE6);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final c = t.colorScheme;

    if (_loading) {
      return Center(child: CircularProgressIndicator(color: c.primary));
    }
    if (_surahs == null || _surahs!.isEmpty) {
      return _buildError(c);
    }
    return Column(
      children: [
        _buildSearchBar(t, c),
        if (_query.isEmpty)
          _buildTabs(t, c)
        else
          Expanded(child: _buildSearchResults(t, c)),
      ],
    );
  }

  Widget _buildError(ColorScheme c) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 60, color: c.onSurface.withAlpha(97)),
          const SizedBox(height: 12),
          Text('فشل تحميل الفهرس',
              style: TextStyle(color: c.onSurface.withAlpha(138), fontSize: 16)),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _load,
            icon: Icon(Icons.refresh, color: c.primary),
            label: Text('إعادة المحاولة', style: TextStyle(color: c.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData t, ColorScheme c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        controller: _searchCtrl,
        onChanged: _onSearch,
        style: TextStyle(color: c.onSurface, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'بحث: سورة، حزب، صفحة، رقم الآية...',
          hintStyle: TextStyle(color: c.onSurface.withAlpha(97)),
          prefixIcon: Icon(Icons.search, color: c.onSurface.withAlpha(97), size: 20),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: c.onSurface.withAlpha(97), size: 18),
                  onPressed: () { _searchCtrl.clear(); _onSearch(''); },
                )
              : null,
          filled: true,
          fillColor: _surfaceDim(t),
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildTabs(ThemeData t, ColorScheme c) {
    return Expanded(
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: _surfaceDim(t),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TabBar(
              controller: _tabCtrl,
              indicator: BoxDecoration(
                color: c.primary.withAlpha(60),
                borderRadius: BorderRadius.circular(8),
              ),
              labelColor: c.primary,
              unselectedLabelColor: c.onSurface.withAlpha(138),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: [
                Tab(text: 'السور (${_surahs!.length})'),
                Tab(text: 'الأحزاب (${_hizbQuarters!.length})'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildSurahList(t, c),
                _buildHizbList(t, c),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurahList(ThemeData t, ColorScheme c) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemCount: _surahs!.length,
      itemBuilder: (context, i) {
        final s = _surahs![i];
        return Card(
          color: _surface(t),
          margin: const EdgeInsets.symmetric(vertical: 3),
          child: ListTile(
            dense: true,
            onTap: () => widget.onNavigate('${s.numPage}'),
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: c.primary.withAlpha(50),
              child: Text('${s.numSoura}',
                  style: TextStyle(color: c.primary, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            title: Text(s.soura,
                style: TextStyle(color: c.onSurface, fontSize: 16, fontWeight: FontWeight.w500)),
            subtitle: Text('صفحة ${s.numPage}  •  ${s.nbrAya} آية',
                style: TextStyle(color: c.onSurface.withAlpha(138), fontSize: 12)),
            trailing: Icon(Icons.chevron_left, color: c.onSurface.withAlpha(61), size: 20),
          ),
        );
      },
    );
  }

  Widget _buildHizbList(ThemeData t, ColorScheme c) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemCount: _hizbQuarters!.length,
      itemBuilder: (context, i) {
        final h = _hizbQuarters![i];
        return Card(
          color: _surface(t),
          margin: const EdgeInsets.symmetric(vertical: 3),
          child: ListTile(
            dense: true,
            onTap: () => widget.onNavigate('${h.page}'),
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: c.primary.withAlpha(50),
              child: Text('${h.rub}',
                  style: TextStyle(color: c.primary, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            title: Text('الحزب ${h.hizb} - الربع ${h.quarter}',
                style: TextStyle(color: c.onSurface, fontSize: 15)),
            subtitle: Text('صفحة ${h.page}',
                style: TextStyle(color: c.onSurface.withAlpha(138), fontSize: 12)),
            trailing: Icon(Icons.chevron_left, color: c.onSurface.withAlpha(61), size: 20),
          ),
        );
      },
    );
  }

  Widget _buildSearchResults(ThemeData t, ColorScheme c) {
    final q = _query;
    final ql = q.toLowerCase();

    final surahMatches = <Surah>[];
    final hizbMatches = <HizbQuarter>[];
    final pageMatches = <int>[];
    String? ayahRefSurah;
    int? ayahRefAya;

    if (int.tryParse(q) != null) {
      final num = int.parse(q);
      if (num >= 1 && num <= 604) pageMatches.add(num);
    }

    final colonIdx = q.indexOf(':');
    if (colonIdx > 0 && colonIdx < q.length - 1) {
      final surahStr = q.substring(0, colonIdx);
      final ayaStr = q.substring(colonIdx + 1);
      final sn = int.tryParse(surahStr);
      final an = int.tryParse(ayaStr);
      if (sn != null && an != null) {
        ayahRefSurah = sn;
        ayahRefAya = an;
      }
    }

    for (final s in _surahs!) {
      if (s.soura.contains(q) || s.soura.toLowerCase().contains(ql) ||
          '$s.numSoura' == q || '$s.numPage'.contains(q)) {
        surahMatches.add(s);
      }
    }

    for (final h in _hizbQuarters!) {
      if ('${h.hizb}' == q || '${h.rub}' == q || '${h.page}'.contains(q)) {
        hizbMatches.add(h);
      }
    }

    final hasAny = surahMatches.isNotEmpty || hizbMatches.isNotEmpty ||
        pageMatches.isNotEmpty || ayahRefSurah != null;

    final sectionStyle = TextStyle(color: c.primary, fontSize: 13, fontWeight: FontWeight.bold);
    final cardColor = _surface(t);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      children: [
        if (surahMatches.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4, right: 4),
            child: Text('السور', style: sectionStyle),
          ),
          ...surahMatches.map((s) => _searchResultCard(cardColor, c, s.numPage,
            leading: Text('${s.numSoura}', style: TextStyle(color: c.primary, fontSize: 11, fontWeight: FontWeight.bold)),
            title: Text(s.soura, style: TextStyle(color: c.onSurface, fontSize: 15)),
            subtitle: Text('صفحة ${s.numPage}', style: TextStyle(color: c.onSurface.withAlpha(138), fontSize: 11)),
          )),
        ],
        if (hizbMatches.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4, right: 4),
            child: Text('الأحزاب', style: sectionStyle),
          ),
          ...hizbMatches.map((h) => _searchResultCard(cardColor, c, h.page,
            leading: Text('${h.rub}', style: TextStyle(color: c.primary, fontSize: 11, fontWeight: FontWeight.bold)),
            title: Text('الحزب ${h.hizb} - الربع ${h.quarter}', style: TextStyle(color: c.onSurface, fontSize: 15)),
            subtitle: Text('صفحة ${h.page}', style: TextStyle(color: c.onSurface.withAlpha(138), fontSize: 11)),
          )),
        ],
        if (ayahRefSurah != null) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4, right: 4),
            child: Text('الآيات', style: sectionStyle),
          ),
          _searchResultCard(cardColor, c, _findSurahPage(ayahRefSurah),
            leading: Text('$ayahRefSurah', style: TextStyle(color: c.primary, fontSize: 11, fontWeight: FontWeight.bold)),
            title: Text('سورة $ayahRefSurah - الآية $ayahRefAya', style: TextStyle(color: c.onSurface, fontSize: 15)),
            subtitle: Text('صفحة ${_findSurahPage(ayahRefSurah)}', style: TextStyle(color: c.onSurface.withAlpha(138), fontSize: 11)),
          ),
        ],
        if (pageMatches.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4, right: 4),
            child: Text('الصفحات', style: sectionStyle),
          ),
          ...pageMatches.map((p) => _searchResultCard(cardColor, c, p,
            leading: Icon(Icons.auto_stories, color: c.primary, size: 14),
            title: Text('صفحة $p', style: TextStyle(color: c.onSurface, fontSize: 15)),
          )),
        ],
        if (!hasAny)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Center(
              child: Text('لا توجد نتائج', style: TextStyle(color: c.onSurface.withAlpha(61), fontSize: 14)),
            ),
          ),
      ],
    );
  }

  Widget _searchResultCard(Color cardColor, ColorScheme c, int page, {
    required Widget leading,
    required Widget title,
    Widget? subtitle,
  }) {
    return Card(
      color: cardColor,
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        dense: true,
        onTap: () => widget.onNavigate('$page'),
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: c.primary.withAlpha(50),
          child: leading,
        ),
        title: title,
        subtitle: subtitle,
        trailing: Icon(Icons.chevron_left, color: c.onSurface.withAlpha(61), size: 18),
      ),
    );
  }

  int _findSurahPage(int surahNum) {
    final surah = _surahs!.where((s) => s.numSoura == surahNum);
    return surah.isNotEmpty ? surah.first.numPage : 1;
  }
}
