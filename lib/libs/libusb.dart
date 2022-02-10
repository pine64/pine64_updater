import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

class _LibUSBContext extends Opaque {}

class _LibUSBDevice extends Opaque {}

class _LibUSBDeviceHandle extends Opaque {}

typedef _libusb_init_t = Int32 Function(Pointer<Pointer<_LibUSBContext>> ctx);
typedef _libusb_get_device_list_t = Int64 Function(
    Pointer<_LibUSBContext> ctx, Pointer<Pointer<Pointer<_LibUSBDevice>>> list);
typedef _libusb_free_device_list_t = Void Function(
    Pointer<Pointer<_LibUSBDevice>> list, Int32 unref_devices);
typedef _libusb_get_device_descriptor_t = Int32 Function(
    Pointer<_LibUSBDevice> device, Pointer<_LibUSBDeviceDescriptor> descriptor);
typedef _libusb_open_t = Int32 Function(Pointer<_LibUSBDevice> device,
    Pointer<Pointer<_LibUSBDeviceHandle>> deviceHandle);
typedef _libusb_close_t = Int32 Function(
    Pointer<_LibUSBDeviceHandle> deviceHandle);

class _LibUSBDeviceDescriptor extends Struct {
  @Uint8()
  external int bLength;
  @Uint8()
  external int bDescriptorType;
  @Uint16()
  external int bcdUSB;
  @Uint8()
  external int bDeviceClass;
  @Uint8()
  external int bDeviceSubClass;
  @Uint8()
  external int bDeviceProtocol;
  @Uint8()
  external int bMaxPacketSize0;
  @Uint16()
  external int idVendor;
  @Uint16()
  external int idProduct;
  @Uint16()
  external int bcdDevice;
  @Uint8()
  external int iManufacturer;
  @Uint8()
  external int iProduct;
  @Uint8()
  external int iSerialNumber;
  @Uint8()
  external int bNumConfigurations;
}

class LibUSBDeviceDescriptor {
  final int idVendor;
  final int idProduct;

  LibUSBDeviceDescriptor.fromStruct(_LibUSBDeviceDescriptor struct)
    : idVendor = struct.idVendor,
      idProduct = struct.idProduct;
}

class LibUSBDeviceList {
  Pointer<Pointer<_LibUSBDevice>> _devicesPtr;
  late List<Pointer<_LibUSBDevice>> _devices;
  List<Pointer<_LibUSBDevice>> get devices => _devices;

  LibUSBDeviceList(this._devicesPtr, int count) {
    _devices = List<Pointer<_LibUSBDevice>>.generate(
        count, (index) => _devicesPtr[index]);
  }

  void free([bool unrefDevices = true]) {
    libUSB._free_device_list(_devicesPtr, unrefDevices ? 1 : 0);
  }
}

class LibUSBException implements Exception {
  String _message;
  int code;

  LibUSBException([this._message = 'Unknown LibUSB error', this.code = 0]);

  @override
  String toString() {
    return _message;
  }
}

const int LIBUSB_SUCCESS = 0;
const int LIBUSB_ERROR_IO = -1;
const int LIBUSB_ERROR_INVALID_PARAM = -2;
const int LIBUSB_ERROR_ACCESS = -3;
const int LIBUSB_ERROR_NO_DEVICE = -4;
const int LIBUSB_ERROR_NOT_FOUND = -5;
const int LIBUSB_ERROR_BUSY = -6;
const int LIBUSB_ERROR_TIMEOUT = -7;
const int LIBUSB_ERROR_OVERFLOW = -8;
const int LIBUSB_ERROR_PIPE = -9;
const int LIBUSB_ERROR_INTERRUPTED = -10;
const int LIBUSB_ERROR_NO_MEM = -11;
const int LIBUSB_ERROR_NOT_SUPPORTED = -12;
const int LIBUSB_ERROR_OTHER = -99;

