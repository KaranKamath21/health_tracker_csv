import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../utils/genderpicker.dart';
import '../../utils/mybutton.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  static String routeName = 'RegisterPage';

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ageController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String gender = '';

  bool areDetailsCorrect() {
    String username = _usernameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();
    String age = _ageController.text.trim();
    if (username.isEmpty) {
      popMsg("Enter a valid name");
      return false;
    }
    if (age.isEmpty) {
      popMsg("Enter your age");
      return false;
    }
    if (gender.isEmpty) {
      popMsg("Select the gender");
      return false;
    }
    if (email.isEmpty || !email.contains('@')) {
      popMsg("Enter a valid email");
      return false;
    }
    if (password.length < 8) {
      popMsg("The length of the password must be greater than or equal to 8");
      return false;
    }
    if (password != confirmPassword) {
      popMsg("The passwords do not match");
      return false;
    }
    return true;
  }

  Future<void> register_user() async {
    if (areDetailsCorrect()) {
      try {
        // Register user with email and password
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim());

        // Registration successful, store additional user information

        addUserDetails();
        popMsg("Registration successful");
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => LoginPage()));

        Fluttertoast.showToast(msg: "Congratulations! You are registered");
      } catch (e) {
        print('Error: $e');
        if (e is FirebaseAuthException) {
          Fluttertoast.showToast(
              msg: e.message ?? "Error occurred during signup");
        } else {
          Fluttertoast.showToast(msg: "Unknown error occurred during signup");
        }
      }
    }
  }

  Future addUserDetails() async {
    await FirebaseFirestore.instance.collection('users').add({
      'username': _usernameController.text.trim(),
      'age': _ageController.text.trim(),
      'gender': gender,
      'email': _emailController.text.trim(),
    });
  }

  popMsg(String msg) {
    Fluttertoast.showToast(msg: msg);
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                const Icon(
                  Icons.person,
                  size: 100,
                ),

                const SizedBox(height: 10),

                //New User Registration
                Text(
                  'New User Registration',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 28,
                      fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 20),

                //UserName Text Field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: TextField(
                    controller: _usernameController,
                    obscureText: false,
                    decoration: InputDecoration(
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                      fillColor: Colors.grey.shade200,
                      filled: true,
                      prefixIcon: const Icon(Icons.account_circle_outlined),
                      hintText: 'Full Name',
                      hintStyle: const TextStyle(color: Colors.grey),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                ),

                const SizedBox(height: 10),

                //Age
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: TextFormField(
                    controller: _ageController,
                    decoration: InputDecoration(
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                      fillColor: Colors.grey.shade200,
                      filled: true,
                      prefixIcon: const Icon(Icons.cake),
                      hintText: 'Enter your Age',
                      hintStyle: const TextStyle(color: Colors.grey),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                ),

                const SizedBox(height: 10),

                // Gender Picker
                GenderPicker(
                  onGenderSelected: (value) {
                    gender = value!;
                  },
                ),

                const SizedBox(height: 10),

                //Email
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: TextField(
                    controller: _emailController,
                    // focusNode: _focusNode,
                    obscureText: false,
                    decoration: InputDecoration(
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                      fillColor: Colors.grey.shade200,
                      filled: true,
                      prefixIcon: const Icon(Icons.email_outlined),
                      hintText: 'Email',
                      hintStyle: const TextStyle(color: Colors.grey),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                ),

                const SizedBox(height: 10),

                //Password
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                      fillColor: Colors.grey.shade200,
                      filled: true,
                      prefixIcon: const Icon(Icons.lock_open),
                      hintText: 'Enter your Password',
                      hintStyle: const TextStyle(color: Colors.grey),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                ),

                const SizedBox(height: 10),

                //Confirm Password
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: TextField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                      fillColor: Colors.grey[200],
                      filled: true,
                      prefixIcon: const Icon(Icons.lock),
                      hintText: 'Confirm Password',
                      hintStyle: const TextStyle(color: Colors.grey),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                ),

                const SizedBox(height: 20),

                // Register Button
                MyButton(
                  text: 'Register',
                  onTapFunction: register_user,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
