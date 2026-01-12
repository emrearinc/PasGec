class Category {
  final int? id;
  final String name;
  int wordCount;
  bool isSelected;

  Category({
    this.id,
    required this.name,
    this.wordCount = 0,
    this.isSelected = false,
  });

  // JSON'dan Category oluştur
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      wordCount: map['word_count'] ?? 0,
      isSelected: false,
    );
  }

  // Category'yi JSON'a dönüştür
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'word_count': wordCount,
    };
  }

  @override
  String toString() => 'Category(id: $id, name: $name, wordCount: $wordCount)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
