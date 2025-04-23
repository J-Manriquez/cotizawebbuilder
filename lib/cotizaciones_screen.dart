// import 'dart:nativewrappers/_internal/vm/lib/ffi_patch.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Necesario para Clipboard
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; // Necesario para abrir WhatsApp y correo

import 'firebase_service.dart'; // Asume que aquí está ServicioFirebase.obtenerCotizacionesStream()
import 'main.dart'; // Asume que aquí está MyApp.colorPrimario

// Asegúrate de tener la dependencia url_launcher en tu pubspec.yaml:
// dependencies:
//   flutter:
//     sdk: flutter
//   url_launcher: ^6.0.0 # O la versión más reciente
//   cloud_firestore: ^...
//   intl: ^...
//   firebase_core: ^...

class CotizacionesScreen extends StatefulWidget {
  const CotizacionesScreen({super.key});

  @override
  State<CotizacionesScreen> createState() => _CotizacionesScreenState();
}

class _CotizacionesScreenState extends State<CotizacionesScreen> {
  late Stream<QuerySnapshot<Map<String, dynamic>>> _cotizacionesStream;

  // Constantes para los valores del PopupMenuButton
  static const String _verOpcion = 'ver';
  static const String _whatsappOpcion = 'whatsapp';
  static const String _correoOpcion = 'correo';
  static const String _eliminarOpcion = 'eliminar';
  static const String _estadoOpcion = 'estado';

  @override
  void initState() {
    super.initState();
    _cotizacionesStream = ServicioFirebase.obtenerCotizacionesStream();
    // Configura intl para español (opcional, si no está en main.dart)
    // Asegúrate de haber inicializado Firebase y configurado los locales
    // Intl.defaultLocale = 'es_ES';
    // initializeDateFormatting('es_ES', null); // Puede ser necesario en algunos setups
  }

  String _formatTimestamp(Timestamp timestamp) {
    try {
      return DateFormat('dd MMM yyyy, HH:mm', 'es_ES')
          .format(timestamp.toDate());
    } catch (e) {
      print(
          "Error formateando fecha: $e. Asegúrate que 'es_ES' esté inicializado.");
      // Fallback más genérico si intl falla
      return DateFormat('yyyy-MM-dd HH:mm')
          .format(timestamp.toDate().toLocal());
    }
  }

  // --- Funciones para Acciones del Menú ---

