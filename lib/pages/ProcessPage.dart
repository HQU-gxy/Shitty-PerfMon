import 'dart:async';

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';

import '../NativeLibWrapper.dart';

class ProcessPage extends StatefulWidget {
  ProcessPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ProcessPageState();
}

class _ProcessPageState extends State<ProcessPage> {
  var dataRows = <DataRow>[];
  Timer? _timer;

  void updateList(List<ProcessInfo> pList) {
    setState(() {
      dataRows.clear();
      for (final p in pList) {
        dataRows.add(DataRow(cells: [
          DataCell(Center(child: Text(p.name))),
          DataCell(Center(child: Text(p.pid.toString()))),
          DataCell(Center(child: Text(p.megaBytes.toStringAsFixed(1))))
        ]));
      }
    });
  }

  @override
  void initState() {
    super.initState();
    updateList(getProcessList());
    _timer = Timer.periodic(Duration(seconds: 2), (timer) {
      updateList(getProcessList());
    });
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return DataTable2(
        columnSpacing: 12,
        horizontalMargin: 12,
        minWidth: 600,
        columns: [
          DataColumn2(
              size: ColumnSize.L,
              label: Center(
                  child: Text('Name',
                      style: TextStyle(fontStyle: FontStyle.italic)))),
          DataColumn(
              label: Center(
                  child: Text('PID',
                      style: TextStyle(fontStyle: FontStyle.italic)))),
          DataColumn(
              label: Center(
                  child: Text('Memory Used(MB)',
                      style: TextStyle(fontStyle: FontStyle.italic))))
        ],
        rows: dataRows);
  }
}
