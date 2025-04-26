// confirmation_screen.dart
import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart'; // Mantener por si se usa en otra parte
import 'dart:convert'; // Necesario para jsonEncode
import 'package:http/http.dart' as http; // Importar el paquete http
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Importa servicios y componentes necesarios
// ignore: unused_import
import 'firebase_service.dart'; // Para formateo si es necesario (y _guardarCotizacionYNotificar)
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

  // ** --- URL DEL WEBHOOK DE MAKE.COM --- **
  // ** REEMPLAZA 'TU_WEBHOOK_URL_DE_MAKE.COM_AQUI' con la URL que copiaste de Make.com **
  final String _makeWebhookUrl =
      'https://hook.us2.make.com/0d14u81dkih3tc9poudur5wpr8sntip1';
  // ** ----------------------------------- **

  // ** --- NÚMERO DE WHATSAPP DE LA EMPRESA --- **
  // ** Reemplaza 'NUMERO_EMPRESA_WHATSAPP' con el número de WhatsApp de tu empresa,
  // ** incluyendo el código de país, sin signos + o espacios, ej: '56912345678' **
  final String _companyWhatsappNumber = '56966965146';
  // ** ------------------------------------- **

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

  // --- Lógica de Envío al Webhook de Make.com ---
  // Función que envía los datos de la cotización al webhook
  Future<void> _sendCotizacionToWebhook(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse(_makeWebhookUrl), // Usa la URL del webhook
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(data), // Convierte el mapa a JSON
      );

      // Verifica la respuesta del webhook
      if (response.statusCode == 200 || response.statusCode == 201) {
        print(
            'Webhook enviado a Make.com correctamente. Respuesta: ${response.body}');
        // Puedes manejar la respuesta de Make.com si envía algún mensaje útil
      } else {
        print('Error al enviar webhook a Make.com: ${response.statusCode}');
        print('Cuerpo del error: ${response.body}');
        // Lanza una excepción para que el catch del llamador la maneje
        throw Exception(
            'Failed to send data to webhook: ${response.statusCode}');
      }
    } catch (e) {
      print('Excepción al enviar webhook: $e');
      // Vuelve a lanzar la excepción para ser manejada por el llamador
      throw e;
    }
  }

  // --- ACCIÓN MODIFICADA (Existente): Enviar copia al usuario mediante Webhook ---
  void _enviarCotizacionAUsuarioViaWebhook() async {
    // 1. Validar el formulario
    if (!_formKey.currentState!.validate()) {
      return; // No hacer nada si el formulario no es válido
    }

    // 2. Mostrar indicador de carga
    setState(() => _isSending = true);

    // 3. Recoger y preparar los datos para enviar al webhook
    String nombre = _nombreController.text.trim();
    String nombreWeb = _nombreWebController.text.trim();
    String telefono = _telefonoController.text.trim();
    String correo = _correoController.text.trim();
    String resumen = widget.cotizacionTextoResumen;
    Map<String, String?> opcionesSeleccionadas = widget.opcionesSeleccionadas;

    // Prepara el mapa de datos que se enviará como JSON al webhook
    Map<String, dynamic> datosParaWebhook = {
      'tipo_envio': 'copia_usuario_email', // Indicador para Make.com
      'destinatario_email': correo,
      'cliente_nombre': nombre,
      'cliente_telefono': telefono,
      'cliente_nombre_web': nombreWeb.isNotEmpty ? nombreWeb : null,
      'resumen_cotizacion_texto': resumen, // El texto formateado del resumen
      'opciones_seleccionadas': opcionesSeleccionadas, // Opciones seleccionadas
      // Puedes añadir cualquier otro dato relevante aquí
    };

    try {
      // 4. Llamar a la función que envía los datos al webhook
      await _sendCotizacionToWebhook(datosParaWebhook);

      // 5. Mostrar mensaje de éxito (si el widget sigue montado)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Copia de cotización enviada a tu correo!'),
            backgroundColor: Colors.green,
          ),
        );
        // Opcional: Limpiar el formulario o navegar
      }
    } catch (e) {
      // 6. Mostrar mensaje de error (si el widget sigue montado)
      print('Error en UI al enviar cotización via webhook: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar la cotización: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // 7. Ocultar indicador de carga (si el widget sigue montado)
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  // --- ACCIÓN: Guardar cotización en Firebase ---
  Future<void> _guardarCotizacionYNotificar() async {
    // 1. Validar el formulario
    if (!_formKey.currentState!.validate()) {
      return; // No hacer nada si el formulario no es válido
    }

    // 2. Mostrar indicador de carga
    setState(() => _isSending = true);

    // 3. Recoger los datos
    String nombre = _nombreController.text.trim();
    String nombreWeb = _nombreWebController.text.trim();
    String telefono = _telefonoController.text.trim();
    String correo = _correoController.text.trim();
    String resumen = widget.cotizacionTextoResumen;

    try {
      // 4. Llamar al servicio de Firebase para guardar
      // Asegúrate de que ServicioFirebase.guardarCotizacion existe y funciona
      await ServicioFirebase.guardarCotizacion(
        nombre: nombre,
        nombreWeb:
            nombreWeb.isNotEmpty ? nombreWeb : null, // Pasa null si está vacío
        telefono: telefono,
        correo: correo,
        resumenCotizacion: resumen,
      );

      // 5. Mostrar mensaje de éxito (si el widget sigue montado)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('¡Cotización enviada! Nos pondremos en contacto pronto.'),
            backgroundColor: Colors.green,
          ),
        );
        // Opcional: Navegar a otra pantalla o limpiar el formulario
        // Navigator.pop(context); // Volver a la pantalla anterior
        // _formKey.currentState?.reset();
        // _nombreController.clear(); ... etc.
      }
    } catch (e) {
      // 6. Mostrar mensaje de error (si el widget sigue montado)
      print('Error en UI al guardar cotización: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar la cotización: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // 7. Ocultar indicador de carga (si el widget sigue montado)
      if (mounted) {
        setState(() => _isSending = false);
      }
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

    // Recolecta los datos del cliente de los controladores
    final Map<String, String> datosClienteParaPdf = {
       'nombre': _nombreController.text.trim(),
       'telefono': _telefonoController.text.trim(),
       'correo': _correoController.text.trim(),
       'nombreWeb': _nombreWebController.text.trim(),
    };

    try {
      // Llama al método del servicio PDF pasando los datos del cliente
      await widget.pdfService.generateAndHandlePdf(
        opcionesSeleccionadas: widget.opcionesSeleccionadas,
        datosCliente: datosClienteParaPdf, // <-- PASA LOS DATOS AQUÍ
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

  // Helper para mostrar Snackbars de error
  void _mostrarErrorSnackBar(String mensaje) {
    if (mounted) {
      // Verifica si el widget está montado antes de usar context
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _enviarWhatsApp(String telefono, String nombreCliente) async {
    // Limpieza básica del número (quitar espacios, guiones) y añadir código país si es necesario
    // Asumimos formato chileno (+569XXXXXXXX)
    String telefonoLimpio = telefono.replaceAll(RegExp(r'[\s-]+'), '');
    if (telefonoLimpio.length == 9 && telefonoLimpio.startsWith('9')) {
      telefonoLimpio =
          '+56$telefonoLimpio'; // Añade código de Chile si parece un móvil chileno
    } else if (telefonoLimpio.length == 8) {
      // Podría ser un número fijo, adaptar si es necesario o manejar el error
      telefonoLimpio =
          '+569$telefonoLimpio'; // Asumiendo que es móvil y falta el 9 inicial
    }
    // Añade más validaciones según los formatos que esperes
    String resumen = widget.cotizacionTextoResumen;
    final String mensaje =
        '''Hola, soy $nombreCliente, realice la siguiente cotizacion en AndoDevs: 
$resumen 
Me gustaría saber cuándo podriamos conversar del tema.''';
    final Uri whatsappUri = Uri.parse(
        'https://wa.me/$telefonoLimpio?text=${Uri.encodeComponent(mensaje)}');

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri,
            mode: LaunchMode.externalApplication); // Abre fuera de la app
      } else {
        print('No se pudo abrir WhatsApp para el número: $telefonoLimpio');
        _mostrarErrorSnackBar('No se pudo abrir WhatsApp. ¿Está instalado?');
      }
    } catch (e) {
      print('Error al intentar abrir WhatsApp: $e');
      _mostrarErrorSnackBar('Error al intentar contactar por WhatsApp.');
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
        //   icon: Icon(Icons.arrow_back, color: Colors.white),
        //   onPressed: () => Navigator.of(context).pop(),
        // ),
        title: Stack(
          // Mismo estilo de título que HomeScreen
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
        iconTheme:
            const IconThemeData(color: Colors.white), // Color íconos AppBar
      ),
      body: SingleChildScrollView(
        // Permite scroll si el contenido es largo
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Center(
            // Centra el contenido si el ancho lo permite
            child: ConstrainedBox(
              // Limita el ancho máximo en pantallas grandes
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Ingresa tus Datos',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                          letterSpacing: 0.8),
                      textAlign: TextAlign.center,
                    ),
                    Container(
                      height: 1,
                      color: Colors.grey.shade300,
                      margin: const EdgeInsets.symmetric(vertical: 14),
                    ),

                    // Botón Enviar Copia al Correo del Usuario (Usa Webhook)
                    ElevatedButton.icon(
                      icon: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.email_outlined,
                              color: Colors.white),
                      label: Text(
                          'Enviarme Cotización vía Email', // Texto actualizado
                          style: GoogleFonts.poppins(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorSecundario,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      // Llama a la función que usa el webhook para enviar al usuario
                      onPressed: _isSending
                          ? null
                          : _enviarCotizacionAUsuarioViaWebhook,
                    ),
                    const SizedBox(height: 18),

                    // --- NUEVO BOTÓN: Enviar a la Empresa via WhatsApp Webhook ---
                    ElevatedButton.icon(
                      icon: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.phone_android_rounded, // Icono de WhatsApp
                              color: Colors.white),
                      label: Text('Solicitar Cotizacion vía WhatsApp',
                          style: GoogleFonts.poppins(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF25D366), // Color típico de WhatsApp
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      // Llama a la nueva función que usa el webhook para enviar a la empresa
                      onPressed: _isSending
                          ? null
                          : () async { // Esta es la función anónima que onPressed espera (VoidCallback)
                          String nombreCiente = _nombreController.text.trim();
        // Llama a tu función _enviarWhatsApp con los datos
        // Como _enviarWhatsApp es async, la función anónima también debe ser async para usar await
        await _enviarWhatsApp(_companyWhatsappNumber, nombreCiente);
      }
                    ),
                    const SizedBox(height: 18),

                    // --- BOTÓN Existente: Enviar a Firebase ---
                    ElevatedButton.icon(
                      icon: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.calendar_month,
                              color: Colors.white), // Icono cambiado
                      label: Text('Agendar Reunión',
                          style: GoogleFonts.poppins(
                              color: Colors.white)), // Mismo texto
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorPrimario, // Mismo color
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      // Llama a la función asíncrona para guardar en Firebase
                      onPressed:
                          _isSending ? null : _guardarCotizacionYNotificar,
                    ),
                    const SizedBox(height: 18),

                    // Botón Descargar PDF (reutilizando la lógica existente)
                    // Esta función NO SE MODIFICA
                    ElevatedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf_outlined,
                          color: colorPrimario),
                      label: Text('Descargar Cotización en PDF',
                          style: GoogleFonts.poppins(color: colorPrimario)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white, // Fondo blanco
                        side: const BorderSide(
                            color: colorPrimario, width: 1.5), // Borde primario
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      // Deshabilita si las fuentes no están listas o si ya está enviando
                      onPressed: widget.pdfFontsReady && !_isSending
                          ? _handlePdfGeneration
                          : null,
                    ),
                    if (!widget
                        .pdfFontsReady) // Muestra advertencia si las fuentes no están listas
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'La descarga PDF estará disponible en breve...',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 12),
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