  void _mostrarDetalleCotizacion(
      BuildContext context, String resumen, String nombreCliente) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                // Para que el título no se salga si es largo
                child: Text(
                  'Resumen - $nombreCliente',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(dialogContext).pop(),
                tooltip: 'Cerrar',
              ),
            ],
          ),
          content: SizedBox(
            // Limita la altura máxima del contenido
            width: double.maxFinite, // Ocupa el ancho disponible
            // Ajusta este valor según necesites, o déjalo sin Sizedbox si prefieres que crezca más
            // height: MediaQuery.of(context).size.height * 0.5,
            child: SingleChildScrollView(
              child: Text(resumen),
            ),
          ),
          actionsAlignment: MainAxisAlignment.center, // Centra las acciones
          actionsPadding: const EdgeInsets.only(
              bottom: 16.0, left: 16.0, right: 16.0), // Padding para acción
          actions: <Widget>[
            SizedBox(
              // Botón que ocupa todo el ancho
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.copy),
                label: const Text('Copiar Contenido'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: resumen));
                  Navigator.of(dialogContext).pop(); // Cierra el modal
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Resumen copiado al portapapeles')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  // backgroundColor: MyApp.colorSecundario, // Opcional: color del botón
                  foregroundColor: Colors.white, // Color del texto e icono
                ),
              ),
            ),
          ],
        );
      },
    );
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

    final String mensaje =
        'Hola $nombreCliente, hablo desde AndoDevs. Recibimos una cotización de su parte, me gustaría saber cuándo tiene tiempo para conversar del tema.';
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

  Future<void> _enviarCorreo(String correo, String nombreCliente) async {
    const String asunto = 'Contacto por Cotización - AndoDevs';
    final String cuerpo =
        'Hola $nombreCliente,\n\nHablo desde AndoDevs. Recibimos una cotización de su parte y nos gustaría conversar sobre los detalles.\n\n¿Cuándo tendría disponibilidad para una breve llamada o reunión?\n\nSaludos,\nEl equipo de AndoDevs.';

    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: correo,
      queryParameters: {
        'subject': asunto,
        'body': cuerpo,
      },
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        print('No se pudo abrir el cliente de correo para: $correo');
        _mostrarErrorSnackBar('No se pudo abrir la aplicación de correo.');
      }
    } catch (e) {
      print('Error al intentar abrir cliente de correo: $e');
      _mostrarErrorSnackBar('Error al intentar enviar el correo.');
    }
  }

  void _eliminarCotizacion(String cotizacionId, String nombreCliente) {
    // --- IMPLEMENTACIÓN FUTURA ---
    print('Intentando eliminar cotización ID: $cotizacionId ($nombreCliente)');
    // Aquí mostrarías un diálogo de confirmación y luego llamarías a un método
    // en tu ServicioFirebase para eliminar el documento.
    // Ejemplo: ServicioFirebase.eliminarCotizacion(cotizacionId);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text(
            '¿Estás seguro de que deseas eliminar la cotización de $nombreCliente? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              // Aquí iría la llamada real a Firebase
              print('Confirmado eliminar: $cotizacionId');
              Navigator.of(context).pop();
              ServicioFirebase.eliminarCotizacion(cotizacionId);
              _mostrarInfoSnackBar(
                  'Cotización eliminada (simulado)'); // O un mensaje de éxito real
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _cambiarEstadoCotizacion(String cotizacionId, String estadoActual) {
    // --- IMPLEMENTACIÓN FUTURA ---
    print(
        'Intentando cambiar estado de cotización ID: $cotizacionId (Actual: $estadoActual)');
    // Aquí mostrarías un diálogo o un BottomSheet con las opciones de estado
    // (Ej: 'Pendiente', 'Contactado', 'En Proceso', 'Completada', 'Rechazada')
    // y luego llamarías a un método en ServicioFirebase para actualizar el campo 'estado'.
    // Ejemplo: ServicioFirebase.actualizarEstadoCotizacion(cotizacionId, nuevoEstado);

    // Ejemplo simple con un diálogo y opciones fijas:
    showDialog(
      context: context,
      builder: (context) {
        String? nuevoEstadoSeleccionado; // Para Radio buttons o Dropdown
        // Opciones de estado (podrían venir de una constante o configuración)
        final List<String> estadosPosibles = [
          'Pendiente',
          'Contactado',
          'En Proceso',
          'Completada',
          'Rechazada'
        ];

        // Usaremos un StatefulWidget dentro del Dialog para manejar la selección
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setStateDialog) {
          return AlertDialog(
            title: const Text('Cambiar Estado'),
            content: Column(
              mainAxisSize:
                  MainAxisSize.min, // Para que no ocupe toda la pantalla
              children: estadosPosibles.map((estado) {
                return RadioListTile<String>(
                  title: Text(estado),
                  value: estado,
                  groupValue: nuevoEstadoSeleccionado ??
                      estadoActual, // Marca el estado actual o el nuevo seleccionado
                  onChanged: (value) {
                    setStateDialog(() {
                      // Actualiza el estado del diálogo
                      nuevoEstadoSeleccionado = value;
                    });
                  },
                );
              }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: nuevoEstadoSeleccionado == null ||
                        nuevoEstadoSeleccionado == estadoActual
                    ? null // Deshabilita si no hay cambio
                    : () {
                        // Aquí iría la llamada real a Firebase
                        print(
                            'Confirmado cambiar estado a: $nuevoEstadoSeleccionado para ID: $cotizacionId');
                        ServicioFirebase.actualizarEstadoCotizacion(
                            cotizacionId, nuevoEstadoSeleccionado!);
                        Navigator.of(context).pop();
                        _mostrarInfoSnackBar(
                            'Estado actualizado a $nuevoEstadoSeleccionado'); // O un mensaje de éxito real
                      },
                child: const Text('Guardar'),
              ),
            ],
          );
        });
      },
    );
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

  // Helper para mostrar Snackbars informativos
  void _mostrarInfoSnackBar(String mensaje) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: Colors.blueAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: // const Text('Cotizaciones Recibidas'),
            Stack(
          alignment: Alignment.center,
          children: [
            Text(
              'COTIZACIONES RECIBIDAS',
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
              'COTIZACIONES RECIBIDAS',
              style: GoogleFonts.poppins(
                fontSize: 24,
                letterSpacing: 1,
                fontWeight: FontWeight.w900,
                color: MyApp.colorSecundario,
              ),
            ),
          ],
        ),
        backgroundColor: MyApp.colorPrimario, // Usa tu color primario
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _cotizacionesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print("Error en StreamBuilder: ${snapshot.error}");
            return Center(
                child: Text(
                    'Error al cargar las cotizaciones: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text('No hay cotizaciones registradas.'));
          }

          final cotizaciones = snapshot.data!.docs;

          return ListView.builder(
            itemCount: cotizaciones.length,
            itemBuilder: (context, index) {
              final cotizacionData = cotizaciones[index].data();
              final cotizacionId = cotizaciones[index].id;

              final String nombre =
                  cotizacionData['nombreCliente'] ?? 'Nombre no disponible';
              final String telefono = cotizacionData['telefonoCliente'] ??
                  ''; // Vacío si no disponible para evitar errores en WhatsApp
              final String correo = cotizacionData['correoCliente'] ??
                  ''; // Vacío si no disponible para evitar errores en Mail
              final String nombreWeb = cotizacionData['nombreWebDeseado'] ?? '';
              final String resumen = cotizacionData['resumenCotizacion'] ??
                  'Resumen no disponible';
              final Timestamp? fechaTimestamp = cotizacionData['fechaRegistro'];
              final String fechaFormateada = fechaTimestamp != null
                  ? _formatTimestamp(fechaTimestamp)
                  : 'Fecha no disponible';
              final String estado = cotizacionData['estado'] ??
                  'Pendiente'; // Estado por defecto 'Pendiente'
              final lines = resumen.split('\n');
              // Si hay al menos 3 líneas, toma la antepenúltima; de lo contrario, muestra toda la cadena
              final String lineaMostrada =
                  lines.length >= 3 ? lines[lines.length - 3] : resumen;

              return Card(
                margin: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8), // Aumenta margen
                elevation: 4, // Sombra más pronunciada
                shape: RoundedRectangleBorder(
                  // Bordes ligeramente redondeados
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 10.0, horizontal: 16.0), // Padding interno
                  // leading: CircleAvatar(
                  //   // Icono o inicial en un círculo
                  //   backgroundColor: MyApp.colorSecundario.withOpacity(0.8),
                  //   foregroundColor: Colors.white,
                  //   child: Text(
                  //       nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                  //       style: const TextStyle(fontWeight: FontWeight.bold)),
                  //   // child: Icon(Icons.person, color: Colors.white), // Alternativa con icono
                  // ),
                  title: Text('Cliente: $nombre',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 20)),
                  subtitle: Padding(
                    // Añade padding al subtítulo
                    padding: const EdgeInsets.only(top: 5.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Registrado: $fechaFormateada',
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey.shade700)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Text(
                              'Estado: ',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Color.fromARGB(255, 158, 158, 158)),
                            ),
                            Container(
                                color: _getColorForEstado(estado),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5.0),
                                child: Text(estado,
                                    style: const TextStyle(
                                        fontSize: 16, color: Colors.white))),
                          ],
                        ),
                        // const SizedBox(height: 6),
                        if (telefono.isNotEmpty)
                          Text('Tel: $telefono',
                              style: TextStyle(color: Colors.grey.shade700)),
                        if (correo.isNotEmpty)
                          Text('Correo: $correo',
                              style: TextStyle(color: Colors.grey.shade700)),
                        if (nombreWeb.isNotEmpty)
                          Text('Web Deseada: $nombreWeb',
                              style: TextStyle(color: Colors.grey.shade700)),
                        const SizedBox(height: 2),
                        // Separa el texto en líneas
                        Container(
                          color: const Color.fromARGB(255, 56, 116, 53),
                          padding: const EdgeInsets.symmetric(horizontal: 5.0),
                          child: Text(
                            lineaMostrada,
                            style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.w900),
                            // Si deseas asegurarte de que se renderice exactamente una línea, puedes configurar maxLines: 1
                            maxLines: 1,
                            overflow: TextOverflow
                                .visible, // sin recortes, para mostrarla completa
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert,
                        color: Colors.grey), // Icono del menú
                    tooltip: 'Más opciones',
                    onSelected: (String result) {
                      // Manejar la selección del menú
                      switch (result) {
                        case _verOpcion:
                          _mostrarDetalleCotizacion(context, resumen, nombre);
                          break;
                        case _whatsappOpcion:
                          if (telefono.isNotEmpty) {
                            _enviarWhatsApp(telefono, nombre);
                          } else {
                            _mostrarErrorSnackBar(
                                'No hay número de teléfono registrado.');
                          }
                          break;
                        case _correoOpcion:
                          if (correo.isNotEmpty) {
                            _enviarCorreo(correo, nombre);
                          } else {
                            _mostrarErrorSnackBar(
                                'No hay correo electrónico registrado.');
                          }
                          break;
                        case _eliminarOpcion:
                          _eliminarCotizacion(cotizacionId, nombre);
                          break;
                        case _estadoOpcion:
                          _cambiarEstadoCotizacion(cotizacionId, estado);
                          break;
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: _verOpcion,
                        child: ListTile(
                            leading: Icon(Icons.visibility),
                            title: Text('Ver Cotización')),
                      ),
                      // Deshabilitar opciones si no hay datos
                      PopupMenuItem<String>(
                        value: _whatsappOpcion,
                        enabled: telefono
                            .isNotEmpty, // Habilita solo si hay teléfono
                        child: const ListTile(
                            leading: Icon(Icons
                                .message /* O icono de WhatsApp si lo tienes */),
                            title: Text('Enviar WhatsApp')),
                      ),
                      PopupMenuItem<String>(
                        value: _correoOpcion,
                        enabled:
                            correo.isNotEmpty, // Habilita solo si hay correo
                        child: const ListTile(
                            leading: Icon(Icons.email),
                            title: Text('Enviar Correo')),
                      ),
                      const PopupMenuDivider(), // Separador visual
                      const PopupMenuItem<String>(
                        value: _estadoOpcion,
                        child: ListTile(
                            leading: Icon(Icons.sync_alt),
                            title: Text('Cambiar Estado')),
                      ),
                      const PopupMenuItem<String>(
                        value: _eliminarOpcion,
                        child: ListTile(
                            leading: Icon(Icons.delete_outline,
                                color: Colors.redAccent),
                            title: Text('Eliminar',
                                style: TextStyle(color: Colors.redAccent))),
                      ),
                    ],
                  ),
                  // Quita el onTap de la tarjeta principal o haz que también abra el detalle
                  onTap: () => _mostrarDetalleCotizacion(context, resumen,
                      nombre), // Ahora el tap en la tarjeta también abre el modal
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Función auxiliar para dar color al estado (opcional)
  Color _getColorForEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Colors.orange.shade700;
      case 'contactado':
        return Colors.blue.shade700;
      case 'en proceso':
        return Colors.purple.shade700;
      case 'completada':
        return Colors.green.shade700;
      case 'rechazada':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }
}
