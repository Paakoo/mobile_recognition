import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ResultScreen extends StatelessWidget {
  final Map<String, dynamic> result;
  final Uint8List imageBytes;

  const ResultScreen({
    Key? key, 
    required this.result,
    required this.imageBytes,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isSuccess = result['status'] == 'success';

    return Scaffold(
      appBar: AppBar(
        title: Text('Verification Result'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.memory(
              imageBytes,
              height: 300,
              fit: BoxFit.cover,
            ),
            SizedBox(height: 20),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Status: ${result['status']?.toUpperCase() ?? 'Unknown'}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: isSuccess ? Colors.green : Colors.red,
                      ),
                    ),
                    SizedBox(height: 10),
                    if (isSuccess) ...[
                      Text(
                        'Name: ${result['name'] ?? 'Unknown'}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Confidence: ${(result['confidence'] * 100).toStringAsFixed(2)}%',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                    SizedBox(height: 10),
                    Text(
                      result['message'] ?? '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isSuccess ? null : Colors.red,
                        fontWeight: isSuccess ? null : FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Processing Times:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 10),
                    if (result['timing'] != null) ...[
                      _buildTimingRow('Detection', result['timing']['detection']),
                      _buildTimingRow('Embedding', result['timing']['embedding']),
                      _buildTimingRow('Matching', result['timing']['matching']),
                      _buildTimingRow('Processing', result['timing']['processing']),
                      Divider(),
                      _buildTimingRow('Total Time', result['timing']['total'], 
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimingRow(String label, String? value, {TextStyle? style}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value ?? '-', style: style),
        ],
      ),
    );
  }
}
