// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:wevent3/firebase_options.dart';
import 'package:wevent3/screens/register_screen.dart';
import '../screens/login_screen.dart'; 
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';


void main() async {
  
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Event Management App', 
      theme: ThemeData(
        primarySwatch: Colors.blue, 
      ),
  
      home: RegisterScreen(), 
    );
  }
}