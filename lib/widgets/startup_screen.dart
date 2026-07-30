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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFD4A843)));
    }
    if (_surahs == null || _surahs!.isEmpty) {
      return _buildError();
    }
    return Column(
      children: [
        _buildSearchBar(),
        if (_query.isEmpty)
          _buildTabs()
        else
          Expanded(child: _buildSearchResults()),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.white24),
          const SizedBox(height: 12),
          const Text('فشل تحميل الفهرس', style: TextStyle(color: Colors.white38, fontSize: 16)),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh, color: Color(0xFFD4A843)),
            label: const Text('إعادة المحاولة', style: TextStyle(color: Color(0xFFD4A843))),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        controller: _searchCtrl,
        onChanged: _onSearch,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'بحث: سورة، حزب، صفحة، رقم الآية...',
          hintStyle: const TextStyle(color: Colors.white24),
          prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white38, size: 18),
                  onPressed: () { _searchCtrl.clear(); _onSearch(''); },
                )
              : null,
          filled: true,
          fillColor: Colors.white10,
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Expanded(
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TabBar(
              controller: _tabCtrl,
              indicator: BoxDecoration(
                color: const Color(0xFFD4A843).withAlpha(60),
                borderRadius: BorderRadius.circular(8),
              ),
              labelColor: const Color(0xFFD4A843),
              unselectedLabelColor: Colors.white38,
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
                _buildSurahList(),
                _buildHizbList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurahList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemCount: _surahs!.length,
      itemBuilder: (context, i) {
        final s = _surahs![i];
        return Card(
          color: Colors.white10,
          margin: const EdgeInsets.symmetric(vertical: 3),
          child: ListTile(
            dense: true,
            onTap: () => widget.onNavigate('${s.numPage}'),
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFD4A843).withAlpha(50),
              child: Text('${s.numSoura}', style: const TextStyle(color: Color(0xFFD4A843), fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            title: Text(s.soura, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
            subtitle: Text('صفحة ${s.numPage}  •  ${s.nbrAya} آية', style: const TextStyle(color: Colors.white38, fontSize: 12)),
            trailing: const Icon(Icons.chevron_left, color: Colors.white24, size: 20),
          ),
        );
      },
    );
  }

  Widget _buildHizbList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemCount: _hizbQuarters!.length,
      itemBuilder: (context, i) {
        final h = _hizbQuarters![i];
        return Card(
          color: Colors.white10,
          margin: const EdgeInsets.symmetric(vertical: 3),
          child: ListTile(
            dense: true,
            onTap: () => widget.onNavigate('${h.page}'),
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFD4A843).withAlpha(50),
              child: Text('${h.rub}', style: const TextStyle(color: Color(0xFFD4A843), fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            title: Text('الحزب ${h.hizb} - الربع ${h.quarter}', style: const TextStyle(color: Colors.white, fontSize: 15)),
            subtitle: Text('صفحة ${h.page}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
            trailing: const Icon(Icons.chevron_left, color: Colors.white24, size: 20),
          ),
        );
      },
    );
  }

  Widget _buildSearchResults() {
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

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      children: [
        if (surahMatches.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4, right: 4),
            child: Text('السور', style: TextStyle(color: Color(0xFFD4A843), fontSize: 13, fontWeight: FontWeight.bold)),
          ),
          ...surahMatches.map((s) => Card(
            color: Colors.white10,
            margin: const EdgeInsets.symmetric(vertical: 2),
            child: ListTile(
              dense: true,
              onTap: () => widget.onNavigate('${s.numPage}'),
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFD4A843).withAlpha(50),
                child: Text('${s.numSoura}', style: const TextStyle(color: Color(0xFFD4A843), fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              title: Text(s.soura, style: const TextStyle(color: Colors.white, fontSize: 15)),
              subtitle: Text('صفحة ${s.numPage}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
              trailing: const Icon(Icons.chevron_left, color: Colors.white24, size: 18),
            ),
          )),
        ],
        if (hizbMatches.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4, right: 4),
            child: Text('الأحزاب', style: TextStyle(color: Color(0xFFD4A843), fontSize: 13, fontWeight: FontWeight.bold)),
          ),
          ...hizbMatches.map((h) => Card(
            color: Colors.white10,
            margin: const EdgeInsets.symmetric(vertical: 2),
            child: ListTile(
              dense: true,
              onTap: () => widget.onNavigate('${h.page}'),
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFD4A843).withAlpha(50),
                child: Text('${h.rub}', style: const TextStyle(color: Color(0xFFD4A843), fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              title: Text('الحزب ${h.hizb} - الربع ${h.quarter}', style: const TextStyle(color: Colors.white, fontSize: 15)),
              subtitle: Text('صفحة ${h.page}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
              trailing: const Icon(Icons.chevron_left, color: Colors.white24, size: 18),
            ),
          )),
        ],
        if (ayahRefSurah != null) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4, right: 4),
            child: Text('الآيات', style: TextStyle(color: Color(0xFFD4A843), fontSize: 13, fontWeight: FontWeight.bold)),
          ),
          Card(
            color: Colors.white10,
            margin: const EdgeInsets.symmetric(vertical: 2),
            child: ListTile(
              dense: true,
              onTap: () => widget.onNavigate('${_findSurahPage(ayahRefSurah)}'),
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFD4A843).withAlpha(50),
                child: Text('$ayahRefSurah', style: const TextStyle(color: Color(0xFFD4A843), fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              title: Text('سورة ${ayahRefSurah} - الآية ${ayahRefAya}', style: const TextStyle(color: Colors.white, fontSize: 15)),
              subtitle: Text('صفحة ${_findSurahPage(ayahRefSurah)}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
              trailing: const Icon(Icons.chevron_left, color: Colors.white24, size: 18),
            ),
          ),
        ],
        if (pageMatches.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4, right: 4),
            child: Text('الصفحات', style: TextStyle(color: Color(0xFFD4A843), fontSize: 13, fontWeight: FontWeight.bold)),
          ),
          ...pageMatches.map((p) => Card(
            color: Colors.white10,
            margin: const EdgeInsets.symmetric(vertical: 2),
            child: ListTile(
              dense: true,
              onTap: () => widget.onNavigate('$p'),
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFD4A843).withAlpha(50),
                child: const Icon(Icons.auto_stories, color: Color(0xFFD4A843), size: 14),
              ),
              title: Text('صفحة $p', style: const TextStyle(color: Colors.white, fontSize: 15)),
              trailing: const Icon(Icons.chevron_left, color: Colors.white24, size: 18),
            ),
          )),
        ],
        if (!hasAny)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Center(
              child: Text('لا توجد نتائج', style: TextStyle(color: Colors.white24, fontSize: 14)),
            ),
          ),
      ],
    );
  }

  int _findSurahPage(int surahNum) {
    final surah = _surahs!.where((s) => s.numSoura == surahNum);
    return surah.isNotEmpty ? surah.first.numPage : 1;
  }
}
