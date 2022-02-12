import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:pine64_updater/main.dart';

typedef _libdfu_set_download_t = Void Function(Pointer<Utf8> filename);
typedef _libdfu_set_altsetting_t = Void Function(Int32 alt);
typedef _libdfu_set_vendprod_t = Void Function(Int32 vendor, Int32 product);
typedef _libdfu_set_dfuse_options_t = Void Function(Pointer<Utf8> dfuseOpts);
typedef _libdfu_execute_t = Int32 Function();
typedef _libdfu_execute_dart_t = Void Function(Int64);
typedef _libdfu_init_dart_t = Int32 Function(Pointer<Void>);

/*typedef MsgCallback = Void Function(Pointer<Utf8>);
typedef MsgProgressCallback = Void Function(Pointer<Utf8>, Int32);

typedef _libdfu_set_stderr_callback_t = Void Function(
    Pointer<NativeFunction<MsgCallback>>); // void (*callback)(const char *)
typedef _libdfu_set_stdout_callback_t = Void Function(
    Pointer<NativeFunction<MsgCallback>>);
typedef _libdfu_set_progress_callback_t = Void Function(
    Pointer<NativeFunction<MsgProgressCallback>>);*/

class _LibDFU {
  late final DynamicLibrary _dyLib;
  late final void Function(Pointer<Utf8> filename) _set_download;
  late final void Function(int alt) _set_altsetting;
  late final void Function(int vendor, int product) _set_vendprod;
  late final void Function(Pointer<Utf8> dfuseOpts) _set_dfuse_options;
  late final int Function() _execute;
  /*late final void Function(Pointer<NativeFunction<MsgCallback>>)
      _set_stderr_callback;
  late final void Function(Pointer<NativeFunction<MsgCallback>>)
      _set_stdout_callback;
  late final void Function(Pointer<NativeFunction<MsgProgressCallback>>)
      _set_progress_callback;*/
  late final int Function(Pointer<Void> api) _init_dart;
  late final void Function(int port) _execute_dart;

  void Function(String msg)? _onInfoMessageCallback = null;
  void Function(String error)? _onErrorMessageCallback = null;
  void Function(String status, int progress)? _onProgressCallback = null;
  ReceivePort? _receivePort = null;

  _LibDFU() {
    if (Platform.isWindows) {
      _dyLib = DynamicLibrary.open('${currentWorkingDirectory}/dfu-util.dll');
    } else if (Platform.isMacOS) {
      _dyLib = DynamicLibrary.open('libdfu-util.1.0.dylib');
    }
    _set_download = _dyLib
        .lookup<NativeFunction<_libdfu_set_download_t>>('libdfu_set_download')
        .asFunction();
    _set_altsetting = _dyLib
        .lookup<NativeFunction<_libdfu_set_altsetting_t>>(
            'libdfu_set_altsetting')
        .asFunction();
    _set_vendprod = _dyLib
        .lookup<NativeFunction<_libdfu_set_vendprod_t>>('libdfu_set_vendprod')
        .asFunction();
    _set_dfuse_options = _dyLib
        .lookup<NativeFunction<_libdfu_set_dfuse_options_t>>(
            'libdfu_set_dfuse_options')
        .asFunction();
    _execute = _dyLib
        .lookup<NativeFunction<_libdfu_execute_t>>('libdfu_execute')
        .asFunction();
    _execute_dart = _dyLib
        .lookup<NativeFunction<_libdfu_execute_dart_t>>('libdfu_execute_dart')
        .asFunction();
    _init_dart = _dyLib
        .lookup<NativeFunction<_libdfu_init_dart_t>>('libdfu_init_dart')
        .asFunction();

    /*_set_stderr_callback = _dyLib
        .lookup<NativeFunction<_libdfu_set_stderr_callback_t>>(
            'libdfu_set_stderr_callback')
        .asFunction();
    _set_stdout_callback = _dyLib
        .lookup<NativeFunction<_libdfu_set_stdout_callback_t>>(
            'libdfu_set_stdout_callback')
        .asFunction();
    _set_progress_callback = _dyLib
        .lookup<NativeFunction<_libdfu_set_progress_callback_t>>(
            'libdfu_set_progress_callback')
        .asFunction();*/
  }

  void setDownload(String fileName) {
    _set_download(fileName.toNativeUtf8());
  }

  void setAltSetting(int alt) {
    _set_altsetting(alt);
  }

  void setVendProd(int vendorId, int productId) {
    _set_vendprod(vendorId, productId);
  }

  void setDfuseOptions(String options) {
    _set_dfuse_options(options.toNativeUtf8());
  }

  /*static void _onErrorMessage(Pointer<Utf8> error) {
    if (libDFU._onErrorMessageCallback != null) {
      libDFU._onErrorMessageCallback!(error.toDartString());
    }
  }

  static void _onInfoMessage(Pointer<Utf8> message) {
    if (libDFU._onInfoMessageCallback != null) {
      libDFU._onInfoMessageCallback!(message.toDartString());
    }
  }

  static void _onProgress(Pointer<Utf8> state, int progress) {
    if (libDFU._onProgressCallback != null) {
      libDFU._onProgressCallback!(state.toDartString(), progress);
    }
  }*/

  void init() {
    if (_init_dart(NativeApi.initializeApiDLData) == 0) {
      throw "Failed to initialize Dart API for DFU Util";
    }
  }

  Future<int> execute({
    void Function(String msg)? onInfoMessage,
    void Function(String error)? onErrorMessage,
    void Function(String status, int progress)? onProgress,
  }) {
    /*_set_stderr_callback(Pointer.fromFunction(_onErrorMessage));
    _set_stdout_callback(Pointer.fromFunction(_onInfoMessage));
    _set_progress_callback(Pointer.fromFunction(_onProgress));*/
    var completer = Completer<int>();
    _onInfoMessageCallback = onInfoMessage;
    _onErrorMessageCallback = onErrorMessage;
    _onProgressCallback = onProgress;
    //var future = Future<int>();
    _receivePort = ReceivePort()
      ..listen((data) {
        String jsonData = data;
        var json = jsonDecode(jsonData);
        if (json['type'] == 'finish') {
          _receivePort!.close();
          completer.complete(json['code']);
        } else if (json['type'] == 'stdout') {
          if (_onInfoMessageCallback != null) {
            _onInfoMessageCallback!(json['msg']);
          }
        } else if (json['type'] == 'stderr') {
          if (_onErrorMessageCallback != null) {
            _onErrorMessageCallback!(json['msg']);
          }
        } else if (json['type'] == 'progress') {
          if (_onProgressCallback != null) {
            String state = json['state'];
            _onProgressCallback!(state.trim(), json['progress']);
          }
        }
      });
    _execute_dart(_receivePort!.sendPort.nativePort);
    return completer.future;
  }
}

_LibDFU? _cachedLibDFU;
_LibDFU get libDFU => _cachedLibDFU ??= _LibDFU();
