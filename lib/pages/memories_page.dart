import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travel_app/components/memories_by_day_list.dart';
import 'package:travel_app/provider/memory_provider.dart';
import '../models/memory.dart';

class MemoriesPage extends StatefulWidget {
  const MemoriesPage({super.key});

  @override
  State<MemoriesPage> createState() => _MemoriesPageState();
}

class _MemoriesPageState extends State<MemoriesPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<MemoryProvider>(
      builder: (context, provider, child) {
        final List<Memory> memories = provider.memoryList;

        // Build grouping from provider list
        final Map<int, List<Memory>> unsortedMemoryList = {};

        for (final m in memories) {
          final int key = (m.assignedAt.year * 10000) + (m.assignedAt.month * 100) + m.assignedAt.day;
          (unsortedMemoryList[key] ??= []).add(m);

          // debug
          // print(m); // useful if you override toString()
          // print('${m.caption} ${m.date}');
        }

        final sortedDateKeys = unsortedMemoryList.keys.toList()..sort();

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: ListView.builder(
              itemCount: sortedDateKeys.length,
              itemBuilder: (context, index) {
                final dateKey = sortedDateKeys[index];
                final currentDate = unsortedMemoryList[dateKey]!;
                return MemoryByDayList(
                  currentDateMemories: currentDate,
                  dateUnformatted: dateKey,
                );
              },
            ),
          ),
        );
      },
    );
  }
}


