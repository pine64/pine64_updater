import 'package:flutter/material.dart';

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
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About'),
              onTap: () {
                Navigator.pushNamed(context, '/about');
              },
            ),
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
