import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/surah.dart';
import '../models/hizb_quarter.dart';

class MobileDataService {
  static const String defaultRepo =
      'https://raw.githubusercontent.com/m9cherif/flutter_quran_data/main';

  String repoBase;

  MobileDataService({String? repoUrl}) : repoBase = repoUrl ?? defaultRepo;

  String _padded(String page) => page.padLeft(3, '0');

  Future<String> get _cacheDir async {
    final dir = await getTemporaryDirectory();
    final cache = Directory('${dir.path}/quran_cache');
    if (!await cache.exists()) await cache.create(recursive: true);
    return cache.path;
  }

  Future<Uint8List> getImageBytes(String pageNumber) async {
    final name = 'page${_padded(pageNumber)}.png';
    final local = '${await _cacheDir}/png/$name';
    final file = File(local);
    if (await file.exists()) return file.readAsBytes();
    final bytes = await _fetchBytes('$repoBase/png/$name');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
    return bytes;
  }

  Future<Uint8List> getAnnotationBytes(String pageNumber) async {
    final name = 'a${_padded(pageNumber)}.xlsx';
    final local = '${await _cacheDir}/annotation/$name';
    final file = File(local);
    if (await file.exists()) return file.readAsBytes();
    final bytes = await _fetchBytes('$repoBase/annotation/$name');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
    return bytes;
  }

  String getAudioUrl(String surahNumber) {
    return '$repoBase/audio/${surahNumber.padLeft(3, '0')}.mp3';
  }

  String? getTimelineUrl(String pageNumber) {
    return '$repoBase/timeline/page${_padded(pageNumber)}.json';
  }

  String getSurahAudioUrl(String surahNumber) {
    return 'https://cdn.jsdelivr.net/gh/m9cherif/flutter_quran_data@main/audio/${surahNumber.padLeft(3, '0')}.mp3';
  }

  String getSurahAudioUrlForCache(String surahNumber) {
    return '$repoBase/audio/${surahNumber.padLeft(3, '0')}.mp3';
  }

  Future<Map<String, dynamic>?> getTimelineData(String pageNumber) async {
    final name = 'page${_padded(pageNumber)}.json';
    final local = '${await _cacheDir}/timeline/$name';
    final file = File(local);
    try {
      final response = await http.get(Uri.parse('$repoBase/timeline/$name'));
      if (response.statusCode == 200) {
        await file.parent.create(recursive: true);
        await file.writeAsString(response.body);
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    if (await file.exists()) {
      return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    }
    return null;
  }

  Future<String?> getCachedAudioPath(String surahNumber) async {
    final name = '${surahNumber.padLeft(3, '0')}.mp3';
    final local = '${await _cacheDir}/audio/$name';
    final file = File(local);
    if (await file.exists()) return local;
    try {
      final url = '$repoBase/audio/$name';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return null;
      await file.parent.create(recursive: true);
      await file.writeAsBytes(response.bodyBytes);
      return local;
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List> _fetchBytes(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('فشل التحميل من $url (${response.statusCode})');
    }
    return response.bodyBytes;
  }

  Future<bool> checkConnection() async {
    try {
      final response = await http
          .get(Uri.parse('$repoBase/png/page001.png'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> saveHiddenStates(String pageNumber, Map<int, bool> hiddenStates) async {
    final dir = '${await _cacheDir}/hidden';
    final file = File('$dir/page${_padded(pageNumber)}.json');
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(hiddenStates));
  }

  Future<Map<int, bool>> loadHiddenStates(String pageNumber) async {
    final file = File('${await _cacheDir}/hidden/page${_padded(pageNumber)}.json');
    if (!await file.exists()) return {};
    final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    return data.map((k, v) => MapEntry(int.parse(k), v as bool));
  }

  Future<void> clearHiddenStates(String pageNumber) async {
    final file = File('${await _cacheDir}/hidden/page${_padded(pageNumber)}.json');
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<List<Surah>> getSurahIndex() async {
    final list = await _fetchJsonList('surah_index.json');
    return list.map((e) => Surah.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<HizbQuarter>> getHizbQuarters() async {
    final list = await _fetchJsonList('hizb_quarters.json');
    return list.map((e) => HizbQuarter.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<dynamic>> _fetchJsonList(String filename) async {
    final local = '${await _cacheDir}/$filename';
    final file = File(local);

    try {
      final response = await http.get(Uri.parse('$repoBase/$filename'));
      if (response.statusCode == 200) {
        await file.parent.create(recursive: true);
        await file.writeAsString(response.body);
        return jsonDecode(response.body) as List<dynamic>;
      }
    } catch (_) {}

    if (await file.exists()) {
      return jsonDecode(await file.readAsString()) as List<dynamic>;
    }
    return [];
  }

  Future<List<List<dynamic>>> getWordIndex() async {
    final list = await _fetchJsonList('word_index.json');
    return list.cast<List<dynamic>>();
  }
}
