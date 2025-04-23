import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_service.dart'; // Para verificar la contraseña
import 'cotizaciones_screen.dart'; // La pantalla a la que se accede
import 'main.dart'; // Para los colores si los usas

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscureText = true; // Para ocultar/mostrar contraseña

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _intentarLogin() async {
    // Oculta el teclado si está abierto
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return; // No continuar si el campo está vacío
    }

    setState(() => _isLoading = true);

    try {
      final String? storedPassword = await ServicioFirebase.obtenerContrasenaAdmin();
      final String enteredPassword = _passwordController.text;

      // Verifica si se obtuvo la contraseña y si coincide
      if (storedPassword != null && storedPassword == enteredPassword) {
        // Éxito: Navega a la pantalla de cotizaciones
         if (mounted) { // Verifica si el widget sigue en el árbol
             Navigator.pushReplacement( // Usa pushReplacement para no volver aquí
               context,
               MaterialPageRoute(builder: (context) => const CotizacionesScreen()),
             );
         }
      } else {
        // Error: Contraseña incorrecta o no encontrada
         if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(
                 content: Text('Contraseña incorrecta.'),
                 backgroundColor: Colors.red,
               ),
             );
         }
      }
    } catch (e) {
       // Error durante la obtención de la contraseña
       print('Error en login: $e');
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al verificar: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
        }
    } finally {
       // Asegura que el estado de carga se desactive
       if (mounted) {
           setState(() => _isLoading = false);
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: //const Text('Acceso Administrador'),
        Stack(
          alignment: Alignment.center,
          children: [
            Text(
              'ACCESO ADMINISTRADOR',
              style: GoogleFonts.poppins(
                fontSize: 24,
                letterSpacing: 1,
                fontWeight: FontWeight.w900,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 3
                  ..color = Colors.white,
              ),
            ),
            Text(
              'ACCESO ADMINISTRADOR',
              style: GoogleFonts.poppins(
                fontSize: 24,
                letterSpacing: 1,
                fontWeight: FontWeight.w900,
                color: MyApp.colorSecundario,
              ),
            ),
          ],
        ),
        backgroundColor: MyApp.colorPrimario, // Usa tus colores
         iconTheme: const IconThemeData(color: Colors.white),
         titleTextStyle: const TextStyle(
           color: Colors.white,
           fontSize: 20,
           fontWeight: FontWeight.bold
         ),
      ),
      body: Center(
        child: SingleChildScrollView( // Para evitar overflow si aparece el teclado
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 80,
                    color: MyApp.colorSecundario, // Usa tus colores
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'Ingrese la contraseña para continuar',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscureText, // Oculta el texto
                    decoration: InputDecoration(
                      hintText: 'Contraseña', // Placeholder
                      // Sin labelText según lo solicitado
                       prefixIcon: const Icon(Icons.vpn_key_outlined),
                       suffixIcon: IconButton(
                          icon: Icon(
                            _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                        ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                       focusedBorder: OutlineInputBorder(
                         borderSide: const BorderSide(color: MyApp.colorPrimario, width: 2.0),
                         borderRadius: BorderRadius.circular(8.0),
                       ),
                    ),
                    keyboardType: TextInputType.visiblePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, ingrese la contraseña';
                      }
                      return null; // Pasa la validación
                    },
                    // Permite enviar desde el teclado
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _isLoading ? null : _intentarLogin(),

                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    icon: _isLoading
                        ? Container( // Contenedor para tamaño fijo del spinner
                            width: 24,
                            height: 24,
                            padding: const EdgeInsets.all(2.0),
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Icon(Icons.login, color: Colors.white),
                    label: const Text('Entrar', style: TextStyle(fontSize: 16, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MyApp.colorPrimario, // Usa tus colores
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _isLoading ? null : _intentarLogin, // Deshabilita si está cargando
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}