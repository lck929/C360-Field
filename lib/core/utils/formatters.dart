import 'package:intl/intl.dart';

String formatHm(DateTime time) => DateFormat('HH:mm').format(time.toLocal());

String formatDay(DateTime day) => DateFormat('EEE d MMM').format(day.toLocal());

String formatWeekday(DateTime day) => DateFormat('EEEEE').format(day);

String formatApiDate(DateTime day) => DateFormat('yyyy-MM-dd').format(day);

String formatDuration(Duration duration) {
  final minutes = duration.isNegative ? 0 : duration.inMinutes;
  return '${minutes ~/ 60} h ${(minutes % 60).toString().padLeft(2, '0')} m';
}

String isoWithOffset(DateTime time) {
  final local = time.toLocal();
  final offset = local.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final hours = offset.abs().inHours.toString().padLeft(2, '0');
  final minutes = (offset.abs().inMinutes % 60).toString().padLeft(2, '0');
  return "${DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(local)}$sign$hours:$minutes";
}

String greetingFor(DateTime now) => now.hour < 12
    ? 'Good morning'
    : now.hour < 17
        ? 'Good afternoon'
        : 'Good evening';
