import 'dart:ffi';

import 'package:ffi/ffi.dart';

final wmiLib = DynamicLibrary.open('dll/WMIFucker.dll');

final class ProcessInfoNative extends Struct {
  external Pointer<Utf8> name;
  @Int()
  external int pid;
  @Int()
  external int bytes;
}

final class CPUInfoNative extends Struct {
  @Uint8()
  external int nCores;
  @Uint8()
  external int totalUsage;
  external Pointer<Uint8> coreUsages;
}

final class ProcessInfo {
  ProcessInfo(this.name, this.pid, this.megaBytes);

  final String name;
  final int pid;
  final double megaBytes;
}

final class CpuUsageInfo {
  CpuUsageInfo(this.nCores, this.totalUsage, this.coreUsages);

  final int nCores;
  final int totalUsage;
  final List<int> coreUsages;
}

final wmiFuckerInit =
    wmiLib.lookupFunction<Void Function(), void Function()>('init');

final getProcessNative = wmiLib.lookupFunction<
    Uint32 Function(Pointer<Pointer<ProcessInfoNative>>),
    int Function(Pointer<Pointer<ProcessInfoNative>>)>('getProcesses');

final getMemoryUsageNative =
    wmiLib.lookupFunction<Uint64 Function(), int Function()>('getMemUsage');

final getCpuUsageNative = wmiLib.lookupFunction<
    Bool Function(Pointer<CPUInfoNative>),
    bool Function(Pointer<CPUInfoNative>)>('getCpuUsage');

double getMemoryUsageInGB() {
  return getMemoryUsageNative() / (1024 * 1024 * 1024);
}

/// coreNum == -1 => total usage
CpuUsageInfo? getCpuUsage() {
  Pointer<CPUInfoNative> pInfo = Arena().call();

  bool suc = getCpuUsageNative(pInfo);
  if (!suc) return null;

  final coreUsages = <int>[];
  for (var i = 0; i < pInfo.ref.nCores; i++) {
    coreUsages.add(pInfo.ref.coreUsages.elementAt(i).value);
  }

  return CpuUsageInfo(pInfo.ref.nCores, pInfo.ref.totalUsage, coreUsages);
}

List<ProcessInfo> getProcessList() {
  Pointer<Pointer<ProcessInfoNative>> ppList = Arena().call();
  final processes = <ProcessInfo>[];

  int np = getProcessNative(ppList);
  for (var a = 0; a < np; a++) {
    final p = ppList.value.elementAt(a).ref;
    if (p.pid != 0)
      processes.add(ProcessInfo(p.name.toDartString(), p.pid,
          p.bytes.toUnsigned(32) / (1024 * 1024)));
  }

  return processes;
}
