import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travel_app/models/memory.dart';
import 'package:travel_app/provider/memory_provider.dart';
import 'package:travel_app/pages/add_memory_page.dart';

class MemoryDetailsView extends StatelessWidget {
  final Memory memory;

  const MemoryDetailsView({
    super.key,
    required this.memory,
  });

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double desiredWidth = screenSize.width * 0.85;
    final double desiredHeight = screenSize.height * 0.65;

    return Center(
      child: SizedBox(
        width: desiredWidth,
        height: desiredHeight,
        child: Material(
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: 1 / 1,
                child: _buildMemoryImage(memory),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        memory.caption,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        memory.description,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context); // close dialog
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddMemoryPage(existing: memory),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_outlined),
                  ),

                  IconButton(
                    onPressed: () async {
                      final provider = context.read<MemoryProvider>();
                      await provider.deleteMemory(memory); // pass the Memory object
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -----------------------------
  // Helper method to show image
  // -----------------------------
  Widget _buildMemoryImage(Memory memory) {
    if (memory.imageUrl.isNotEmpty) {
      return Image.network(
        memory.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
      );
    }

    if (memory.localImagePath.isNotEmpty && File(memory.localImagePath).existsSync()) {
      return Image.file(
        File(memory.localImagePath),
        fit: BoxFit.cover,
      );
    }

    return Container(
      color: Colors.grey[200],
      alignment: Alignment.center,
      child: const Icon(Icons.image, size: 50, color: Colors.grey),
    );
  }
}