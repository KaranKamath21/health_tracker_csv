import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart' as perm_handler;
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';
import 'package:share_plus/share_plus.dart';

class SaveAsCSV extends StatefulWidget {
  @override
  _SaveAsCSVState createState() => _SaveAsCSVState();
}

class _SaveAsCSVState extends State<SaveAsCSV> {
  List<HealthDataPoint> _healthDataList = [];
  AppState _state = AppState.DATA_NOT_FETCHED;
  bool _isTripActive = false;
  List<Map<String, dynamic>> _tripData = [];
  Timer? _dataTimer;
  Timer? _heartRateTimer;
  bool _isLoading = false;

  late final startingTime;
  late final endingTime;

  List<HealthDataType> get types => (Platform.isAndroid)
      ? dataTypesAndroid
      : (Platform.isIOS)
      ? dataTypesIOS
      : [];

  static final dataTypesAndroid = [
    HealthDataType.HEART_RATE,
  ];

  static final dataTypesIOS = [
    HealthDataType.HEART_RATE,
  ];

  List<HealthDataAccess> get permissions =>
      types.map((e) => HealthDataAccess.READ).toList();

  @override
  void initState() {
    Health().configure(useHealthConnectIfAvailable: true);
    super.initState();
  }

  Future<void> authorize() async {
    await perm_handler.Permission.activityRecognition.request();
    await perm_handler.Permission.location.request();

    bool? hasPermissions =
    await Health().hasPermissions(types, permissions: permissions);

    hasPermissions = false;

    bool authorized = false;
    if (!hasPermissions) {
      try {
        authorized = await Health()
            .requestAuthorization(types, permissions: permissions);
      } catch (error) {
        debugPrint("Exception in authorize: $error");
      }
    }

    setState(() => _state =
    (authorized) ? AppState.AUTHORIZED : AppState.AUTH_NOT_GRANTED);
  }

  void _toggleTrip() {
    setState(() {
      _isTripActive = !_isTripActive;
      startingTime = DateTime.now();
    });

    if (_isTripActive) {
      // Start collecting data
      _startCollectingData();
    } else {
      // Stop collecting data and upload to Firestore
      _stopCollectingData();
    }
  }

  void _startCollectingData() {
    _dataTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      _collectSensorAndLocationData();
    });

    _heartRateTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      _collectHeartRateData();
    });
  }

  void _stopCollectingData() async {
    _dataTimer?.cancel();
    _heartRateTimer?.cancel();

    setState(() {
      _isLoading = true;
    });

    // Save collected data to Excel and provide download option
    await _saveDataToExcel();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _collectHeartRateData() async {
    final now = DateTime.now();
    final oneMinuteAgo = now.subtract(Duration(minutes: 1));

    List<HealthDataPoint> healthData = await Health().getHealthDataFromTypes(
      types: types,
      startTime: oneMinuteAgo,
      endTime: now,
    );

    healthData = Health().removeDuplicates(healthData);

    setState(() {
      _healthDataList.addAll(healthData);
    });

    if (healthData.isNotEmpty) {
      var heartRateData = {
        'type': 'heart_rate',
        'value': healthData.first.value,
        'timestamp': now,
      };
      _tripData.add(heartRateData);
    }
  }

  void _collectSensorAndLocationData() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    accelerometerEvents.listen((AccelerometerEvent event) {
      var sensorData = {
        'type': 'accelerometer',
        'x': event.x,
        'y': event.y,
        'z': event.z,
        'timestamp': DateTime.now(),
      };
      _tripData.add(sensorData);
    });

    gyroscopeEvents.listen((GyroscopeEvent event) {
      var sensorData = {
        'type': 'gyroscope',
        'x': event.x,
        'y': event.y,
        'z': event.z,
        'timestamp': DateTime.now(),
      };
      _tripData.add(sensorData);
    });

    magnetometerEvents.listen((MagnetometerEvent event) {
      var sensorData = {
        'type': 'magnetometer',
        'x': event.x,
        'y': event.y,
        'z': event.z,
        'timestamp': DateTime.now(),
      };
      _tripData.add(sensorData);
    });

    var locationData = {
      'type': 'location',
      'latitude': position.latitude,
      'longitude': position.longitude,
      'timestamp': DateTime.now(),
    };

    _tripData.add(locationData);
  }

  Future<void> _saveDataToExcel() async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Sheet1'];

    sheetObject.appendRow([
      TextCellValue('Type'),
      TextCellValue('Value'),
      TextCellValue('X'),
      TextCellValue('Y'),
      TextCellValue('Z'),
      TextCellValue('Latitude'),
      TextCellValue('Longitude'),
      TextCellValue('Timestamp'),
    ]);

    sheetObject.appendRow([
      TextCellValue('1'),
      TextCellValue('1'),
      TextCellValue('1'),
      TextCellValue('1'),
      TextCellValue('1'),
      TextCellValue('1'),
      TextCellValue('1'),
      TextCellValue('1'),
    ]);

    print("ability");
    print("ability");
    print("ability");
    print("ability");
    print("ability");
    print("ability");

    for (var data in _tripData) {
      sheetObject.appendRow([
        TextCellValue(data['type'].toString()),
        TextCellValue(data['value']?.toString() ?? ''),
        TextCellValue(data['x']?.toString() ?? ''),
        TextCellValue(data['y']?.toString() ?? ''),
        TextCellValue(data['z']?.toString() ?? ''),
        TextCellValue(data['latitude']?.toString() ?? ''),
        TextCellValue(data['longitude']?.toString() ?? ''),
        TextCellValue(data['timestamp'].toString()),
      ]);
    }

    sheetObject.appendRow([
      TextCellValue('2'),
      TextCellValue('2'),
      TextCellValue('2'),
      TextCellValue('2'),
      TextCellValue('2'),
      TextCellValue('2'),
      TextCellValue('2'),
      TextCellValue('2'),
    ]);

    print("done");
    print("done");
    print("done");
    print("done");
    print("done");


    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/trip_data.xlsx';
    File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(excel.encode()!);

    // Provide download option to the user using Share Plus
    final box = context.findRenderObject() as RenderBox?;
    await Share.shareXFiles([XFile(path)], text: 'Trip Data Excel File', sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size);

    // Clear trip data after saving
    setState(() {
      _tripData.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Health App'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: authorize,
                child: Text("Authorize"),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _toggleTrip,
                child: _isLoading
                    ? CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
                    : Text(_isTripActive ? 'End Trip' : 'Start Trip'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum AppState {
  DATA_NOT_FETCHED,
  FETCHING_DATA,
  DATA_READY,
  NO_DATA,
  AUTHORIZED,
  AUTH_NOT_GRANTED,
}
