import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'theme/app_theme.dart';
import 'models/alarm_model.dart';
import 'services/alarm_service.dart';
import 'services/alarm_storage_service.dart';
import 'services/sleep_storage_service.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/alarm_ring_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz_data.initializeTimeZones();

  final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(currentTimeZone));

  await AlarmStorageService.init();
  await SleepStorageService.init();
  await AlarmService.init();

  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  const initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  final notificationsPlugin = FlutterLocalNotificationsPlugin();
  await notificationsPlugin.initialize(initSettings);

  final androidPlugin = notificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  await androidPlugin?.requestNotificationsPermission();
  await androidPlugin?.requestExactAlarmsPermission();

  final iosPlugin = notificationsPlugin
      .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
  await iosPlugin?.requestPermissions(
    alert: true,
    badge: true,
    sound: true,
    critical: true,
  );

  bool isRingScreenOpen = false;

Alarm.ringing.listen((alarmSet) {
  if (alarmSet.alarms.isEmpty || isRingScreenOpen) return;

  final settings = alarmSet.alarms.first;
  final storedAlarms = AlarmStorageService.loadAlarms();
  final model = AlarmService.findAlarmModelForSettingsId(settings.id, storedAlarms);

  isRingScreenOpen = true;
  navigatorKey.currentState
      ?.push(
        MaterialPageRoute(
          builder: (_) => AlarmRingScreen(
            alarmSettings: settings,
            taskType: model?.taskType ?? TaskType.pushUps,
            targetReps: model?.targetReps ?? 10,
          ),
        ),
      )
      .then((_) => isRingScreenOpen = false);
});

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Task Alarm',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainNavigationScreen(),
    );
  }
}