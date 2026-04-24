String shortDisplayName(String? value, {int maxCharacters = 9}) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) return '';
  if (trimmed.length <= maxCharacters) return trimmed;
  return trimmed.substring(0, maxCharacters);
}
