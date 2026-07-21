import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class MobileDataService {
  static const String defaultRepo =
      'https://raw.githubusercontent.com/m9cherif/flutter_quran_data/main';

  String repoBase;

  MobileDataService({String? repoUrl}) : repoBase = repoUrl ?? defaultRepo;

  String _padded(String page) => page.padLeft(3, '0');

  Future<String> get _cacheDir async {
    final dir = await getApplicationDocumentsDirectory();
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
}
