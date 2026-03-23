
class AdModel {
  final String id;
  final String title;
  final String imageUrl;
  final String? link;
  final bool isSponsored;

  AdModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.link,
    this.isSponsored = false,
  });

  factory AdModel.fromMap(Map<String, dynamic> map, String documentId) {
    return AdModel(
      id: documentId,
      title: map['title'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      link: map['link'],
      isSponsored: map['isSponsored'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'imageUrl': imageUrl,
      'link': link,
      'isSponsored': isSponsored,
    };
  }
}
