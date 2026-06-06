class DialogueMessage {
  final String speaker;
  final String text;
  final String createdAt;

  DialogueMessage({
    required String speaker,
    required String text,
    String? createdAt,
  }) : speaker = speaker.trim(),
       text = text.trim(),
       createdAt = (createdAt == null || createdAt.trim().isEmpty)
           ? DateTime.now().toIso8601String()
           : createdAt.trim();

  factory DialogueMessage.fromJson(Map<String, dynamic> json) {
    return DialogueMessage(
      speaker: json['speaker'] as String? ?? '',
      text: json['text'] as String? ?? '',
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'speaker': speaker,
    'text': text,
    'createdAt': createdAt,
  };
}
