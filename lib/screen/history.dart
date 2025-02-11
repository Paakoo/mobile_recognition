import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'nav_bar.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:intl/date_symbol_data_local.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final storage = FlutterSecureStorage();
  List<Map<String, dynamic>> historyData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null).then((_) {
      fetchHistoryData();
    });
  }

  Future<void> fetchHistoryData() async {
    try {
      final token = await storage.read(key: 'jwt_token');
      final decodedToken = JwtDecoder.decode(token!);
      final userName = decodedToken['sub'];

      final response = await http.get(
        Uri.parse('http://172.20.10.2:5000/api/history?nama=$userName'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          historyData = List<Map<String, dynamic>>.from(data['data']);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load history');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Failed to load history')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Histori Absensi',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue[500],
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[500]!, Colors.blue[50]!],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: fetchHistoryData,
          backgroundColor: Colors.white,
          child: ListView.builder(
            itemCount: historyData.length,
            padding: EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final item = historyData[index];
              final date = DateTime.parse(item['tanggal']);
              final isToday = DateFormat('yyyy-MM-dd').format(date) ==
                  DateFormat('yyyy-MM-dd').format(DateTime.now());

              return Card(
                margin: EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: isToday ? Colors.blue[700]! : Colors.transparent,
                      width: isToday ? 2 : 0,
                    ),
                  ),
                  child: Column(
                    children: [
                      if (isToday)
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue[700],
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(13),
                              topRight: Radius.circular(13),
                            ),
                          ),
                          child: Text(
                            'Hari Ini',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(date),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                // _buildStatusBadge(item['work_type']),
                              ],
                            ),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                _buildInfoItem(
                                  Icons.access_time,
                                  item['jam'],
                                  Colors.blue[700]!,
                                ),
                                SizedBox(width: 24),
                                _buildInfoItem(
                                  Icons.home_work,
                                  item['work_type'],
                                  Colors.green[700]!,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: NavBar(currentIndex: 1),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = status == 'WFO' ? Colors.green : Colors.orange;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text, Color color) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }
}