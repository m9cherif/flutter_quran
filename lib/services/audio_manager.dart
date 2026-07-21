import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/annotation_provider.dart';

class AudioManager {
  final AnnotationProvider provider;
  final AudioPlayer _player = AudioPlayer();

  String? currentAudioFile;
  bool audioLoaded = false;
  bool recording = false;
  bool _sliderSeeking = false;
  String currentSurahNumber = '';

  int recordingStartTime = 0;
  int recordingStartAudioPos = 0;
  int recordingDuration = 0;

  final List<Map<String, dynamic>> timeline = [];
  String timelineName = '';

  List<Map<String, dynamic>> playbackEvents = [];
  int playbackIndex = 0;
  int playbackStartTime = 0;
  bool playbackPaused = false;
  int playbackPausedElapsed = 0;
  bool playbackFinished = false;
  bool _playPendingStart = false;

  ValueNotifier<int> positionNotifier = ValueNotifier(0);
  ValueNotifier<int> durationNotifier = ValueNotifier(0);
  ValueNotifier<String> statusNotifier = ValueNotifier('لا يوجد صوت');
  ValueNotifier<bool> isPlayingNotifier = ValueNotifier(false);
  ValueNotifier<bool> isRecordingNotifier = ValueNotifier(false);
  ValueNotifier<int> timelineEventCount = ValueNotifier(0);

  AudioManager(this.provider) {
    _player.onPositionChanged.listen((pos) {
      if (!_sliderSeeking) {
        positionNotifier.value = pos.inMilliseconds;
      }
    });
    _player.onDurationChanged.listen((dur) {
      durationNotifier.value = dur.inMilliseconds;
    });
    _player.onPlayerStateChanged.listen((state) {
      isPlayingNotifier.value = state == PlayerState.playing;
      if (state == PlayerState.completed) {
        statusNotifier.value = 'الصوت انتهى';
      }
    });
  }

  void dispose() {
    _player.dispose();
    positionNotifier.dispose();
    durationNotifier.dispose();
    statusNotifier.dispose();
    isPlayingNotifier.dispose();
    isRecordingNotifier.dispose();
    timelineEventCount.dispose();
  }

  Future<void> cleanup() async {
    await stopAudio();
    stopPlayback();
    recording = false;
  }

  String _formatTime(int ms) {
    if (ms <= 0) return '0:00';
    final s = ms ~/ 1000;
    final m = s ~/ 60;
    final sec = s % 60;
    return '$m:${sec.toString().padLeft(2, '0')}';
  }

  String get timeDisplay {
    final pos = _formatTime(positionNotifier.value);
    final dur = _formatTime(durationNotifier.value);
    return '$pos / $dur';
  }

  Future<void> loadAudioBySurah(String surahNumber) async {
    await stopAudio();
    stopPlayback();
    recording = false;
    final padded = surahNumber.padLeft(3, '0');
    final path = 'G:\\trabelsi\\$padded.mp3';
    final file = File(path);
    if (!await file.exists()) {
      statusNotifier.value = 'لا يوجد صوت للسورة $surahNumber';
      currentAudioFile = null;
      audioLoaded = false;
      return;
    }
    currentSurahNumber = surahNumber;
    currentAudioFile = path;
    audioLoaded = false;
    statusNotifier.value = 'جاري التحميل...';
    try {
      await _player.setSource(DeviceFileSource(path));
      audioLoaded = true;
      statusNotifier.value = 'تم تحميل صوت السورة $surahNumber';
    } catch (e) {
      statusNotifier.value = 'خطأ: $e';
    }
  }

  Future<void> loadAudioBySurahFromUrl(String url, String surahNumber) async {
    await stopAudio();
    stopPlayback();
    recording = false;
    currentSurahNumber = surahNumber;
    currentAudioFile = url;
    audioLoaded = false;
    statusNotifier.value = 'جاري التحميل...';
    try {
      await _player.setSource(UrlSource(url));
      audioLoaded = true;
      statusNotifier.value = 'تم تحميل صوت السورة $surahNumber';
    } catch (e) {
      statusNotifier.value = 'خطأ: $e';
    }
  }

