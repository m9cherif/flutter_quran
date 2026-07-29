import 'package:flutter/material.dart';
import '../models/surah.dart';
import '../mobile/mobile_data_service.dart';

class SurahListScreen extends StatefulWidget {
  final MobileDataService dataService;
  final void Function(String page) onNavigate;

  const SurahListScreen({
    super.key,
    required this.dataService,
    required this.onNavigate,
  });

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  List<Surah>? _surahs;
  List<Surah> _filtered = [];
  final _searchCtrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await widget.dataService.getSurahIndex();
    if (mounted) setState(() {
      _surahs = list;
      _filtered = list;
      _loading = false;
    });
  }

  void _filter(String q) {
    if (_surahs == null) return;
    if (q.isEmpty) {
      setState(() => _filtered = _surahs!);
      return;
    }
    final lq = q.toLowerCase();
    setState(() {
      _filtered = _surahs!.where((s) =>
        s.soura.toLowerCase().contains(lq) ||
        s.numSoura.toString().contains(q)
      ).toList();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFD4A843)));
    }
    if (_surahs == null || _surahs!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.white24),
            const SizedBox(height: 12),
            Text('فشل تحميل فهرس السور', style: TextStyle(color: Colors.white38, fontSize: 16)),
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: TextField(
            controller: _searchCtrl,
            onChanged: _filter,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'بحث...',
              hintStyle: const TextStyle(color: Colors.white24),
              prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white38, size: 18),
                      onPressed: () { _searchCtrl.clear(); _filter(''); },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white10,
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            itemCount: _filtered.length,
            itemBuilder: (context, i) {
              final s = _filtered[i];
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
                  subtitle: Text('الصفحة ${s.numPage}  •  ${s.nbrAya} آية', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  trailing: const Icon(Icons.chevron_left, color: Colors.white24, size: 20),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
