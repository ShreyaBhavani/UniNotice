class Notice {
  final int id;
  final String title;
  final String body;
  final String? url;

  Notice({
    required this.id,
    required this.title,
    required this.body,
    this.url,
  });

  /// Map a generic article/notice JSON into our model.
  ///
  /// Designed for APIs that return English news/articles, such as
  /// the Spaceflight News API (id, title, summary, url).
  factory Notice.fromJson(Map<String, dynamic> json) {
    return Notice(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? json['summary'] ?? '').toString(),
      url: json['url']?.toString(),
    );
  }
}
