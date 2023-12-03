import 'dart:async';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shitty_perf_mon/WMIFuckerWrapper.dart';

import '../windows_system_info/lib/windows_system_info.dart';

class DiskInfoPage extends StatefulWidget {
  DiskInfoPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _DiskInfoPageState();
}

class _DiskInfoPageState extends State<DiskInfoPage> {
  Timer? _timer;
  List<DiskLayoutInfo>? diskInfo;

  final refreshPeriod = 5;

  Future<void> updateChart() async {
    if (await WindowsSystemInfo.isInitilized) {
      setState(() {
        diskInfo = WindowsSystemInfo.disks;
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

  void showDetailedInfo(int index) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Disk Info'),
            content: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
              Center(
                  child: Text('${diskInfo![index].name}',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold))),
              Text(
                  'Size: ${(diskInfo![index].size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB'),
              Text('Interface: ${diskInfo![index].interfaceType}'),
              Text('S/N: ${diskInfo![index].serialNum}'),
              Text('SMART Status: ${diskInfo![index].smartStatus}')
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

  Widget getTitles(double value, TitleMeta titleMeta) {
    final txt = 'Title ${value.toInt()}';
    return SideTitleWidget(
        child: Text(txt), axisSide: titleMeta.axisSide, space: 2);
  }

  Gradient getGradient() {
    return LinearGradient(
        colors: [
          Colors.greenAccent,
          Colors.blueAccent,
          Colors.yellowAccent,
        ],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        tileMode: TileMode.clamp);
  }

  List<BarChartGroupData> getBarGroups() {
    return List.generate(10, (index) {
      return BarChartGroupData(x: index, barRods: [
        BarChartRodData(
            width: 20,
            toY: Random().nextDouble() * 100,
            gradient: getGradient())
      ]);
    });
  }

  Widget buildDiskInfoWidget() {
    if (diskInfo!.length == 0) {
      return Text('No Disk Found');
    }
    return Stack(children: [
      Text('Disks',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      Positioned(
          right: 16,
          top: 8,
          child: TextButton(
            onPressed: () => showDetailedInfo(0),
            child: Text('Detail',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          )),
      Padding(
          padding: EdgeInsets.only(top: 64, left: 16, right: 16, bottom: 16),
          child: BarChart(
              BarChartData(
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
                      getTitlesWidget: getTitles),
                ),
                leftTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
