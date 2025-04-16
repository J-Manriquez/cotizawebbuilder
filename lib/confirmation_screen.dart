// confirmation_screen.dart
import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart'; // Para mailto:

// Importa servicios y componentes necesarios
// ignore: unused_import
import 'firebase_service.dart'; // Para formateo si es necesario
import 'ui_components.dart';
import 'main.dart'; // Para colores
import 'pdf_service.dart'; // Para la instancia y descarga

class ConfirmationScreen extends StatefulWidget {
  final Map<String, String?> opcionesSeleccionadas;
  final String cotizacionTextoResumen; // El texto del resumen generado
  final PdfService pdfService; // La instancia del servicio PDF
  final bool pdfFontsReady; // El estado de las fuentes PDF

  const ConfirmationScreen({
    super.key,
    required this.opcionesSeleccionadas,
    required this.cotizacionTextoResumen,
    required this.pdfService,
    required this.pdfFontsReady,
  });

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  final _formKey = GlobalKey<FormState>(); // Clave para el formulario
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _nombreWebController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();

  bool _isSending = false; // Para mostrar indicador de carga en botones

  @override
  void dispose() {
    _nombreController.dispose();
    _nombreWebController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    super.dispose();
  }

  // --- Lógica de Validación ---
  String? _validateNombre(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor, ingresa tu nombre';
    }
    return null;
  }

  String? _validateTelefono(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor, ingresa tu número de teléfono';
    }
    // Validación simple de número (puedes mejorarla)
    if (!RegExp(r'^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]*$')
        .hasMatch(value.trim())) {
      return 'Ingresa un número de teléfono válido';
    }
    return null;
  }

  String? _validateCorreo(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor, ingresa tu correo electrónico';
    }
    // Validación de formato de correo
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
      return 'Ingresa un correo electrónico válido';
    }
    return null;
  }

  // --- Lógica de Envío (Simulada con mailto:) ---
  Future<void> _enviarCorreo(String destinatario, String asunto, String cuerpo) async {
    setState(() => _isSending = true);

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: destinatario,
      queryParameters: {
        'subject': asunto,
        'body': cuerpo,
      },
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'No se pudo abrir el cliente de correo. ¿Tienes uno instalado?')),
        );
      }
    } catch (e) {
      print('Error al intentar lanzar mailto: $e');
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al preparar el correo: $e')),
      );
    } finally {
      // Asegurarse de que el estado se revierta incluso si hay errores
      if (mounted) {
         setState(() => _isSending = false);
      }
    }
  }

  // Prepara el cuerpo del correo con los detalles
  String _prepararCuerpoCorreo() {
    String nombre = _nombreController.text.trim();
    String nombreWeb = _nombreWebController.text.trim();
    String telefono = _telefonoController.text.trim();
    String correo = _correoController.text.trim();

    String cuerpo = 'Hola,\n\n';
    cuerpo += 'He generado una cotización y estoy interesado/a.\n\n';
    cuerpo += 'Mis Datos:\n';
    cuerpo += 'Nombre: $nombre\n';
    if (nombreWeb.isNotEmpty) {
      cuerpo += 'Nombre Web Deseado: $nombreWeb\n';
    }
    cuerpo += 'Teléfono: $telefono\n';
    cuerpo += 'Correo: $correo\n\n';
    cuerpo += '--- Resumen Cotización Generada ---\n';
    cuerpo += '${widget.cotizacionTextoResumen}\n'; // Usa el texto ya formateado
    cuerpo += '----------------------------------\n\n';

    return cuerpo;
  }

  // Acción: Enviar cotización a sí mismo
  void _enviarCorreoAUsuario() {
    if (_formKey.currentState!.validate()) {
      String correoUsuario = _correoController.text.trim();
      String asunto = 'Cotización Web Generada en Ando Devs';
      String cuerpo = _prepararCuerpoCorreo();
      cuerpo += 'Gracias por usar nuestro cotizador, esperamos que nos elijas.\n';

      _enviarCorreo(correoUsuario, asunto, cuerpo);
    }
  }

  // Acción: Enviar cotización a la empresa y solicitar reunión
  void _enviarCorreoAEmpresa() {
     if (_formKey.currentState!.validate()) {
      String correoEmpresa = 'ando.devs@gmail.com'; // Correo fijo
      String nombreUsuario = _nombreController.text.trim();
      String asunto = 'Solicitud de Reunión - Cotización Web de $nombreUsuario';
      String cuerpo = _prepararCuerpoCorreo();
      cuerpo += 'Por favor, contactarme para agendar una reunión y discutir los detalles.\n\n';
      cuerpo += 'Saludos,\n$nombreUsuario';

      _enviarCorreo(correoEmpresa, asunto, cuerpo);
    }
  }

 // --- Manejador para la Generación/Descarga/Compartir PDF ---
  Future<void> _handlePdfGeneration() async {
    // Verifica si las fuentes PDF están listas
    if (!widget.pdfFontsReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Las fuentes para el PDF aún no están listas. Intenta de nuevo en un momento.')),
      );
      return;
    }

    // Muestra indicador de progreso
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      // Llama al método del servicio PDF pasado desde HomeScreen
      await widget.pdfService.generateAndHandlePdf(
        opcionesSeleccionadas: widget.opcionesSeleccionadas,
         // Puedes añadir datos del cliente al PDF si modificas PdfService
        // datosCliente: {
        //   'nombre': _nombreController.text.trim(),
        //   'telefono': _telefonoController.text.trim(),
        //   'correo': _correoController.text.trim(),
        //   'nombreWeb': _nombreWebController.text.trim(),
        // },
      );

      if (mounted) Navigator.of(context).pop(); // Cierra el diálogo

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF procesado correctamente.')),
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop(); // Cierra el diálogo

      print('Error capturado en ConfirmationScreen al generar/manejar PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar el PDF: ${e.toString()}')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    const Color colorPrimario = MyApp.colorPrimario;
    const Color colorSecundario = MyApp.colorSecundario;
    // ignore: unused_local_variable
    const bool esWeb = kIsWeb; // Verifica si es web para layout

    return Scaffold(
      appBar: AppBar(
         // Añadir botón de retroceso si se desea
        // leading: IconButton(
        //   icon: Icon(Icons.arrow_back, color: Colors.white),
        //   onPressed: () => Navigator.of(context).pop(),
        // ),
        title: Stack( // Mismo estilo de título que HomeScreen
          alignment: Alignment.center,
          children: [
            Text(
              'ENVIAR COTIZACIÓN',
              style: GoogleFonts.poppins(
                fontSize: 20, // Un poco más pequeño para adaptarse
                letterSpacing: 1,
                fontWeight: FontWeight.w900,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 3
                  ..color = Colors.white,
              ),
            ),
            Text(
              'ENVIAR COTIZACIÓN',
              style: GoogleFonts.poppins(
                fontSize: 20,
                letterSpacing: 1,
                fontWeight: FontWeight.w900,
                color: colorSecundario,
              ),
            ),
          ],
        ),
        backgroundColor: colorPrimario, // Color de fondo del AppBar
        iconTheme: const IconThemeData(color: Colors.white), // Color íconos AppBar
      ),
      body: SingleChildScrollView( // Permite scroll si el contenido es largo
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Center( // Centra el contenido si el ancho lo permite
            child: ConstrainedBox( // Limita el ancho máximo en pantallas grandes
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Ingresa tus Datos',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w300,
                            color: Colors.black87,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Campo Nombre
                    TextFormField(
                      controller: _nombreController,
                      decoration: UIComponents.getInputDecoration(
                        labelText: 'Nombre Completo *',
                        hintText: 'Ej: Juan Pérez',
                        primaryColor: colorPrimario,
                      ),
                      validator: _validateNombre,
                      keyboardType: TextInputType.name,
                    ),
                    const SizedBox(height: 16),

                    // Campo Nombre Web (Opcional)
                    TextFormField(
                      controller: _nombreWebController,
                      decoration: UIComponents.getInputDecoration(
                        labelText: 'Nombre deseado para tu Web (Opcional)',
                        hintText: 'Ej: mi-tienda-online',
                         primaryColor: colorPrimario,
                      ),
                      // Sin validador, es opcional
                    ),
                    const SizedBox(height: 16),

                    // Campo Teléfono
                    TextFormField(
                      controller: _telefonoController,
                      decoration: UIComponents.getInputDecoration(
                        labelText: 'Número de Teléfono *',
                        hintText: 'Ej: +56 9 1234 5678',
                        primaryColor: colorPrimario,
                      ),
                      validator: _validateTelefono,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    // Campo Correo
                    TextFormField(
                      controller: _correoController,
                      decoration: UIComponents.getInputDecoration(
                        labelText: 'Correo Electrónico *',
                        hintText: 'ejemplo@correo.com',
                        primaryColor: colorPrimario,
                      ),
                      validator: _validateCorreo,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 30),

                    // --- Botones de Acción ---
                    Text(
                      'Acciones Finales',
                       style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w300,
                            color: Colors.black87,
                            letterSpacing: 0.8
                          ),
                       textAlign: TextAlign.center,
                    ),
                     Container(
                      height: 1,
                      color: Colors.grey.shade300,
                      margin: const EdgeInsets.symmetric(vertical: 14),
                    ),

                    // Botón Enviar Copia al Correo del Usuario
                    ElevatedButton.icon(
                      icon: _isSending
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.email_outlined, color: Colors.white),
                      label: Text('Enviarme Copia de la Cotización', style: GoogleFonts.poppins(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorSecundario,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _isSending ? null : _enviarCorreoAUsuario,
                    ),
                    const SizedBox(height: 18),

                    // Botón Enviar a Empresa y Solicitar Reunión
                    ElevatedButton.icon(
                       icon: _isSending
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send_outlined, color: Colors.white),
                      label: Text('Enviar y Solicitar Reunión', style: GoogleFonts.poppins(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorPrimario,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                         shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _isSending ? null : _enviarCorreoAEmpresa,
                    ),
                    const SizedBox(height: 18),

                    // Botón Descargar PDF (reutilizando la lógica)
                     ElevatedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf_outlined, color: colorPrimario),
                      label: Text('Descargar Cotización en PDF', style: GoogleFonts.poppins(color: colorPrimario)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white, // Fondo blanco
                        side: const BorderSide(color: colorPrimario, width: 1.5), // Borde primario
                        padding: const EdgeInsets.symmetric(vertical: 15),
                         shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      // Deshabilita si las fuentes no están listas o si ya está enviando
                      onPressed: widget.pdfFontsReady && !_isSending ? _handlePdfGeneration : null,
                    ),
                     if (!widget.pdfFontsReady) // Muestra advertencia si las fuentes no están listas
                       Padding(
                         padding: const EdgeInsets.only(top: 8.0),
                         child: Text(
                           'La descarga PDF estará disponible en breve...',
                           textAlign: TextAlign.center,
                           style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                         ),
                       ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
