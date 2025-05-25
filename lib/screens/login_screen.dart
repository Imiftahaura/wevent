// ignore_for_file: prefer_const_constructors, use_key_in_widget_constructors, unnecessary_nullable_for_final_variable_declarations

import 'package:flutter/material.dart';
import 'package:wevent3/screens/home_screen.dart';
import '../screens/register_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';


class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final Color orangeColor = Color(0xFFFF6F00); 

 
  Future<void> _performLogin() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email and password cannot be empty')),
      );
      return;
    }

    try {
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen(userName: '',)),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login successful!')),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Login failed.';
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Wrong password provided for that user.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
      print('Firebase Auth Exception: ${e.code} - ${e.message}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred')),
      );
      print('Unexpected error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // PENTING: Atur background color scaffold menjadi transparent agar gradien di body terlihat
      backgroundColor: Colors.transparent, 
      // appBar: AppBar(
      //   title: Text('Login', style: TextStyle(color: const Color.fromARGB(255, 251, 245, 245))),
      //   backgroundColor: orangeColor,
      //   iconTheme: IconThemeData(color: const Color.fromARGB(255, 230, 224, 224)), // Icon warna hitam
      // ),
      body: Container( // Bungkus seluruh body dengan Container
        decoration: BoxDecoration(
          gradient: LinearGradient(
            // Definisikan warna gradien Anda di sini, sesuaikan dengan RegisterScreen jika ingin sama
            // ignore: prefer_const_literals_to_create_immutables
            colors: [
              Color(0xFF0B1A40).withOpacity(0.9), // Warna awal (misal: warna dasar gelap Anda)
              Color(0xFF1E3A8A).withOpacity(0.7), // Warna tengah (misal: biru lebih terang)
              // Color(0xFF4C5E9C), // Warna akhir (misal: biru keunguan)
            ],
            begin: Alignment.topLeft, // Arah awal gradien
            end: Alignment.bottomRight, // Arah akhir gradien
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(height: 5),
              ShaderMask(
                shaderCallback: (bounds) {
                  // Definisikan gradien kamu di sini
                  return LinearGradient(
                    // ignore: prefer_const_literals_to_create_immutables
                    colors: [
                      Color(0xFFFFA000),
                      Color(0xFFFFCC80), 
                    ],
                    begin: Alignment.topLeft, 
                    end: Alignment.bottomRight, 
                  ).createShader(bounds);
                },
                child: Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: 50.0,
                    fontFamily: 'Roboto',
                    color: Colors.white, 
                   
                  ),
                ),
              ),

              SizedBox(height: 4.0),
              Text(
                'login to your account, and start your event',
                style: TextStyle(
                  fontSize: 16.0,
                  fontFamily: 'roboto',
                  color: Color.fromARGB(234, 248, 244, 242),
                ),
              ),
              SizedBox(height: 40),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next, 
                style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Color.fromARGB(255, 255, 255, 255), fontSize: 13),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: orangeColor),
                    borderRadius: BorderRadius.circular(18.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color.fromARGB(234, 243, 100, 29)),
                    borderRadius: BorderRadius.circular(18.0),
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: _passwordController,
                obscureText: true,
                textInputAction: TextInputAction.done, 
                onSubmitted: (_) => _performLogin(), 
                style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: Color.fromARGB(255, 255, 255, 255), fontSize: 13),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: orangeColor),
                    borderRadius: BorderRadius.circular(18.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color.fromARGB(234, 243, 100, 29)),
                    borderRadius: BorderRadius.circular(18.0),
                  ),
                ),
              ),
              SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: _performLogin, 
                style: ElevatedButton.styleFrom(
                  backgroundColor: orangeColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50.0),
                  ),
                ),
                child: Text('login'),
              ),
              SizedBox(height: 2),
              TextButton(
                onPressed: () {
                  //menggunakan pushreplacement agar tidak bisa kembali ke halaman login/tidak menumpuk ygyg
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => RegisterScreen()),
                  );
                },
                child: Text(
                  'Dont have any account? Regiester here',
                  style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}