/// Parses the API's `tags: [{ tag: { name } }]` shape into plain tag names.
List<String> parseTagNames(Object? raw) => raw is List
    ? raw
          .whereType<Map<String, dynamic>>()
          .map((t) => (t['tag'] as Map<String, dynamic>?)?['name'] as String?)
          .whereType<String>()
          .toList()
    : const [];
