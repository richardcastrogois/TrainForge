import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../nutrition/presentation/food_offline_labels.dart';
import '../data/local_food_repository.dart';

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});
  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  final controller = MobileScannerController(
    formats: [
      BarcodeFormat.ean8,
      BarcodeFormat.ean13,
      BarcodeFormat.upcA,
      BarcodeFormat.itf14,
    ],
  );
  final manual = TextEditingController();
  bool returned = false;
  void select(String? value) {
    if (returned || value == null || !LocalFoodRepository.validBarcode(value)) {
      return;
    }
    returned = true;
    Navigator.pop(context, value);
  }

  @override
  void dispose() {
    controller.dispose();
    manual.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(foodOfflineLabel(context, 'scan'))),
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(foodOfflineLabel(context, 'scanHint')),
          ),
          Expanded(
            child: MobileScanner(
              controller: controller,
              onDetect: (capture) {
                for (final barcode in capture.barcodes) {
                  select(barcode.rawValue);
                }
              },
              errorBuilder: (context, error) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(foodOfflineLabel(context, 'scanUnavailable')),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: manual,
              keyboardType: TextInputType.number,
              maxLength: 14,
              decoration: InputDecoration(
                labelText: foodOfflineLabel(context, 'barcode'),
                suffixIcon: IconButton(
                  onPressed: () => select(manual.text.trim()),
                  icon: const Icon(Icons.search),
                ),
              ),
              onSubmitted: (value) => select(value.trim()),
            ),
          ),
        ],
      ),
    ),
  );
}
