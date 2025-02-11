import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tes/screen/result.dart';

class VerificationHandler {
  static Future<void> handleResponse(
    BuildContext context, 
    Map<String, dynamic> response,
    Uint8List imageBytes
  ) async {
    final bool isSuccess = response['status'] == 'success';
    final bool isReal = response['data']['is_real'] == true;
    final bool isError = response['status'] == 'error';
    final errorCode = response['data']?['error_code'];

    if (!isSuccess || !isReal || isError) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Verification failed'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    !isReal ? 'Spoof detection failed. Please use a real face.' :
                    isError ? 'Face matched with different user (${response['data']['matched_name']})' :
                    response['message'] ?? 'Verification failed',
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (errorCode != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Error Code: $errorCode',
                      style: const TextStyle(fontSize: 14, color: Colors.red),
                    ),
                  ],
                  if (response['data']?['error_details'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Details: ${response['data']['error_details']}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Try Again'),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/cob');
                },
              ),
            ],
          );
        },
      );
    } else {
      // Success case - navigate to result screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            result: response,
            imageBytes: imageBytes,
          ),
        ),
      );
    }
  } 

  static String _getErrorTitle(int? errorCode) {
    if (errorCode != null) {
      if (errorCode >= 400 && errorCode < 500) {
        return 'Request Error ($errorCode)';
      }
      return 'Error ($errorCode)';
    }
    return 'Error Occurred';
  }
}




// class VerificationHandler {
//   static Future<void> handleResponse(
//     BuildContext context,
//     Map<String, dynamic> response,
//     Uint8List imageBytes
//   ) async {
//     final bool isSuccess = response['status'] == 'success';
//     final bool isError = response['status'] == 'error';
//     final errorCode = response['data']?['error_code'];

//     if (!isSuccess || isError) {
//       await showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (BuildContext context) {
//           return AlertDialog(
//             title: Text(_getErrorTitle(errorCode)),
//             content: SingleChildScrollView(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text(
//                     response['message'] ?? 'An error occurred',
//                     style: const TextStyle(fontSize: 16),
//                   ),
//                   if (errorCode != null) ...[
//                     const SizedBox(height: 10),
//                     Text(
//                       'Error Code: $errorCode',
//                       style: const TextStyle(fontSize: 14, color: Colors.red),
//                     ),
//                   ],
//                   if (response['data']?['error_details'] != null) ...[
//                     const SizedBox(height: 8),
//                     Text(
//                       'Details: ${response['data']['error_details']}',
//                       style: const TextStyle(fontSize: 12, color: Colors.grey),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//             actions: [
//               TextButton(
//                 child: const Text('Try Again'),
//                 onPressed: () {
//                   Navigator.of(context).pop();
//                   Navigator.pushReplacementNamed(context, '/home');
//                 },
//               ),
//             ],
//           );
//         },
//       );
//     }else {0   
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (context) => ResultScreen(
//             result: response,
//             imageBytes: imageBytes,
//           ),
//         ),
//       );
//     }
//   }

//   static String _getErrorTitle(int? errorCode) {
//     if (errorCode != null) {
//       if (errorCode >= 400 && errorCode < 500) {
//         return 'Request Error ($errorCode)';
//       }
//       return 'Error ($errorCode)';
//     }
//     return 'Error Occurred';
//   }
// }