enum AnnotationType { hLine, vLine, word }

class Annotation {
  final int id;
  final AnnotationType type;
  bool hidden;

  Annotation({required this.id, required this.type, this.hidden = false});
}

class HLine extends Annotation {
  double y;

  HLine({required super.id, required this.y}) : super(type: AnnotationType.hLine);

  Map<String, dynamic> toMap() => {'y': y};
}

class VLine extends Annotation {
  double x, top, bottom;

  VLine({required super.id, required this.x, required this.top, required this.bottom})
      : super(type: AnnotationType.vLine);

  Map<String, dynamic> toMap() => {'x': x, 'top': top, 'bottom': bottom};
}

class Word extends Annotation {
  double x1, y1, x2, y2;

  Word({
    required super.id,
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
  }) : super(type: AnnotationType.word);

  double get width => x2 - x1;
  double get height => y2 - y1;

  Map<String, dynamic> toMap() => {
        'x1': x1,
        'y1': y1,
        'x2': x2,
        'y2': y2,
        'hidden': hidden,
        'id': id,
      };
}

class UndoAction {
  final String type;
  final Map<String, dynamic> data;

  UndoAction({required this.type, required this.data});
}
