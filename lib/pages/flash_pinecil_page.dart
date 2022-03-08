import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:clipboard/clipboard.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pine64_updater/libs/libdfu.dart';
import 'package:pine64_updater/libs/libusb.dart';
import 'package:http/http.dart' as http;

import '../main.dart';

class FlashPinecilPage extends StatefulWidget {
  const FlashPinecilPage({Key? key}) : super(key: key);

  @override
  State<FlashPinecilPage> createState() => _FlashPinecilPageState();
}

enum _PinecilState { Disconnected, Connected, ConnectedNoDriver, Error }

class _LogMessage {
  final bool isError;
  final String message;

  _LogMessage(this.message, this.isError);
}

class _FirmwareEntry {
  final String name;
  final String fileName;
  final String zipUrl;

  _FirmwareEntry(this.name, this.fileName, this.zipUrl);
}

class _FlashPinecilPageState extends State<FlashPinecilPage> {
  int _currentStep = 0;
  Timer? _usbTimer;
  int _previousDevicesCount = -1;
  _PinecilState _pinecilState = _PinecilState.Disconnected;
  bool _isLogOpened = false;
  final _log = List<_LogMessage>.empty(growable: true);
  String _state = 'Loading...';
  int _progress = 0;
  bool _errorOccured = false;
  late Future<List<_FirmwareEntry>> _firmwareListFuture;
  _FirmwareEntry? _firmwareToFlash;
  final _dio = Dio();

  bool get _isPinecilConnected => (_pinecilState == _PinecilState.Connected ||
      _pinecilState == _PinecilState.ConnectedNoDriver);
  final _firmwarePathController = TextEditingController();

  void _startUSBTimer() {
    _usbTimer =
        Timer.periodic(const Duration(seconds: 1), _updatePinecilStatus);
  }

  @override
  void initState() {
    super.initState();
    _startUSBTimer();
    _firmwareListFuture = _getLatestFirmwares();
  }

  @override
  void dispose() {
    super.dispose();
    _usbTimer?.cancel();
    _firmwarePathController.dispose();
  }

  Future<void> _parseJsonMetadata(List<_FirmwareEntry> firmwaresList,
      ArchiveFile jsonArchive, String zipUrl) async {
    final metadata = jsonDecode(utf8.decode(jsonArchive.content));
    final list = List<_FirmwareEntry>.empty(growable: true);
    for (String firmwareFile in metadata['contents'].keys) {
      if (firmwareFile.contains('.hex')) continue;
      final firmwareInfo = metadata['contents'][firmwareFile];
      list.add(
        _FirmwareEntry(
            "IronOS ${metadata['release']} - ${firmwareInfo['language_name']}",
            firmwareFile,
            zipUrl),
      );
    }
    list.sort((a, b) => a.fileName.compareTo(b.fileName));
    firmwaresList.addAll(list);
  }

  Future<List<_FirmwareEntry>> _getLatestFirmwares() async {
    final list = List<_FirmwareEntry>.empty(growable: true);
    try {
      final githubResponse = await _dio
          .get("https://api.github.com/repos/Ralim/IronOS/releases/latest");
      if (githubResponse.statusCode != 200) {
        throw "Failed to fetch Github releases";
      }
      List<dynamic> assets = githubResponse.data['assets'];
      final pinecilZipUrl = assets.singleWhere((element) =>
          element['name'] == 'Pinecil.zip')?['browser_download_url'];
      final pinecilMultilangZipUrl = assets.singleWhere((element) =>
          element['name'] == 'Pinecil_multi-lang.zip')?['browser_download_url'];
      final metadata =
          assets.singleWhere((element) => element['name'] == "metadata.zip");
      final metadataRequest = await _dio.get(metadata['browser_download_url'],
          options: Options(responseType: ResponseType.bytes));
      final metadataZip = ZipDecoder().decodeBytes(metadataRequest.data);
      final pinecilMultilangJsonFile = metadataZip
          .singleWhere((element) => element.name == "Pinecil_multi-lang.json");
      await _parseJsonMetadata(
          list, pinecilMultilangJsonFile, pinecilMultilangZipUrl);
      final pinecilJsonFile =
          metadataZip.singleWhere((element) => element.name == "Pinecil.json");
      await _parseJsonMetadata(list, pinecilJsonFile, pinecilZipUrl);
      /*final pinecilMetadata = jsonDecode(utf8.decode(pinecilJsonFile.content));
      return List<_FirmwareEntry>.generate(
          pinecilMetadata['contents'].keys.length, (index) {
        final firmwareFile = pinecilMetadata['contents'].keys.toList()[index];
        final firmwareInfo = pinecilMetadata['contents'][firmwareFile];
        return _FirmwareEntry(
            "IronOS ${pinecilMetadata['release']} - ${firmwareInfo['language_name']}",
            firmwareFile);
      });*/
    } catch (ex) {
      print(ex);
    }
    return list;
  }

