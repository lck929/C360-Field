class Employee {
  const Employee({
    required this.employeeId,
    required this.name,
    required this.trade,
    required this.faceEnrolled,
    required this.projectId,
    required this.projectName,
    required this.wifiBssids,
    required this.shiftStart,
    required this.shiftEnd,
  });

  final String employeeId;
  final String name;
  final String trade;
  final bool faceEnrolled;
  final String projectId;
  final String projectName;
  final List<String> wifiBssids;
  final String shiftStart;
  final String shiftEnd;

  List<String> get _parts => name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();

  String get firstName => _parts.isEmpty ? employeeId : _parts.first;

  String get initials => _parts.isNotEmpty
      ? _parts.take(2).map((p) => p[0].toUpperCase()).join()
      : employeeId.isEmpty
          ? '?'
          : employeeId[0];

  String get shiftLabel => '$shiftStart – $shiftEnd';
}
