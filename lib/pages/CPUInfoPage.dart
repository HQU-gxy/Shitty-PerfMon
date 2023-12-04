import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../NativeLibWrapper.dart';
import '../windows_system_info/lib/windows_system_info.dart';

class CPUInfoPage extends StatefulWidget {
  CPUInfoPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _CPUInfoPageState();
}

class _CPUInfoPageState extends State<CPUInfoPage> {
  Timer? _timer;
  CpuInfo? cpuInfo;

  List<CpuUsageInfo> cpuUsage = [];

  final nSpots = 30;
  final refreshPeriod = 2;

  var showOverallUsage = true;

  Future<void> updateChart() async {
    if (await WindowsSystemInfo.isInitilized) {
      setState(() {
        final usageInfo = getCpuUsage();
        if (usageInfo != null) {
          if (cpuUsage.length > nSpots) cpuUsage.removeAt(0);
          cpuUsage.add(usageInfo);
          cpuInfo = WindowsSystemInfo.cpu;
        }
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

  void showDetailedInfo() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('CPU Info'),
            content: cpuInfo == null
                ? Text('Loading...',
                    style: TextStyle(fontSize: 20, fontStyle: FontStyle.italic))
                : Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('Vendor: ${cpuInfo!.vendor}'),
                    Text('Clock Speed: ${cpuInfo!.speed} MHz'),
                    Text('Logical Cores: ${cpuInfo!.cores}'),
                    Text('Physical Cores: ${cpuInfo!.physicalCores}'),
                  ]),
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

  ///coreIndex == -1 means overall usage
  LineChartData getLineChartData(int coreIndex) {
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
              axisNameSize: 20),
          leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: 25,
              ),
              axisNameWidget: Text('CPU Usage (%)'),
              axisNameSize: 20),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: const Color(0xff37434d), width: 1),
        ),
        minX: -(nSpots * refreshPeriod).toDouble(),
        maxX: 0,
        minY: 0,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
              spots: List<FlSpot>.generate(
                  cpuUsage.length,
                  (index) => FlSpot(
                      refreshPeriod * (index.toDouble() - cpuUsage.length + 1),
                      coreIndex == -1
                          ? cpuUsage[index].totalUsage.toDouble()
                          : cpuUsage[index].coreUsages[coreIndex].toDouble())),
              isCurved: true,
              dotData: FlDotData(show: false),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.blue,
                  Colors.blue.withOpacity(0.2),
                ],
              ),
              barWidth: 3,
              belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue,
                      Colors.green,
                    ].map((e) => e.withOpacity(0.5)).toList(),
                  )))
        ]);
  }

  Widget buildLineChart() {
    return showOverallUsage
        ? LineChart(getLineChartData(-1))
        : GridView.count(
            crossAxisCount: 4,
            children: List.generate(cpuUsage[0].nCores, (index) {
              return LineChart(getLineChartData(index));
            }));
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    // return LineChart(data)
    return Stack(children: [
      Positioned(
          right: 16,
          top: 16,
          child: TextButton(
            onPressed: showDetailedInfo,
            child: Text('Detail',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          )),
      Padding(
          padding: const EdgeInsets.only(left: 16, top: 16, bottom: 16),
          child: Text(
            cpuInfo == null ? "Loading..." : cpuInfo!.brand,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          )),
      Padding(
          padding:
              const EdgeInsets.only(left: 16, top: 80, right: 64, bottom: 64),
          child: buildLineChart()),
      Positioned(
          bottom: 16,
          right: 16,
          child: TextButton(
              style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(
                      Colors.cyanAccent.withOpacity(0.2))),
              onPressed: () => {
                    setState(() {
                      showOverallUsage = !showOverallUsage;
                    })
                  },
              child: Text(
                  showOverallUsage
                      ? "Show Per Core Usage"
                      : "Show Overall Usage",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))))
    ]);
  }
}
