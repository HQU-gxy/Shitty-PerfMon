import 'dart:async';
import 'package:flutter/material.dart';

import 'package:shitty_perf_mon/NativeLibWrapper.dart';
import 'package:shitty_perf_mon/pages/CPUInfoPage.dart';
import 'package:shitty_perf_mon/pages/DiskInfoPage.dart';
import 'package:shitty_perf_mon/pages/MemoryInfoPage.dart';
import 'package:shitty_perf_mon/pages/ProcessPage.dart';

import 'windows_system_info/lib/windows_system_info.dart';

void main() {
  wmiFuckerInit();
  initSystemInfo();
  runApp(MyApp());
}

Future<void> initSystemInfo() async {
  await WindowsSystemInfo.initWindowsInfo(requiredValues: [
    WindowsSystemInfoFeat.cpu,
    WindowsSystemInfoFeat.memory,
    WindowsSystemInfoFeat.diskLayout
  ]);
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shitty PerfMon',

      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: DefaultTabController(
        length: 4,
        child: Scaffold(
            appBar: AppBar(
              title: const Text('Shitty PerfMon'),
              bottom: const TabBar(tabs: [
                Tab(text: "Processes"),
                Tab(text: "CPU"),
                Tab(text: "Memory"),
                Tab(text: "Disk")
              ]),
            ),
            body: TabBarView(
                children: [ProcessPage(), CPUInfoPage(), MemoryInfoPage(), DiskInfoPage()])),
      ),
    );
  }
}
