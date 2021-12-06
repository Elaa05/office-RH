import 'package:android_intent/android_intent.dart';
import 'package:attendancewithqr/screen/about_page.dart';
import 'package:attendancewithqr/screen/attendance_page.dart';
import 'package:attendancewithqr/screen/report_page.dart';
import 'package:attendancewithqr/screen/setting_page.dart';
import 'package:attendancewithqr/screen/leave_page.dart';
import 'package:attendancewithqr/translate/translate.dart';
import 'package:attendancewithqr/utils/single_menu.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class MainMenuPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Menu();
  }
}

class Menu extends StatefulWidget {
  @override
  _MenuState createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  @override
  void initState() {
    _getPermission();
    super.initState();
  }

  void _getPermission() async {
    getPermissionAttendance();
    _checkGps();
  }

  void getPermissionAttendance() async {
    await PermissionHandler().requestPermissions([
      PermissionGroup.camera,
      PermissionGroup.location,
      PermissionGroup.locationWhenInUse,
    ]);
  }

  // Check the GPS is on
  Future _checkGps() async {
    if (!(await Geolocator().isLocationServiceEnabled())) {
      if (Theme.of(context).platform == TargetPlatform.android) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Can't get gurrent location"),
              content:
                  const Text('Please make sure your enable GPS and try again.'),
              actions: <Widget>[
                // ignore: deprecated_member_use
                FlatButton(
                  child: Text('Ok'),
                  onPressed: () async {
                    final AndroidIntent intent = AndroidIntent(
                        action: 'android.settings.LOCATION_SOURCE_SETTINGS');

                    await intent.launch();
                    Navigator.of(context, rootNavigator: true).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Container(
            margin: EdgeInsets.only(bottom: 40.0),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 200.0,
                  color: Colors.blue,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image(
                        image: AssetImage('images/logo.png'),
                      ),
                      SizedBox(
                        height: 10.0,
                      ),
                      Text(
                        main_menu_title,
                        style: TextStyle(
                            fontSize: 18.0,
                            color: Color(0xFFf7c846),
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    SingleMenu(
                      icon: FontAwesomeIcons.clock,
                      menuName: main_menu_check_in,
                      color: Colors.blue,
                      action: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AttendancePage(
                            query: 'in',
                            title: main_menu_check_in_title,
                          ),
                        ),
                      ),
                    ),
                    SingleMenu(
                      icon: FontAwesomeIcons.signOutAlt,
                      menuName: main_menu_check_out,
                      color: Colors.teal,
                      action: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AttendancePage(
                            query: 'out',
                            title: main_menu_check_out_title,
                          ),
                        ),
                      ),
                    ),
                    SingleMenu(
                      icon: FontAwesomeIcons.cogs,
                      menuName: main_menu_settings,
                      color: Colors.green,
                      action: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => SettingPage()),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    SingleMenu(
                      icon: FontAwesomeIcons.calendar,
                      menuName: main_menu_report,
                      color: Colors.yellow[700],
                      action: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => ReportPage()),
                      ),
                    ),
                    SingleMenu(
                      icon: FontAwesomeIcons.userAlt,
                      menuName: main_menu_about,
                      color: Colors.purple,
                      action: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => AboutPage()),
                      ),
                    ),
                    SingleMenu(
                        icon: FontAwesomeIcons.info,
                        menuName: 'v 1.0',
                        color: Colors.red[300]),
                  ],
                ),       Row(
                  children: [
                    SingleMenu(
                      icon: FontAwesomeIcons.calendar,
                      menuName: main_menu_leave,
                      color: Colors.red[700],
                      action: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => LeavePage()),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
