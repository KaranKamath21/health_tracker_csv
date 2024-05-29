import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:carp_serializable/carp_serializable.dart';

class HealthApp extends StatefulWidget {
  @override
  _HealthAppState createState() => _HealthAppState();
}

enum AppState {
  DATA_NOT_FETCHED,
  FETCHING_DATA,
  DATA_READY,
  NO_DATA,
  AUTHORIZED,
  AUTH_NOT_GRANTED,
  DATA_ADDED,
  DATA_DELETED,
  DATA_NOT_ADDED,
  DATA_NOT_DELETED,
  STEPS_READY,
  HEALTH_CONNECT_STATUS,
}

class _HealthAppState extends State<HealthApp> {
  List<HealthDataPoint> _healthDataList = [];
  AppState _state = AppState.DATA_NOT_FETCHED;
  int _nofSteps = 0;
  var _contentHealthConnectStatus;

  List<HealthDataType> get types => (Platform.isAndroid)
      ? dataTypesAndroid
      : (Platform.isIOS)
      ? dataTypesIOS
      : [];

  static final dataTypesAndroid = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.ACTIVE_ENERGY_BURNED,
  ];

  static final dataTypesIOS = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    // HealthDataType.ACTIVE_ENERGY_BURNED,
    // HealthDataType.BLOOD_GLUCOSE,
  ];

  List<HealthDataAccess> get permissions =>
      types.map((e) => HealthDataAccess.READ).toList();

  @override
  void initState() {
    Health().configure(useHealthConnectIfAvailable: true);
    super.initState();
  }

  Future<void> installHealthConnect() async {
    await Health().installHealthConnect();
  }

  Future<void> authorize() async {
    await Permission.activityRecognition.request();
    await Permission.location.request();

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

  // Future<void> getHealthConnectSdkStatus() async {
  //   assert(Platform.isAndroid, "This is only available on Android");
  //
  //   final status = await Health().getHealthConnectSdkStatus();
  //
  //
  //   setState(() {
  //     _contentHealthConnectStatus = Text('Health Connect Status: $status');
  //     _state = AppState.HEALTH_CONNECT_STATUS;
  //   });
  // }

  Future<void> fetchData() async {
    setState(() => _state = AppState.FETCHING_DATA);

    final now = DateTime.now();
    final yesterday = now.subtract(Duration(hours: 24));

    _healthDataList.clear();

    List<HealthDataPoint> healthData = await Health().getHealthDataFromTypes(
      types: types,
      startTime: yesterday,
      endTime: now,
    );

    debugPrint('Total number of data points: ${healthData.length}. '
        '${healthData.length > 100 ? 'Only showing the first 100.' : ''}');

    _healthDataList.addAll(
        (healthData.length < 100) ? healthData : healthData.sublist(0, 100));

    _healthDataList = Health().removeDuplicates(_healthDataList);

    _healthDataList.forEach((data) => debugPrint(toJsonString(data)));

    setState(() {
      _state = _healthDataList.isEmpty ? AppState.NO_DATA : AppState.DATA_READY;
    });
  }

  // Future<void> deleteData() async {
  //   final now = DateTime.now();
  //   final earlier = now.subtract(Duration(hours: 24));
  //
  //   bool success = true;
  //   for (HealthDataType type in types) {
  //     success &= await Health().delete(
  //       type: type,
  //       startTime: earlier,
  //       endTime: now,
  //     );
  //   }
  //
  //   setState(() {
  //     _state = success ? AppState.DATA_DELETED : AppState.DATA_NOT_DELETED;
  //   });
  // }

  Future<void> fetchStepData() async {
    int? steps;

    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    bool stepsPermission =
        await Health().hasPermissions([HealthDataType.STEPS]) ?? false;
    if (!stepsPermission) {
      stepsPermission =
      await Health().requestAuthorization([HealthDataType.STEPS]);
    }

    if (stepsPermission) {
      try {
        steps = await Health().getTotalStepsInInterval(midnight, now);
      } catch (error) {
        debugPrint("Exception in getTotalStepsInInterval: $error");
      }

      debugPrint('Total number of steps: $steps');

      setState(() {
        _nofSteps = (steps == null) ? 0 : steps;
        _state = (steps == null) ? AppState.NO_DATA : AppState.STEPS_READY;
      });
    } else {
      debugPrint("Authorization not granted - error in authorization");
      setState(() => _state = AppState.DATA_NOT_FETCHED);
    }
  }

  // Future<void> revokeAccess() async {
  //   try {
  //     await Health().revokePermissions();
  //   } catch (error) {
  //     debugPrint("Exception in revokeAccess: $error");
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Health Example'),
        ),
        body: Container(
          child: Column(
            children: [
              Wrap(
                spacing: 10,
                children: [
                  TextButton(
                      onPressed: authorize,
                      child: Text("Authenticate",
                          style: TextStyle(color: Colors.white)),
                      style: ButtonStyle(
                          backgroundColor:
                          MaterialStatePropertyAll(Colors.blue))),
                  // if (Platform.isAndroid)
                  //   TextButton(
                  //       onPressed: getHealthConnectSdkStatus,
                  //       child: Text("Check Health Connect Status",
                  //           style: TextStyle(color: Colors.white)),
                  //       style: ButtonStyle(
                  //           backgroundColor:
                  //           MaterialState PropertyAll(Colors.blue))),
                  TextButton(
                      onPressed: fetchData,
                      child: Text("Fetch Data",
                          style: TextStyle(color: Colors.white)),
                      style: ButtonStyle(
                          backgroundColor:
                          MaterialStatePropertyAll(Colors.blue))),
                  // TextButton(
                  //     onPressed: deleteData,
                  //     child: Text("Delete Data",
                  //         style: TextStyle(color: Colors.white)),
                  //     style: ButtonStyle(
                  //         backgroundColor:
                  //         MaterialStatePropertyAll(Colors.blue))),
                  TextButton(
                      onPressed: fetchStepData,
                      child: Text("Fetch Step Data",
                          style: TextStyle(color: Colors.white)),
                      style: ButtonStyle(
                          backgroundColor:
                          MaterialStatePropertyAll(Colors.blue))),
                  // TextButton(
                  //     onPressed: revokeAccess,
                  //     child: Text("Revoke Access",
                  //         style: TextStyle(color: Colors.white)),
                  //     style: ButtonStyle(
                  //         backgroundColor:
                  //         MaterialStatePropertyAll(Colors.red))),
                  // if (Platform.isAndroid)
                  //   TextButton(
                  //       onPressed: installHealthConnect,
                  //       child: Text("Install Health Connect",
                  //           style: TextStyle(color: Colors.white)),
                  //       style: ButtonStyle(
                  //           backgroundColor:
                  //           MaterialStatePropertyAll(Colors.green))),
                ],
              ),
              Expanded(
                child: Center(child: _content()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content() {
    switch (_state) {
      case AppState.DATA_READY:
        return ListView.builder(
          itemCount: _healthDataList.length,
          itemBuilder: (_, index) {
            HealthDataPoint p = _healthDataList[index];
            return ListTile(
              title: Text("${p.typeString}: ${p.value}"),
              trailing: Text('${p.unitString}'),
              subtitle: Text(
                '${p.dateFrom} - ${p.dateTo}',
                style: TextStyle(color: Colors.black),
              ),
            );
          },
        );
      case AppState.NO_DATA:
        return Text('No Data to Show');
      case AppState.AUTH_NOT_GRANTED:
        return Text('Authorization not granted');
      case AppState.FETCHING_DATA:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(strokeWidth: 10),
            SizedBox(height: 20),
            Text('Fetching data...'),
          ],
        );
      case AppState.STEPS_READY:
        return Text('Total number of steps: $_nofSteps');
      case AppState.HEALTH_CONNECT_STATUS:
        return _contentHealthConnectStatus;
      default:
        return Text('Press a button to fetch data');
    }
  }
}