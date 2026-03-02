import 'package:flutter/material.dart';
import 'package:travel_app/components/memory_details_view.dart';
import 'package:travel_app/models/memory.dart';
import 'memory_snapshot.dart';

class MemoryByDayList extends StatelessWidget {
  final List<Memory> currentDateMemories;
  final int dateUnformatted;

  const MemoryByDayList({
    super.key,
    required this.currentDateMemories,
    required this.dateUnformatted,
  });

  String formatIntDateWritten(int yyyymmdd) {
    final dateStr = yyyymmdd.toString().padLeft(8, '0');

    final year = int.parse(dateStr.substring(0, 4));
    final month = int.parse(dateStr.substring(4, 6));
    final day = int.parse(dateStr.substring(6, 8));

    final date = DateTime(year, month, day);
    return '${_monthName(date.month)} ${date.day}, ${date.year}';
  }

  String _monthName(int month) {
    const months = [
      '',
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    return months[month];
  }

  Future<void> _showDetailsOverlay(BuildContext context, Memory memory) async {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return MemoryDetailsView(
          memory: memory,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(padding: EdgeInsets.only(top: 30.0)),
        Padding(
          padding: const EdgeInsets.only(left: 10.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              formatIntDateWritten(dateUnformatted),
              style: const TextStyle(fontSize: 18.0),
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: 240,
          ),
          itemCount: currentDateMemories.length,
          itemBuilder: (context, gridIndex) {
            final Memory memory = currentDateMemories[gridIndex];

            return GestureDetector(
              onTap: () => _showDetailsOverlay(context, memory),
              child: MemorySnapshot(memory: memory)
            );
          },
        ),
      ],
    );
  }
}
