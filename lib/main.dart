import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Importa el script de servicio de Firebase (asume que existe)
import 'firebase_service.dart';
// Importa la pantalla principal
import 'home_screen.dart';

void main() async {
  // Asegura la inicialización de los bindings de Flutter
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializa Firebase (asume que esta función existe en ServicioFirebase)
  await ServicioFirebase.inicializarFirebase();
  // Obtiene los precios iniciales (asume que esta función existe en ServicioFirebase)
  await ServicioFirebase.obtenerPrecios();
  // Ejecuta la aplicación
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Definir los colores personalizados - centralizados aquí para el tema
  static const Color colorPrimario = Color.fromARGB(255, 59, 59, 59);
  static const Color colorSecundario = Color.fromARGB(255, 155, 154, 154);
  static const Color colorFondo = Color.fromARGB(255, 240, 240, 240);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'COTIZA WEB BUILDER',
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: colorPrimario,
          secondary: colorSecundario,
          background: colorFondo,
          surface: Colors.white,
          onSurface: Colors.black87,
        ),
        scaffoldBackgroundColor: colorFondo,
        appBarTheme: const AppBarTheme(
          backgroundColor: colorPrimario,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          // El título con estilo se define en HomeScreen para acceso a colores
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorPrimario, // Usar el colorPrimario del tema
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30), // Bordes redondeados suaves
            ),
            elevation: 0, // Sin sombra
          ),
        ),
        textButtonTheme: TextButtonThemeData(
           style: TextButton.styleFrom(
             foregroundColor: Colors.white, // Color de texto para TextButton
             backgroundColor: const Color.fromARGB(255, 0, 0, 0), // Fondo oscuro para contraste
             shape: RoundedRectangleBorder(
               borderRadius: BorderRadius.circular(30),
            ),
           )
        ),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0), // Bordes cuadrados en Cards
            side: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          color: Colors.white,
        ),
         inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(0), // Bordes cuadrados
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(0),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(0),
              borderSide: const BorderSide(color: colorPrimario, width: 1),
            ),
            filled: true,
            fillColor: Colors.white,
             contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
             labelStyle: TextStyle(color: Colors.grey.shade600, letterSpacing: 0.3),
             hintStyle: TextStyle(color: Colors.grey.shade500),
        ),
        textTheme: TextTheme( // Usar GoogleFonts directamente donde se necesite o definir estilos aquí
          headlineMedium: GoogleFonts.poppins(fontWeight: FontWeight.w500, letterSpacing: 0.5),
          titleLarge: GoogleFonts.poppins(fontWeight: FontWeight.w500, letterSpacing: 0.5),
          titleMedium: GoogleFonts.poppins(fontWeight: FontWeight.w400), // Más ligero
          bodyLarge: GoogleFonts.poppins(fontSize: 16),
          bodyMedium: GoogleFonts.poppins(fontSize: 15, height: 1.6, letterSpacing: 0.3),
        ),
      ),
      // La pantalla principal de la aplicación
      home: const HomeScreen(),
    );
  }
}