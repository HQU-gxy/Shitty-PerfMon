import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shitty_perf_mon/NativeLibWrapper.dart';

import '../windows_system_info/lib/windows_system_info.dart';

class DiskInfoPage extends StatefulWidget {
  DiskInfoPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _DiskInfoPageState();
}

class _DiskInfoPageState extends State<DiskInfoPage> {
  Timer? _timer;
  List<DiskLayoutInfo>? diskInfo;

  List<DriveUsageInfo> driveUsage = [];
  final refreshPeriod = 5;

  Future<void> updateChart() async {
    if (await WindowsSystemInfo.isInitilized) {
      setState(() {
        diskInfo = WindowsSystemInfo.disks;
        driveUsage = getDriveUsageList();
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
            title: Text('Disk Info'),
            content: Column(
                mainAxisSize: MainAxisSize.min,
                children: List<Widget>.generate(
                    diskInfo!.length,
                    (index) => Column(children: [
                          Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text('${diskInfo![index].name}',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold))),
                          Text(
                              'Size: ${(diskInfo![index].size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB'),
                          Text('Interface: ${diskInfo![index].interfaceType}'),
                          Text('S/N: ${diskInfo![index].serialNum}'),
                          Text('SMART Status: ${diskInfo![index].smartStatus}'),
                          Text('Type: ${diskInfo![index].type}')
                        ]))),
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

  Widget getBottomTitles(double value, TitleMeta titleMeta) {
    final txt = driveUsage[value.toInt()].driveLetter;
    return SideTitleWidget(
        child: Text(txt), axisSide: titleMeta.axisSide, space: 2);
  }

  Gradient getGradient() {
    return LinearGradient(
        colors: [
          Colors.greenAccent,
          Colors.blueAccent,
        ],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        tileMode: TileMode.clamp);
  }

  List<BarChartGroupData> getBarGroups() {
    return List.generate(driveUsage.length, (index) {
      return BarChartGroupData(x: index, barRods: [
        BarChartRodData(
            width: 20,
            toY: (driveUsage[index].totalSize - driveUsage[index].freeSpace) /
                driveUsage[index].totalSize *
                100,
            gradient: getGradient())
      ]);
    });
  }

  Widget buildDiskInfoWidget() {
    if (diskInfo == null)
      return Text('Loading...',
          style: TextStyle(fontSize: 24, fontStyle: FontStyle.italic));
    if (diskInfo!.length == 0) {
      return Text('No Disk Found',
          style: TextStyle(fontSize: 24, fontStyle: FontStyle.italic));
    }
    if (driveUsage.length == 0)
      return Text('Loading...',
          style: TextStyle(fontSize: 24, fontStyle: FontStyle.italic));

    return Stack(children: [
      Positioned(
        left: 16,
          top: 8,
          child: Text('Disks',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
      Positioned(
          right: 16,
          top: 8,
          child: TextButton(
            onPressed: () => showDetailedInfo(),
            child: Text('Detail',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          )),
      Padding(
          padding: EdgeInsets.only(top: 64, left: 16, right: 16, bottom: 16),
          child: BarChart(BarChartData(
              gridData: FlGridData(show: false),
              maxY: 100,
              alignment: BarChartAlignment.spaceAround,
              barTouchData: BarTouchData(
                enabled: false,
                touchTooltipData: BarTouchTooltipData(
                  tooltipBgColor: Colors.transparent,
                  tooltipPadding: EdgeInsets.zero,
                  tooltipMargin: 8,
                  getTooltipItem: (
                    BarChartGroupData group,
                    int groupIndex,
                    BarChartRodData rod,
                    int rodIndex,
                  ) {
                    return BarTooltipItem(
                      rod.toY.round().toString(),
                      TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: getBottomTitles),
                ),
                leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (v, m) {
                          return SideTitleWidget(
                              child: Text('${v.toInt()}%'),
                              axisSide: AxisSide.left,
                              space: 2);
                        })),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              barGroups: getBarGroups())))
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return buildDiskInfoWidget();
  }
}