  Future<void> loadAudioFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'ogg', 'flac', 'm4a'],
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;

    currentAudioFile = path;
    audioLoaded = false;
    statusNotifier.value = 'جاري التحميل...';
    try {
      await _player.setSource(DeviceFileSource(path));
      audioLoaded = true;
      statusNotifier.value = 'تم تحميل الصوت';
    } catch (e) {
      statusNotifier.value = 'خطأ: $e';
    }
  }

  Future<void> toggleAudioPlay() async {
    if (currentAudioFile == null) {
      await loadAudioFile();
      return;
    }
    if (isPlayingNotifier.value) {
      await _player.pause();
      statusNotifier.value = 'متوقف مؤقتاً';
    } else {
      if (!audioLoaded && currentAudioFile != null) {
        if (currentAudioFile!.startsWith('http://') || currentAudioFile!.startsWith('https://')) {
          await _player.setSource(UrlSource(currentAudioFile!));
        } else {
          await _player.setSource(DeviceFileSource(currentAudioFile!));
        }
        audioLoaded = true;
      }
      await _player.resume();
      statusNotifier.value = 'جاري التشغيل...';
    }
  }

  Future<void> stopAudio() async {
    await _player.stop();
    statusNotifier.value = 'متوقف';
  }

  void seekAudio(int positionMs) {
    _player.seek(Duration(milliseconds: positionMs));
  }

  void onSliderPressed() => _sliderSeeking = true;

  void onSliderReleased(int value) {
    _sliderSeeking = false;
    _player.seek(Duration(milliseconds: value));
    _syncWordsToPosition(value);
  }

  void _syncWordsToPosition(int positionMs) {
    if (playbackEvents.isEmpty) return;
    int idx = 0;
    for (var i = 0; i < playbackEvents.length; i++) {
      final e = playbackEvents[i];
      if ((e['time'] as int) <= positionMs) {
        idx = i;
      } else {
        break;
      }
    }
    playbackStartTime = DateTime.now().millisecondsSinceEpoch - positionMs;
    playbackIndex = idx + 1 < playbackEvents.length ? idx + 1 : playbackEvents.length;
  }

  Future<void> startRecording() async {
    if (recording) return;

    if (currentAudioFile == null) {
      statusNotifier.value = 'انقر "بدون صوت" أو حمل ملفاً صوتياً';
      return;
    }

    if (!audioLoaded && currentAudioFile != null) {
      if (currentAudioFile!.startsWith('http://') || currentAudioFile!.startsWith('https://')) {
        await _player.setSource(UrlSource(currentAudioFile!));
      } else {
        await _player.setSource(DeviceFileSource(currentAudioFile!));
      }
      audioLoaded = true;
    }

    timeline.clear();
    recording = true;
    recordingStartTime = DateTime.now().millisecondsSinceEpoch;
    recordingStartAudioPos = 0;
    timelineName = 'page${provider.currentPageNumber}';
    isRecordingNotifier.value = true;
    statusNotifier.value = 'جاري التسجيل...';
    await _player.resume();
    isPlayingNotifier.value = true;
  }

  void startRecordingNoAudio() {
    timeline.clear();
    recording = true;
    recordingStartTime = DateTime.now().millisecondsSinceEpoch;
    recordingStartAudioPos = 0;
    timelineName = 'page${provider.currentPageNumber}';
    isRecordingNotifier.value = true;
    statusNotifier.value = 'جاري التسجيل (بدون صوت)...';
  }

  void stopRecording() {
    if (!recording) return;
    recording = false;
    recordingDuration = DateTime.now().millisecondsSinceEpoch - recordingStartTime;
    _player.pause();
    isRecordingNotifier.value = false;
    timelineEventCount.value = timeline.length;
    statusNotifier.value = 'تم التسجيل – ${timeline.length} حدث';
  }

  void recordEvent(int wordId, String action) {
    if (!recording) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsed = now - recordingStartTime;
    timeline.add({'time': elapsed, 'word_id': wordId, 'action': action});
    timelineEventCount.value = timeline.length;
  }

  Future<void> saveTimeline() async {
    if (timeline.isEmpty) return;
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'حفظ الخط الزمني',
      fileName: '$timelineName.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null) return;
    try {
      final data = {
        'name': timelineName,
        'audio_file': currentAudioFile,
        'audio_start_pos': recordingStartAudioPos,
        'recording_duration': recordingDuration,
        'events': timeline,
      };
      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
      await File(result).writeAsString(jsonStr);
      statusNotifier.value = 'تم حفظ الخط الزمني';
    } catch (e) {
      statusNotifier.value = 'خطأ في الحفظ: $e';
    }
  }

  Future<void> loadTimeline() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;

    try {
      final jsonStr = await File(path).readAsString();
      final data = json.decode(jsonStr) as Map<String, dynamic>;

      if (!data.containsKey('events')) {
        statusNotifier.value = 'تنسيق ملف غير صالح';
        return;
      }

      final events = (data['events'] as List).cast<Map<String, dynamic>>();
      timeline.clear();
      timeline.addAll(events);
      timelineName = data['name'] as String? ?? '';
      recordingStartAudioPos = data['audio_start_pos'] as int? ?? 0;
      recordingDuration = data['recording_duration'] as int? ?? 0;
      if (data['audio_file'] != null) {
        currentAudioFile = data['audio_file'] as String;
      }
      timelineEventCount.value = timeline.length;
      statusNotifier.value = 'تم تحميل الخط الزمني: ${timeline.length} حدث';
    } catch (e) {
      statusNotifier.value = 'خطأ في التحميل: $e';
    }
  }

  Future<void> togglePlayPause() async {
    if (playbackPaused) {
      resumePlayback();
      return;
    }
    if (playbackEvents.isNotEmpty && playbackIndex < playbackEvents.length) {
      pausePlayback();
      return;
    }
    await playTimeline();
  }

  Future<void> playTimeline() async {
    playbackFinished = false;
    if (timeline.isEmpty) {
      statusNotifier.value = 'لا يوجد خط زمني للتشغيل';
      return;
    }

    final wordIds = provider.words.map((w) => w.id).toSet();
    for (var e in timeline) {
      if (!wordIds.contains(e['word_id'])) {
        statusNotifier.value = 'الكلمة ID ${e['word_id']} غير موجودة';
        return;
      }
    }

    if (currentAudioFile != null && !audioLoaded) {
      if (currentAudioFile!.startsWith('http://') || currentAudioFile!.startsWith('https://')) {
        await _player.setSource(UrlSource(currentAudioFile!));
      } else {
        await _player.setSource(DeviceFileSource(currentAudioFile!));
      }
      _playPendingStart = true;
    } else if (currentAudioFile != null) {
      await _player.seek(Duration(milliseconds: recordingStartAudioPos));
      await _player.resume();
      _playPendingStart = false;
    }

    playbackPaused = false;
    playbackEvents = List.from(timeline)..sort((a, b) => (a['time'] as int).compareTo(b['time'] as int));
    playbackIndex = 0;
    statusNotifier.value = 'جاري التشغيل – $timelineName';

    if (!_playPendingStart) {
      playbackStartTime = DateTime.now().millisecondsSinceEpoch;
      _scheduleNextEvent();
    }
  }

  void _scheduleNextEvent() {
    if (playbackIndex >= playbackEvents.length) {
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsed = now - playbackStartTime;
    final nextEvent = playbackEvents[playbackIndex];
    var delay = (nextEvent['time'] as int) - elapsed;
    if (delay < 0) delay = 0;

    Future.delayed(Duration(milliseconds: delay), _executeNextEvent);
  }

  void _executeNextEvent() {
    if (playbackIndex >= playbackEvents.length) return;

    final evt = playbackEvents[playbackIndex];
    final word = provider.words.where((w) => w.id == evt['word_id']).firstOrNull;

    if (word != null) {
      if (evt['action'] == 'show') {
        provider.selectAnnotation(word);
      }
    }

    playbackIndex++;
    _scheduleNextEvent();
  }

  void pausePlayback() {
    playbackPausedElapsed = DateTime.now().millisecondsSinceEpoch - playbackStartTime;
    playbackPaused = true;
    _player.pause();
    statusNotifier.value = 'التشغيل متوقف مؤقتاً';
  }

  void resumePlayback() {
    playbackStartTime = DateTime.now().millisecondsSinceEpoch - playbackPausedElapsed;
    playbackPaused = false;
    _player.resume();
    _scheduleNextEvent();
    statusNotifier.value = 'تم استئناف التشغيل';
  }

  void stopPlayback() {
    _playPendingStart = false;
    playbackFinished = false;
    _player.stop();
    playbackIndex = 0;
    playbackEvents = [];
    playbackPaused = false;
    statusNotifier.value = 'تم إيقاف التشغيل';
  }
}
