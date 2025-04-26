// import 'dart:nativewrappers/_internal/vm/lib/ffi_patch.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Necesario para Clipboard
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; // Necesario para abrir WhatsApp y correo

import 'firebase_service.dart'; // Asume que aquí está ServicioFirebase.obtenerCotizacionesStream()
import 'main.dart'; // Asume que aquí está MyApp.colorPrimario

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
                  'Cliente: $nombreCliente',
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

    // Codifica manualmente el asunto y el cuerpo usando Uri.encodeQueryComponent
    // Esto asegura que los espacios se conviertan en %20
    // Codifica manualmente el asunto y cuerpo
    final String asuntoCodificado = Uri.encodeComponent(asunto);
    final String cuerpoCodificado = Uri.encodeComponent(cuerpo);
    
    // Construye la URI manualmente con los componentes ya codificados
    // Usamos el parámetro 'query' directamente en lugar de 'queryParameters'
    final Uri emailUri = Uri.parse(
        'mailto:$correo?subject=$asuntoCodificado&body=$cuerpoCodificado');

    // Lanza la URI usando url_launcher (o el método que prefieras)
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

  // --- Widget Builder para la Tarjeta (Reutilizable) ---
  Widget _buildCotizacionCard(BuildContext context,
      Map<String, dynamic> cotizacionData, String cotizacionId) {
    // Extraer datos con valores por defecto seguros
    final String nombre =
        cotizacionData['nombreCliente'] as String? ?? 'Nombre no disponible';
    final String telefono = cotizacionData['telefonoCliente'] as String? ?? '';
    final String correo = cotizacionData['correoCliente'] as String? ?? '';
    final String nombreWeb =
        cotizacionData['nombreWebDeseado'] as String? ?? '';
    final String resumen = cotizacionData['resumenCotizacion'] as String? ??
        'Resumen no disponible';
    final Timestamp? fechaTimestamp =
        cotizacionData['fechaRegistro'] as Timestamp?;
    final String fechaFormateada = fechaTimestamp != null
        ? _formatTimestamp(fechaTimestamp)
        : 'Fecha no disponible';
    final String estado = cotizacionData['estado'] as String? ?? 'Pendiente';

    // Lógica para obtener la línea del resumen
    final lines = resumen.split('\n');
    final String lineaMostrada = lines.length >= 3
        ? lines[lines.length - 3]
        : (lines.isNotEmpty
            ? lines.last
            : resumen); // Lógica un poco más robusta
    final String lineaSinPrimeraPalabra = lineaMostrada.contains(' ')
        ? lineaMostrada.substring(lineaMostrada.indexOf(' ') + 1)
        : lineaMostrada;

    return Card(
        margin: const EdgeInsets.symmetric(
            horizontal: 0,
            vertical: 0), // El Wrap/Padding se encargará del margen externo
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        // Clip.antiAlias es útil para asegurar que el InkWell no se salga de los bordes
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          // <-- 1. Añade InkWell aquí
          // 2. Mueve la lógica onTap del ListTile aquí
          onTap: () => _mostrarDetalleCotizacion(context, resumen, nombre),
          // 3. Añade borderRadius para que el hover/splash coincida con la forma de la Card
          borderRadius: BorderRadius.circular(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Importante para Wrap/GridView
            children: [
              ListTile(
                contentPadding:
                    const EdgeInsets.only(left: 16.0, right: 16.0, top: 10.0),
                title: Text('Cliente: $nombre',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 20)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0), // Ajuste ligero
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Registrado: $fechaFormateada',
                          style: TextStyle(
                              fontSize: 16, color: Colors.grey.shade700)),
                      const SizedBox(height: 4), // Espacio
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            'Estado: ',
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey.shade700),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: _getColorForEstado(estado),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10.0,
                                vertical:
                                    2.0), // Ajuste ligero padding vertical
                            child: Text(estado,
                                style: const TextStyle(
                                    fontSize:
                                        14, // Ligeramente más pequeño para encajar mejor
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4), // Espacio
                      if (telefono.isNotEmpty)
                        Text('Tel: $telefono',
                            style: TextStyle(
                                fontSize: 15,
                                color: Colors
                                    .grey.shade700)), // Tamaño consistente
                      if (correo.isNotEmpty)
                        Text('Correo: $correo',
                            style: TextStyle(
                                fontSize: 15, color: Colors.grey.shade700)),
                      if (nombreWeb.isNotEmpty)
                        Text('Web Deseada: $nombreWeb',
                            style: TextStyle(
                                fontSize: 15, color: Colors.grey.shade700)),
                      // const SizedBox(height: 0), // No necesario aquí
                    ],
                  ),
                ),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
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
                    PopupMenuItem<String>(
                      value: _whatsappOpcion,
                      enabled: telefono
                          .isNotEmpty, // Habilitar/deshabilitar dinámicamente
                      child: ListTile(
                          leading: Icon(Icons.message,
                              color: telefono.isNotEmpty
                                  ? null
                                  : Colors
                                      .grey), // Estilo visual si deshabilitado
                          title: Text('Enviar WhatsApp',
                              style: TextStyle(
                                  color: telefono.isNotEmpty
                                      ? null
                                      : Colors.grey))),
                    ),
                    PopupMenuItem<String>(
                      value: _correoOpcion,
                      enabled: correo.isNotEmpty,
                      child: ListTile(
                          leading: Icon(Icons.email,
                              color: correo.isNotEmpty ? null : Colors.grey),
                          title: Text('Enviar Correo',
                              style: TextStyle(
                                  color:
                                      correo.isNotEmpty ? null : Colors.grey))),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(
                      value: _estadoOpcion,
                      child: ListTile(
                        leading: Icon(Icons.sync_alt),
                        title: Text('Cambiar Estado'),
                      ),
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
                // onTap: () => _mostrarDetalleCotizacion(context, resumen, nombre),
              ),
              // Contenedor de lineaSinPrimeraPalabra ahora está fuera del ListTile
              Padding(
                padding: const EdgeInsets.only(
                    bottom: 15.0,
                    left: 16.0,
                    right: 16.0,
                    top: 5.0), // Ajustar padding
                child: Center(
                  // Centrar el contenedor
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10.0, vertical: 4.0), // Padding interno
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color.fromARGB(255, 56, 116, 53),
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      lineaSinPrimeraPalabra,
                      style: const TextStyle(
                        fontSize: 16, // Ligeramente más pequeño
                        color: Color.fromARGB(255, 56, 116, 53),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign
                          .center, // Centrar texto dentro del contenedor
                      maxLines: 2, // Permitir hasta 2 líneas si es necesario
                      overflow: TextOverflow
                          .ellipsis, // Añadir puntos suspensivos si excede
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: const Text('Cotizaciones Recibidas'), // Comentado en tu original
        title: Stack(
          // Tu título estilizado
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
                color: MyApp.colorSecundario, // Usando el color secundario
              ),
            ),
          ],
        ),
        backgroundColor: MyApp.colorPrimario, // Usa tu color primario
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          // Estilo por defecto si el Stack no estuviera
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

          // Usamos LayoutBuilder para decidir qué layout mostrar
          return LayoutBuilder(
            builder: (context, constraints) {
              final double screenWidth = constraints.maxWidth;
              const double breakpoint =
                  730.0; // Punto de quiebre para cambiar layout
              const double cardMaxWidth =
                  340.0; // Ancho máximo para cada tarjeta en modo grid

              if (screenWidth < breakpoint) {
                // --- Layout para pantallas pequeñas: ListView ---
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8), // Padding que tenías en Card
                  itemCount: cotizaciones.length,
                  itemBuilder: (context, index) {
                    final cotizacionData = cotizaciones[index].data();
                    final cotizacionId = cotizaciones[index].id;
                    // Reutilizamos el builder de la tarjeta
                    // Añadimos un padding inferior a cada item para simular el `margin` vertical original de la Card
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: _buildCotizacionCard(
                          context, cotizacionData, cotizacionId),
                    );
                  },
                );
              } else {
                // --- Layout para pantallas anchas: Wrap ---
                return SingleChildScrollView(
                  // Para permitir scroll si el contenido es muy alto
                  child: Padding(
                    padding: const EdgeInsets.all(
                        16.0), // Espaciado general del grid
                    child: Wrap(
                      spacing: 16.0, // Espacio horizontal entre tarjetas
                      runSpacing:
                          16.0, // Espacio vertical entre filas de tarjetas
                      alignment: WrapAlignment
                          .center, // Centrar las tarjetas si no llenan el ancho
                      children: cotizaciones.map((doc) {
                        final cotizacionData = doc.data();
                        final cotizacionId = doc.id;
                        // Limitamos el ancho de cada tarjeta usando ConstrainedBox
                        return ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: cardMaxWidth),
                          child: _buildCotizacionCard(
                              context, cotizacionData, cotizacionId),
                        );
                      }).toList(),
                    ),
                  ),
                );
              }
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
