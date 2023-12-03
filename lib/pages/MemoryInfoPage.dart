import 'dart:async';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shitty_perf_mon/WMIFuckerWrapper.dart';

import '../windows_system_info/lib/windows_system_info.dart';

class MemoryInfoPage extends StatefulWidget {
  MemoryInfoPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MemoryInfoPageState();
}

class _MemoryInfoPageState extends State<MemoryInfoPage> {
  Timer? _timer;
  List<MemoryInfo>? memInfo;
  double memorySize = 0;
  List<double> memoryUsage = [];

  final nSpots = 30;
  final refreshPeriod = 2;

  double calcMemSize(List<MemoryInfo> memInfo) {
    int size = 0;
    for (var mem in memInfo) {
      size += mem.size;
    }
    return size / (1024 * 1024 * 1024);
  }

  Future<void> updateChart() async {
    if (await WindowsSystemInfo.isInitilized) {
      setState(() {
        if (memoryUsage.length > nSpots) memoryUsage.removeAt(0);
        memoryUsage.add(getMemoryUsageInGB());

        memInfo = WindowsSystemInfo.memories;
        if (memInfo != null) memorySize = calcMemSize(memInfo!);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    updateChart();
    _timer = Timer.periodic(Duration(seconds: refreshPeriod), (timer) {
      updateChart();
    });
  }

  LineChartData getLineChartData() {
    return LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: const Color(0xff37434d),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: const Color(0xff37434d),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
            show: true,
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 10,
              ),
              axisNameWidget: Text('Time (s)'),
              axisNameSize: 20,
            ),
            leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  interval: memorySize * 2.floor() / 10,
                ),
                axisNameWidget: Text('Memory Used (GB)'),
                axisNameSize: 20)),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: const Color(0xff37434d), width: 1),
        ),
        minX: -60,
        maxX: 0,
        minY: 0,
        maxY: memorySize * 10.floor() / 10,
        lineBarsData: [
          LineChartBarData(
              spots: List<FlSpot>.generate(
                  memoryUsage.length,
                  (index) => FlSpot(
                      refreshPeriod *
                          (index.toDouble() - memoryUsage.length + 1),
                      memoryUsage[index])),
              isCurved: true,
              dotData: FlDotData(show: false),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.amberAccent,
                  Colors.amberAccent.withOpacity(0.2),
                ],
              ),
              barWidth: 3,
              belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      Colors.limeAccent,
                      Colors.orange,
                    ].map((e) => e.withOpacity(0.5)).toList(),
                  )))
        ]);
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
  }

  void showDetailedInfo() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Memory Info'),
            content: memInfo == null
                ? Text('Loading...',
                    style: TextStyle(fontSize: 20, fontStyle: FontStyle.italic))
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                          Center(
                              child: Text('Slots: ${memInfo!.length}',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold))),
                        ] +
                        List<Widget>.generate(
                            memInfo!.length,
                            (index) => Text(
                                  'Slot ${index + 1}: ${memInfo![index].manufacturer} ${memInfo![index].partNum}'
                                  '   ${(memInfo![index].size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB'
                                  '   ${memInfo![index].clockSpeed} MHz',
                                ))),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('OK'))
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    // return LineChart(data)
    return Stack(
      children: [
        Padding(
            padding: const EdgeInsets.only(left: 16, top: 16, bottom: 16),
            child: Text(
              memInfo == null
                  ? 'Loading...'
                  : 'Memory\t${memorySize.toStringAsFixed(1)} GB',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            )),
        Positioned(
            right: 16,
            top: 16,
            child: TextButton(
              onPressed: showDetailedInfo,
              child: Text('Detail',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            )),
        Padding(
            padding:
                const EdgeInsets.only(left: 16, top: 80, right: 64, bottom: 64),
            child: LineChart(getLineChartData())),
      ],
    );
  }
}
