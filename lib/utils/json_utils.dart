Map<String, dynamic> asJsonMap(Object? value) {
  return Map<String, dynamic>.from(value as Map);
}

List<dynamic> asJsonList(Object? value) {
  return List<dynamic>.from(value as List);
}
