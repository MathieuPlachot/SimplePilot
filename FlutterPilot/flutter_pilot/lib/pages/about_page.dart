import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('About'),
        leading: BackButton(),
      ),
      body: Center(
        child: Text('About Page', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