class _LibUSB {
  late final DynamicLibrary _dyLib;
  late final int Function(Pointer<Pointer<_LibUSBContext>> ctx) _init;
  late final int Function(Pointer<_LibUSBContext> ctx,
      Pointer<Pointer<Pointer<_LibUSBDevice>>> list) _get_device_list;
  late final void Function(
          Pointer<Pointer<_LibUSBDevice>> list, int unref_devices)
      _free_device_list;
  late final int Function(Pointer<_LibUSBDevice> device,
      Pointer<_LibUSBDeviceDescriptor> descriptor) _get_device_descriptor;
  late final int Function(Pointer<_LibUSBDevice> device,
      Pointer<Pointer<_LibUSBDeviceHandle>> deviceHandle) _open;
  late final int Function(Pointer<_LibUSBDeviceHandle> deviceHandle) _close;
  late final Pointer<_LibUSBContext> _context;
  bool _initialized = false;
  bool get initialized => _initialized;

  _LibUSB() {
    if (Platform.isWindows) {
      _dyLib = DynamicLibrary.open('${Directory.current.path}/libusb-1.0.dll');
    } else if (Platform.isMacOS) {
      _dyLib = DynamicLibrary.open('libusb-1.0.0.dylib');
    }
    _init = _dyLib
        .lookup<NativeFunction<_libusb_init_t>>('libusb_init')
        .asFunction();
    _get_device_list = _dyLib
        .lookup<NativeFunction<_libusb_get_device_list_t>>(
            'libusb_get_device_list')
        .asFunction();
    _free_device_list = _dyLib
        .lookup<NativeFunction<_libusb_free_device_list_t>>(
            'libusb_free_device_list')
        .asFunction();
    _get_device_descriptor = _dyLib
        .lookup<NativeFunction<_libusb_get_device_descriptor_t>>(
            'libusb_get_device_descriptor')
        .asFunction();
    _open = _dyLib
        .lookup<NativeFunction<_libusb_open_t>>('libusb_open')
        .asFunction();
    _close = _dyLib
        .lookup<NativeFunction<_libusb_close_t>>('libusb_close')
        .asFunction();
  }

  void init() {
    Pointer<Pointer<_LibUSBContext>> ctx = calloc();
    int err = _init(ctx);
    _context = ctx.value;
    calloc.free(ctx);
    if (err < 0) {
      throw LibUSBException('LibUSB init failed', err);
    }
    _initialized = true;
  }

  LibUSBDeviceList getDevicesList() {
    Pointer<Pointer<Pointer<_LibUSBDevice>>> list = calloc();
    int count = _get_device_list(_context, list);
    if (count < 0) {
      throw LibUSBException('LibUSB get device list failed', count);
    }
    final finalList = LibUSBDeviceList(list.value, count);
    calloc.free(list);
    return finalList;
  }

  LibUSBDeviceDescriptor getDeviceDescriptor(Pointer<_LibUSBDevice> device) {
    final descriptorPtr = calloc<_LibUSBDeviceDescriptor>();
    int err = _get_device_descriptor(device, descriptorPtr);
    if (err < 0) {
      throw LibUSBException('LibUSB get device descriptor failed', err);
    }
    final descriptorStruct = descriptorPtr.ref;
    final descriptor = LibUSBDeviceDescriptor.fromStruct(descriptorStruct);
    calloc.free(descriptorPtr);
    return descriptor;
  }

  Pointer<_LibUSBDeviceHandle> open(Pointer<_LibUSBDevice> device) {
    Pointer<Pointer<_LibUSBDeviceHandle>> deviceHandle = calloc();
    int resp = _open(device, deviceHandle);
    if (resp < 0) {
      throw LibUSBException("Failed to open device", resp);
    }
    final handle = deviceHandle.value;
    calloc.free(deviceHandle);
    return handle;
  }

  void close(Pointer<_LibUSBDeviceHandle> deviceHandle) {
    _close(deviceHandle);
  }
}

_LibUSB? _cachedLibUSB;
_LibUSB get libUSB => _cachedLibUSB ??= _LibUSB();
