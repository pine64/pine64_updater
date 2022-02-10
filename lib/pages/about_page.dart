import 'package:flutter/material.dart';
import 'package:pine64_updater/main.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("About"),
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "PINE64 Updater ${packageInfo.version}",
              style: const TextStyle(fontSize: 28.0),
            ),
            const Text("© 2022 Marek Kraus and PINE64 Community"),
            const SizedBox(height: 16.0),
            const Text(
                "Huge thanks for everyone from community who helped with testing and giving feedback."),
            const SizedBox(height: 16.0),
            const Text(
                "This application uses open-source software, you can find their licenses in LICENSE_3RD_PARTY file.")
          ],
        ),
      ),
    );
  }
}
