import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../libs/libdfu.dart';
import '../libs/libusb.dart';
import '../main.dart';

class _DeviceCard extends StatelessWidget {
  void Function()? onTap;
  String deviceImageAssetPath;
  String deviceName;

  _DeviceCard(
      {Key? key,
      this.onTap,
      required this.deviceName,
      required this.deviceImageAssetPath})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: FittedBox(
            fit: BoxFit.fitHeight,
            child: Column(
              children: [
                Image.asset(
                  deviceImageAssetPath,
                ),
                Text(deviceName, style: TextStyle(fontSize: 48.0))
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PickDevicePage extends StatefulWidget {
  const PickDevicePage({Key? key}) : super(key: key);

  @override
  State<PickDevicePage> createState() => _PickDevicePageState();
}

class _PickDevicePageState extends State<PickDevicePage> {
  static bool _checkedForUpdates = false;

  void _checkForUpdates(BuildContext context) async {
    final dio = Dio();
    try {
      final latestReleaseInfo = await dio.get(
          "https://api.github.com/repos/pine64/pine64_updater/releases/latest");
      if (latestReleaseInfo.data['tag_name'] != packageInfo.version) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('New update available!'),
              content: Text('Do you want redirect to download page?'),
              actions: <Widget>[
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      launch(
                          "https://github.com/pine64/pine64_updater/releases/latest");
                    },
                    child: Text('Yes')),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('No'),
                )
              ],
            );
          },
        );
      }
    } catch (ex) {
      print(ex);
    }
  }

  void _initNativeLibraries(BuildContext context) {
    try {
      libUSB.init();
      libDFU.init();
    } catch (ex) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Application failed to initialize.'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                    'Application failed to initialize native libraries. Please report this on Github.'),
                SelectableText('Error: $ex')
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  exit(0);
                },
                child: const Text('Close App'),
              )
            ],
          );
        },
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      if (!libUSB.initialized) {
        _initNativeLibraries(context);
      }
      if (!_checkedForUpdates) {
        _checkedForUpdates = true;
        _checkForUpdates(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick a device to update'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'PINE64 Updater',
                style: TextStyle(color: Colors.white, fontSize: 32),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About'),
              onTap: () {
                Navigator.pushNamed(context, '/about');
              },
            ),
            ListTile(
              leading: const Icon(Icons.bug_report_outlined),
              title: const Text('Report a bug'),
              onTap: () =>
                  launch("https://github.com/pine64/pine64_updater/issues"),
            )
          ],
        ),
      ),
      body: GridView.count(
        crossAxisCount: MediaQuery.of(context).size.shortestSide < 600 ? 2 : 4,
        children: [
          _DeviceCard(
            onTap: () => Navigator.of(context).pushNamed('/flash/pinecil'),
            deviceName: "Pinecil",
            deviceImageAssetPath: "assets/images/pinecil.png",
          )
        ],
      ),
    );
  }
}
