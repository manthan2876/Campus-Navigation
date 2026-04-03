import 'package:flutter/material.dart';

class SearchBottomSheet extends StatefulWidget {
  final Map<String, int> endpoints;
  final String? initialStart;
  final String? initialEnd;
  final Function(String? start, String? end) onRouteSelected;

  const SearchBottomSheet({
    super.key,
    required this.endpoints,
    this.initialStart,
    this.initialEnd,
    required this.onRouteSelected,
  });

  @override
  State<SearchBottomSheet> createState() => _SearchBottomSheetState();
}

class _SearchBottomSheetState extends State<SearchBottomSheet> {
  late TextEditingController _startController;
  late TextEditingController _endController;

  @override
  void initState() {
    super.initState();
    _startController = TextEditingController(text: widget.initialStart ?? "");
    _endController = TextEditingController(text: widget.initialEnd ?? "");
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Directions",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildAutocompleteRow("From", _startController, Icons.my_location, Colors.blue),
            const SizedBox(height: 16),
            _buildAutocompleteRow("To", _endController, Icons.location_on, Colors.red),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onRouteSelected(_startController.text, _endController.text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Find Route",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutocompleteRow(String label, TextEditingController controller, IconData icon, Color iconColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          Expanded(
            child: Autocomplete<String>(
              initialValue: TextEditingValue(text: controller.text),
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return widget.endpoints.keys.take(5);
                }
                return widget.endpoints.keys.where((String option) {
                  return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                });
              },
              onSelected: (String selection) {
                controller.text = selection;
              },
              fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                // Keep controllers in sync
                textEditingController.addListener(() {
                  if (controller.text != textEditingController.text) {
                     controller.text = textEditingController.text;
                  }
                });
                // Initialize field value
                if (textEditingController.text != controller.text) {
                   textEditingController.text = controller.text;
                }
                return TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: label,
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
