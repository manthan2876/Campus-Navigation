import 'package:flutter/material.dart';

class DirectionsBottomSheet extends StatelessWidget {
  final List<String> instructions;
  final String startLocation;
  final String endLocation;

  const DirectionsBottomSheet({
    super.key,
    required this.instructions,
    required this.startLocation,
    required this.endLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          // Handle bar
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                const Icon(Icons.directions_walk, color: Colors.blueAccent, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'To $endLocation',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'From $startLocation',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 30),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              itemCount: instructions.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                // simple icon logic based on instruction text
                IconData icon = Icons.straight;
                Color iconColor = Colors.black54;
                if (instructions[index].toLowerCase().contains("stairs") || instructions[index].toLowerCase().contains("elevator")) {
                  icon = Icons.elevator;
                  iconColor = Colors.orange;
                } else if (instructions[index].toLowerCase().contains("enter")) {
                  icon = Icons.meeting_room;
                  iconColor = Colors.green;
                } else if (instructions[index].toLowerCase().contains("exit")) {
                  icon = Icons.exit_to_app;
                  iconColor = Colors.redAccent;
                } else if (instructions[index].toLowerCase().contains("destination")) {
                  icon = Icons.flag;
                  iconColor = Colors.red;
                }

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor),
                  ),
                  title: Text(
                    instructions[index],
                    style: const TextStyle(fontSize: 16),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
