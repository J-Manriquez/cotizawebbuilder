import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Tu logo
            // Image.asset(
            //   'assets/icon/app_icon.png',
            //   width: 150,
            //   height: 150,
            // ),
            SizedBox(height: 30),
            // Animación de carga personalizada
            SpinKitDoubleBounce(
              color: Colors.white,
              size: 50.0,
            ),
            SizedBox(height: 20),
            Text(
              'Cargando...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}