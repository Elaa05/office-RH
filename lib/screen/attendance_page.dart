import 'dart:async';

import 'package:attendancewithqr/model/attendance.dart';
import 'package:attendancewithqr/translate/translate.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

import '../database/db_helper.dart';
import '../model/settings.dart';
import '../utils/utils.dart';

class AttendancePage extends StatefulWidget {
  final String query;
  final String title;

  AttendancePage({this.query, this.title});

  @override
  _AttendancePageState createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  // Progress dialog
  ProgressDialog pr;

  // Database
  DbHelper dbHelper = DbHelper();

  // Utils
  Utils utils = Utils();

  // Model settings
  Settings settings;

  // Global key scaffold
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  // String
  String getUrl,
      getKey,
      _barcode = "",
      getQrId,
      getQuery,
      getPath = 'api/attendance/apiSaveAttendance',
      mAccuracy;

  // Geolocation
  Position _currentPosition;
  String _currentAddress;
  final Geolocator geoLocator = Geolocator()..forceAndroidLocationManager;
  var subscription;
  double setAccuracy = 200.0;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    getSettings();
  }

  // Get latitude longitude
  _getCurrentLocation() {
    subscription = geoLocator
        .getPositionStream(LocationOptions(
            accuracy: LocationAccuracy.best, timeInterval: 1000))
        .listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }

      _getAddressFromLatLng(position.accuracy);
    });
  }

  // Get address
  _getAddressFromLatLng(double accuracy) async {
    String strAccuracy = accuracy.toStringAsFixed(1);
    if (accuracy > setAccuracy) {
      mAccuracy = '$strAccuracy $attendance_not_accurate';
    } else {
      mAccuracy = '$strAccuracy $attendance_accurate';
    }
    try {
      List<Placemark> p = await geoLocator.placemarkFromCoordinates(
          _currentPosition.latitude, _currentPosition.longitude);

      Placemark placeMark = p[0];
      if (mounted) {
        setState(() {
          _currentAddress =
              "$mAccuracy ${placeMark.name}, ${placeMark.subLocality}, ${placeMark.subAdministrativeArea} - ${placeMark.administrativeArea}.";
        });
      }
    } catch (e) {
      print(e);
    }
  }

  // Get settings data
  void getSettings() async {
    var getSettings = await dbHelper.getSettings(1);
    setState(() {
      getUrl = getSettings.url;
      getKey = getSettings.key;
    });
  }

  // Send data post via http
  sendData() async {
    // Get info for attendance
    var dataAddress = _currentAddress;
    var dataKey = getKey;
    var dataQrId = getQrId;
    var dataQuery = getQuery;

    // Add data to map
    Map<String, dynamic> body = {
      'location': dataAddress,
      'key': dataKey,
      'qr_id': dataQrId,
      'q': dataQuery,
    };

    // Sending the data to server
    final uri = utils.getRealUrl(getUrl, getPath);
    Dio dio = new Dio();
    FormData formData = new FormData.fromMap(body);
    final response = await dio.post(uri, data: formData);

    var data = response.data;

    // Show response from server via snackBar
    if (data['message'] == 'Success!') {
      // Set the url and key
      Attendance attendance = Attendance(
          date: data['date'],
          time: data['time'],
          location: data['location'],
          type: data['query']);

      // Insert the settings
      insertAttendance(attendance);

      // Hide the loading
      Future.delayed(Duration(seconds: 2)).then((value) {
        if (mounted) {
          setState(() {
            subscription.cancel();

            pr.hide();

            utils.showAlertDialog(
                "$attendance_show_alert-$dataQuery $attendance_success_ms",
                "Success",
                AlertType.success,
                _scaffoldKey,
                true);
          });
        }
      });
    } else if (data['message'] == 'already check-in') {
      setState(() {
        pr.hide();

        utils.showAlertDialog(
            already_check_in, "warning", AlertType.warning, _scaffoldKey, true);
      });
    } else if (data['message'] == 'check-in first') {
      setState(() {
        pr.hide();

        utils.showAlertDialog(
            check_in_first, "warning", AlertType.warning, _scaffoldKey, true);
      });
    } else if (data['message'] == 'Error Qr!') {
      setState(() {
        pr.hide();

        utils.showAlertDialog(
            format_barcode_wrong, "Error", AlertType.error, _scaffoldKey, true);
      });
    } else if (data['message'] == 'Error! Something Went Wrong!') {
      setState(() {
        pr.hide();

        utils.showAlertDialog(attendance_error_server, "Error", AlertType.error,
            _scaffoldKey, true);
      });
    } else {
      setState(() {
        pr.hide();

        utils.showAlertDialog(response.data.toString(), "Error",
            AlertType.error, _scaffoldKey, true);
      });
    }
  }

  insertAttendance(Attendance object) async {
    await dbHelper.newAttendances(object);
  }

  // Scan the QR name of user
  Future scan() async {
    try {
      var barcode = await BarcodeScanner.scan();
      // The value of Qr Code

      if (barcode != null && barcode != '') {
        // Decode the json data form QR
        setState(() {
          // Show dialog
          pr.show();

          // Get name from QR
          getQrId = barcode;
          // Sending the data
          sendData();
        });
      } else {
        utils.showAlertDialog(
            '$barcode_empty', "Error", AlertType.error, _scaffoldKey, true);
      }
    } on PlatformException catch (e) {
      if (e.code == BarcodeScanner.CameraAccessDenied) {
        _barcode = '$camera_permission';
        utils.showAlertDialog(
            _barcode, "Warning", AlertType.warning, _scaffoldKey, true);
      } else {
        _barcode = '$barcode_unknown_error $e';
        utils.showAlertDialog(
            _barcode, "Error", AlertType.error, _scaffoldKey, true);
      }
    } catch (e) {
      _barcode = '$barcode_unknown_error : $e';
      print(_barcode);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show progress
    pr = new ProgressDialog(context,
        isDismissible: false, type: ProgressDialogType.Normal);
    // Style progress
    pr.style(
        message: attendance_sending,
        borderRadius: 10.0,
        backgroundColor: Colors.white,
        progressWidget: CircularProgressIndicator(),
        elevation: 10.0,
        padding: EdgeInsets.all(10.0),
        insetAnimCurve: Curves.easeInOut,
        progress: 0.0,
        maxProgress: 100.0,
        progressTextStyle: TextStyle(
            color: Colors.black, fontSize: 13.0, fontWeight: FontWeight.w400),
        messageTextStyle: TextStyle(
            color: Colors.black, fontSize: 19.0, fontWeight: FontWeight.w600));

    // Init the query
    getQuery = widget.query;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              '$attendance_accurate_info $mAccuracy $attendance_on_gps',
              style: TextStyle(color: Colors.grey[600], fontSize: 14.0),
              textAlign: TextAlign.center,
            ),
            Container(
              margin: EdgeInsets.all(20.0),
              child: ButtonTheme(
                minWidth: double.infinity,
                height: 60.0,
                // ignore: deprecated_member_use
                child: RaisedButton(
                  child: Text(button_scan),
                  color: Color(0xFFf7c846),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                  ),
                  textColor: Colors.black,
                  onPressed: () => scan(),
                ),
              ),
            ),
            Text(
              '$attendance_button_info-$getQuery.',
              style: TextStyle(color: Colors.grey, fontSize: 12.0),
            ),
          ],
        ),
      ),
    );
  }
}
