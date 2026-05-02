import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

class TurboLinkEngine {
  static late final DynamicLibrary _lib;

  static late final int Function() _tlInit;
  static late final void Function() _tlShutdown;
  static late final void Function(int) _tlSetFecMode;
  static late final int Function() _tlGetFecMode;
  static late final void Function(int) _tlCancelTransfer;
  static late final void Function() _tlCancelAll;
  
  static late final int Function(int, Pointer<Double>, Pointer<Double>) _tlGetStats;

  static late final int Function(
    int transferId,
    int fd,
    int fileSize,
    Pointer<Utf8> fileName,
    Pointer<Utf8> peerIp,
    int peerPort,
    Pointer<Uint8> key,
    Pointer<NativeFunction<Void Function(Int64, Int64, Double)>> onProgress,
    Pointer<NativeFunction<Void Function(Pointer<Utf8>)>> onError,
  ) _tlSendFile;

  static late final int Function(
    int transferId,
    int listenPort,
    Pointer<Utf8> saveDir,
    Pointer<Uint8> key,
    Pointer<NativeFunction<Void Function(Int64, Int64, Double)>> onProgress,
    Pointer<NativeFunction<Void Function(Pointer<Utf8>)>> onComplete,
    Pointer<NativeFunction<Void Function(Pointer<Utf8>)>> onError,
  ) _tlReceiveFile;

  static bool _initialized = false;

  static void init() {
    if (_initialized) return;

    if (!Platform.isAndroid) {
      _initialized = true;
      return;
    }

    _lib = DynamicLibrary.open('libturbolink_engine.so');

    _tlInit = _lib.lookupFunction<Int32 Function(), int Function()>('tl_engine_init');
    _tlShutdown = _lib.lookupFunction<Void Function(), void Function()>('tl_engine_shutdown');
    _tlSetFecMode = _lib.lookupFunction<Void Function(Int32), void Function(int)>('tl_set_fec_mode');
    _tlGetFecMode = _lib.lookupFunction<Int32 Function(), int Function()>('tl_get_fec_mode');
    _tlCancelTransfer = _lib.lookupFunction<Void Function(Int32), void Function(int)>('tl_cancel_transfer');
    _tlCancelAll = _lib.lookupFunction<Void Function(), void Function()>('tl_cancel_all');
    
    _tlGetStats = _lib.lookupFunction<
        Int32 Function(Int32, Pointer<Double>, Pointer<Double>),
        int Function(int, Pointer<Double>, Pointer<Double>)
    >('tl_get_stats');

    _tlSendFile = _lib.lookupFunction<
        Int32 Function(Int32, Int32, Int64, Pointer<Utf8>, Pointer<Utf8>, Uint16, Pointer<Uint8>, Pointer<NativeFunction<Void Function(Int64, Int64, Double)>>, Pointer<NativeFunction<Void Function(Pointer<Utf8>)>>),
        int Function(int, int, int, Pointer<Utf8>, Pointer<Utf8>, int, Pointer<Uint8>, Pointer<NativeFunction<Void Function(Int64, Int64, Double)>>, Pointer<NativeFunction<Void Function(Pointer<Utf8>)>>)
    >('tl_send_file');

    _tlReceiveFile = _lib.lookupFunction<
        Int32 Function(Int32, Uint16, Pointer<Utf8>, Pointer<Uint8>, Pointer<NativeFunction<Void Function(Int64, Int64, Double)>>, Pointer<NativeFunction<Void Function(Pointer<Utf8>)>>, Pointer<NativeFunction<Void Function(Pointer<Utf8>)>>),
        int Function(int, int, Pointer<Utf8>, Pointer<Uint8>, Pointer<NativeFunction<Void Function(Int64, Int64, Double)>>, Pointer<NativeFunction<Void Function(Pointer<Utf8>)>>, Pointer<NativeFunction<Void Function(Pointer<Utf8>)>>)
    >('tl_receive_file');

    _tlInit();
    _initialized = true;
  }

  static void shutdown() {
    if (Platform.isAndroid && _initialized) {
      _tlShutdown();
    }
  }

  static void setFecMode(int mode) {
    if (Platform.isAndroid && _initialized) {
      _tlSetFecMode(mode);
    }
  }

  static int getFecMode() {
    if (Platform.isAndroid && _initialized) {
      return _tlGetFecMode();
    }
    return 0;
  }

  static void cancelTransfer(int transferId) {
    if (Platform.isAndroid && _initialized) {
      _tlCancelTransfer(transferId);
    }
  }

  static int getStats(int transferId, Pointer<Double> outProgress, Pointer<Double> outSpeed) {
    if (Platform.isAndroid && _initialized) {
      return _tlGetStats(transferId, outProgress, outSpeed);
    }
    return -1;
  }

  static int sendFile(
    int transferId,
    int fd,
    int fileSize,
    Pointer<Utf8> fileName,
    Pointer<Utf8> peerIp,
    int peerPort,
    Pointer<Uint8> key,
    Pointer<NativeFunction<Void Function(Int64, Int64, Double)>> onProgress,
    Pointer<NativeFunction<Void Function(Pointer<Utf8>)>> onError,
  ) {
    if (Platform.isAndroid && _initialized) {
      return _tlSendFile(transferId, fd, fileSize, fileName, peerIp, peerPort, key, onProgress, onError);
    }
    return -1;
  }

  static int receiveFile(
    int transferId,
    int listenPort,
    Pointer<Utf8> saveDir,
    Pointer<Uint8> key,
    Pointer<NativeFunction<Void Function(Int64, Int64, Double)>> onProgress,
    Pointer<NativeFunction<Void Function(Pointer<Utf8>)>> onComplete,
    Pointer<NativeFunction<Void Function(Pointer<Utf8>)>> onError,
  ) {
    if (Platform.isAndroid && _initialized) {
      return _tlReceiveFile(transferId, listenPort, saveDir, key, onProgress, onComplete, onError);
    }
    return -1;
  }
}