  void _updatePinecilStatus(Timer timer) {
    final devicesList = libUSB.getDevicesList();
    if (_previousDevicesCount != devicesList.devices.length) {
      _previousDevicesCount = devicesList.devices.length;
      _pinecilState = _PinecilState.Disconnected;
      for (var device in devicesList.devices) {
        var descriptor = libUSB.getDeviceDescriptor(device);
        if (descriptor.idVendor == 0x28E9 && descriptor.idProduct == 0x0189) {
          try {
            final deviceHandle = libUSB.open(device);
            libUSB.close(deviceHandle);
            _pinecilState = _PinecilState.Connected;
          } on LibUSBException catch (e) {
            if (e.code == LIBUSB_ERROR_NOT_SUPPORTED) {
              _pinecilState = _PinecilState.ConnectedNoDriver;
            } else {
              _pinecilState = _PinecilState.Error;
            }
          }
          break;
        }
      }
      setState(() {
        if (_currentStep == 0 && _isPinecilConnected) {
          _currentStep = 1;
        } else if (_currentStep == 1 && !_isPinecilConnected) {
          _currentStep = 0;
        }
      });
    }
    devicesList.free();
  }

  void _copyLog() {
    String logData = _log.map((e) => e.message).join('\n');
    FlutterClipboard.copy(logData);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("The log has been copied"),
    ));
  }

  void _flashFirmware(
      {String? firmwarePath, _FirmwareEntry? firmwareEntry}) async {
    String filePath = "";

    // region Custom Firmware Check
    if (firmwareEntry == null) {
      if (firmwarePath == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("You need to specify custom firmware path"),
        ));
        return;
      }
      if (!(await File(firmwarePath).exists())) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Specified file doesn't exists"),
        ));
      }
      filePath = firmwarePath;
    }
    // endregion

    _usbTimer?.cancel();
    _usbTimer = null;
    setState(() {
      _currentStep = 2;
    });
    // TODO: custom dfu-util.exe support?
    /* late List<String> arguments;

    if (path.extension(filePath) == '.dfu') {
      arguments = [
        "-a",
        "0",
        "-D",
        filePath,
        // TODO: Mass-Erase support
      ];
    } else {
      arguments = [
        "-d",
        "28e9:0189",
        "-a",
        "0",
        "-D",
        filePath,
        "-s",
        "0x08000000" + (false ? ":mass-erase:force" : "")
      ];
    }
    var dfuUtil = await Process.start(
        '$currentWorkingDirectory/dfu-util.exe', arguments,
        runInShell: true);
    stdout.addStream(dfuUtil.stdout);
    stderr.addStream(dfuUtil.stderr); */

    // region Download Firmware
    if (firmwareEntry != null) {
      setState(() {
        _state = "Downloading firmware... 0%";
        _log.add(_LogMessage(
            "Downloading firmware " + firmwareEntry.fileName, false));
      });
      try {
        final firmwaresZipResponse = await _dio.get(
          firmwareEntry.zipUrl,
          onReceiveProgress: (count, total) => setState(() {
            _state =
                "Downloading firmware... ${((count / total) * 100.0).round()}%";
            _progress = ((count / total) * 45.0).round();
          }),
          options: Options(responseType: ResponseType.bytes),
        );
        final firmwaresZip =
            ZipDecoder().decodeBytes(firmwaresZipResponse.data);

        final firmwareZipFile = firmwaresZip.files
            .singleWhere((element) => element.name == firmwareEntry.fileName);
        final firmwareFile = File("$currentWorkingDirectory/_tmpfirm.dfu");
        await firmwareFile.create(recursive: true);
        await firmwareFile.writeAsBytes(firmwareZipFile.content);
        // TODO: Handle errors

        setState(() {
          _log.add(_LogMessage("Dowloading completed", false));
        });
        filePath = "$currentWorkingDirectory/_tmpfirm.dfu";
      } catch (ex) {
        setState(() {
          _log.add(_LogMessage(
            "Downloading of firmware failed, reason: " + ex.toString(),
            true,
          ));
          _errorOccured = true;
        });
        return;
      }
    }
    // endregion

    // region Zadic (Windows only)

    if (Platform.isWindows &&
        _pinecilState == _PinecilState.ConnectedNoDriver) {
      setState(() {
        _state = "Installing WinUSB...";
        _progress = 45;
        _log.add(_LogMessage("Installing WinUSB driver", false));
      });
      var zadic = await Process.start(
          '$currentWorkingDirectory/zadic.exe',
          [
            '--vid',
            '0x28e9',
            '--pid',
            '0x0189',
            '--noprompt',
            '--usealldevices'
          ],
          runInShell: false);
      zadic.stdout.transform(utf8.decoder).forEach((element) {
        setState(() {
          _log.add(_LogMessage(element, false));
        });
      });
      zadic.stderr.transform(utf8.decoder).forEach((element) {
        setState(() {
          _log.add(_LogMessage(element, true));
        });
      });
      var exitCode = await zadic.exitCode;
      if (exitCode != 0) {
        setState(() {
          _errorOccured = true;
        });
        return;
      }
      setState(() {
        _log.add(_LogMessage("WinUSB driver installed", false));
      });
    }

    // endregion

    // region Flashing
    libDFU.setAltSetting(0);
    libDFU.setDownload(filePath);
    if (path.extension(filePath) != '.dfu') {
      libDFU.setVendProd(0x28e9, 0x0189);
      libDFU.setDfuseOptions("0x08000000" + (false ? ":mass-erase:force" : ""));
    }
    int ret = await libDFU.execute(
      onProgress: (status, progress) => setState(() {
        if (_state != status) {
          _state = status;
        }
        if (_state == "Erase") {
          _progress = 55 + ((progress / 100.0) * 22.0).round();
        } else if (_state == "Download") {
          _progress = 77 + ((progress / 100.0) * 23.0).round();
        }
      }),
      onInfoMessage: (msg) => setState(
          () => _log.add(_LogMessage(msg.replaceAll('\n', ''), false))),
      onErrorMessage: (msg) =>
          setState(() => _log.add(_LogMessage(msg.replaceAll('\n', ''), true))),
    );
    // endregion

    setState(() {
      if (ret == 0) {
        _currentStep = 3;
      } else {
        _errorOccured = true;
      }
    });
  }

  Step _connectStep(BuildContext context) {
    return Step(
      isActive: _currentStep == 0,
      state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      title: const Text('Connect'),
      content: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Instructions:'),
          const Text(
              '0. Step: Check that you do not have DC barrel jack connected.'),
          const Text(
              '1. Step: Hold down the minus (-) button (closer to usb-c side).'),
          const Text(
              '2. Step: Plug USB-C cable into Pinecil & PC (do not release (-) button).'),
          const Text(
              '3. Step: Wait about 10 seconds until Pinecil launches to DFU mode.'),
          const Text(
              '4. Step: Release the minus (-) button. (Screen stays black during upgrade)'),
          Center(
            child: Image.asset("assets/images/pinecil_flashing.png"),
          ),
        ],
      ),
    );
  }

  Step _selectFirmwareStep(BuildContext context) {
    return Step(
      isActive: _currentStep == 1,
      state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      title: const Text('Select Firmware'),
      content: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FutureBuilder<List<_FirmwareEntry>>(
              future: _firmwareListFuture,
              builder: (context, snapshot) {
                return Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<_FirmwareEntry?>(
                        value: _firmwareToFlash,
                        isDense: true,
                        items: [
                          const DropdownMenuItem<_FirmwareEntry?>(
                            child: Text("Custom"),
                            value: null,
                          ),
                          if (snapshot.hasData)
                            ...snapshot.data!
                                .map<DropdownMenuItem<_FirmwareEntry?>>(
                                  (e) => DropdownMenuItem<_FirmwareEntry?>(
                                    child: Text(e.name),
                                    value: e,
                                  ),
                                )
                                .toList()
                        ],
                        onChanged: (item) =>
                            setState(() => _firmwareToFlash = item),
                        decoration:
                            const InputDecoration(labelText: 'Firmware Type'),
                      ),
                    ),
                    if (!snapshot.hasData)
                      Row(
                        children: const [
                          SizedBox(width: 16),
                          SizedBox(
                              width: 30,
                              height: 30,
                              child: CircularProgressIndicator()),
                        ],
                      ),
                  ],
                );
              }),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: TextField(
                  enabled: _firmwareToFlash == null,
                  controller: _firmwarePathController,
                  decoration:
                      const InputDecoration(labelText: 'Path to the firmware'),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _firmwareToFlash == null
                    ? () async {
                        var result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['bin', 'dfu']);
                        if (result != null) {
                          setState(() {
                            _firmwarePathController.text =
                                result.files.single.path ?? '';
                          });
                        }
                      }
                    : null,
                child: const Text('Browse'),
              )
            ],
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: () => _flashFirmware(
              firmwarePath: _firmwarePathController.text,
              firmwareEntry: _firmwareToFlash,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Step _updateStep(BuildContext context) {
    return Step(
      isActive: _currentStep == 2,
      state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      title: const Text('Update'),
      content: Column(
        children: [
          if (_errorOccured) ...[
            Text(
              'An error occured during flashing! You can find more information in log.',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Exit'))
          ] else ...[
            Text('$_state'),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: _progress / 100.0,
            ),
          ],
          const SizedBox(height: 32),
          ExpansionPanelList(
            expansionCallback: (panelIndex, isExpanded) => setState(
              () => _isLogOpened = !_isLogOpened,
            ),
            children: [
              ExpansionPanel(
                headerBuilder: (context, isExpanded) => ListTile(
                  title: Text('Log'),
                  trailing: IconButton(
                    onPressed: _copyLog,
                    icon: Icon(Icons.copy),
                    tooltip: 'Copy log to clipboard',
                  ),
                ),
                body: Container(
                  height: 400,
                  padding: const EdgeInsets.all(8.0),
                  decoration: const BoxDecoration(color: Colors.black),
                  child: ListView.builder(
                    itemCount: _log.length,
                    itemBuilder: (context, index) {
                      const TextStyle errorStyle = TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Firacode');
                      const TextStyle normalStyle = TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Firacode');
                      return Text(
                        _log[index].message,
                        style: _log[index].isError ? errorStyle : normalStyle,
                      );
                    },
                  ),
                ),
                isExpanded: _isLogOpened,
              ),
            ],
          )
        ],
      ),
    );
  }

  Step _unplugStep(BuildContext context) {
    return Step(
      isActive: _currentStep == 3,
      title: const Text('Unplug'),
      content: const Text(
          'Your device has been successfully flashed! Please unplug the Pinecil.'),
    );
  }

  Widget _stepperControlsBuilder(
      BuildContext context, ControlsDetails details) {
    if (details.currentStep == 0) {
      if (_pinecilState == _PinecilState.Error) {
        return const Text(
            'Something wrong happened, please try reconnect your Pinecil or restart the app.');
      }
    }
    return const SizedBox();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pinecil Update'),
        automaticallyImplyLeading: _currentStep != 2,
      ),
      body: Stepper(
        type: MediaQuery.of(context).size.shortestSide < 600
            ? StepperType.vertical
            : StepperType.horizontal,
        currentStep: _currentStep,
        controlsBuilder: _stepperControlsBuilder,
        steps: [
          _connectStep(context),
          _selectFirmwareStep(context),
          _updateStep(context),
          _unplugStep(context)
        ],
      ),
    );
  }
}
