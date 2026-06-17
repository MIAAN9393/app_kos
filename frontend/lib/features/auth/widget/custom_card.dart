import 'package:flutter/material.dart';

class AuthCard extends StatelessWidget {
  final List<Widget> children; // Untuk menampung banyak input/tombol
  final String title;

  const AuthCard({
    super.key, 
    required this.children, 
    required this.title
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Kartu fleksibel sesuai isi
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ...children, // Memasukkan list widget input ke sini
          ],
        ),
      ),
    );
  }
}
