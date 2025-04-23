import 'package:cloud_firestore/cloud_firestore.dart'; // Importa Firestore.
import 'package:firebase_core/firebase_core.dart'; // Importa Firebase Core.
import 'firebase_options.dart'; // Importa las opciones de Firebase.

class ServicioFirebase {
  static Map<String, dynamic> precios =
      {}; // Mapa estático para almacenar los precios.
  // Referencia a la instancia de Firestore
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  // Define constantes para la colección y documento de configuración
  static const String _configCollection = 'configuracion';
  static const String _configDoc = 'acceso';
  static const String _adminPasswordField = 'adminPassword';

  static Future<void> inicializarFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  static Future<void> obtenerPrecios() async {
    print('Intentando obtener el documento de Firestore...');
    try {
      DocumentSnapshot doc =
          await _db.collection('precios').doc('lista_precios').get();

      if (doc.exists) {
        print('Documento encontrado en Firestore.');
        precios = doc.data() as Map<String, dynamic>;
      } else {
        print('No se encontró el documento.');
      }
    } catch (e) {
      print('Error al obtener el documento: $e');
    }
  }

  // Función para formatear el número con separadores de miles
  static String formatearNumeroConPuntos(int number) {
    return number.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.');
  }

  // Función para formatear el nombre de la opción
  static String formatearNombreOpcion(String optionKey) {
    return optionKey
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ')
        .trim();
  }

  // Método para formatear la opción con el precio
  static String formatearOpcionConPrecio(String optionKey,
      [String priceKey = 'valor_ofrecido']) {
    if (precios.containsKey(optionKey)) {
      int price = (precios[optionKey][priceKey] as num).round();
      return '${formatearNombreOpcion(optionKey)} - \$${formatearNumeroConPuntos(price)}';
    } else {
      print('Clave $optionKey no encontrada en los precios.');
      return '${formatearNombreOpcion(optionKey)} - Precio no disponible';
    }
  }

  // --- NUEVA FUNCIÓN PARA GUARDAR COTIZACIÓN ---
  static Future<void> guardarCotizacion({
    required String nombre,
    String? nombreWeb, // Puede ser nulo o vacío
    required String telefono,
    required String correo,
    required String resumenCotizacion,
  }) async {
    print('Intentando guardar cotización en Firestore...');
    try {
      // Define la colección donde se guardarán las cotizaciones
      CollectionReference cotizacionesRef = _db.collection('cotizaciones');

      // Crea el mapa de datos a guardar
      Map<String, dynamic> datosCotizacion = {
        'nombreCliente': nombre,
        'nombreWebDeseado': nombreWeb ?? '', // Guarda string vacío si es null
        'telefonoCliente': telefono,
        'correoCliente': correo,
        'resumenCotizacion': resumenCotizacion,
        'fechaRegistro': Timestamp.now(), // Guarda la fecha y hora actual
        'estado':
            'pendiente', // Puedes añadir un estado inicial (ej: pendiente, contactado)
      };

      // Añade un nuevo documento con un ID generado automáticamente
      await cotizacionesRef.add(datosCotizacion);

      print('Cotización guardada exitosamente en Firestore.');
    } catch (e) {
      print('Error al guardar la cotización en Firestore: $e');
      // Re-lanzar el error para que la UI pueda manejarlo
      throw Exception('No se pudo guardar la cotización: $e');
    }
  }

  // --- NUEVA FUNCIÓN PARA OBTENER COTIZACIONES ---
  // Devuelve un Stream para actualizaciones en tiempo real en la pantalla de visualización
  static Stream<QuerySnapshot<Map<String, dynamic>>>
      obtenerCotizacionesStream() {
    print('Obteniendo stream de cotizaciones desde Firestore...');
    try {
      return _db
          .collection('cotizaciones')
          .orderBy('fechaRegistro',
              descending: true) // Ordena por fecha, más nuevas primero
          .snapshots(); // Escucha cambios en tiempo real
    } catch (e) {
      print('Error al obtener stream de cotizaciones: $e');
      // Devuelve un stream vacío o maneja el error como prefieras
      return const Stream.empty();
    }
  }

  // --- NUEVA FUNCIÓN PARA OBTENER LA CONTRASEÑA DE ADMIN ---
  static Future<String?> obtenerContrasenaAdmin() async {
    print('Intentando obtener contraseña de admin desde Firestore...');
    try {
      DocumentSnapshot doc =
          await _db.collection(_configCollection).doc(_configDoc).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey(_adminPasswordField)) {
          print('Contraseña de admin encontrada.');
          // !! ADVERTENCIA DE SEGURIDAD !!
          // Idealmente, la contraseña debería estar hasheada y la comparación
          // debería hacerse con el hash, no recuperando el texto plano.
          // Esto es solo para cumplir el requisito directo.
          return data[_adminPasswordField] as String?;
        } else {
          print(
              'Documento de acceso encontrado, pero falta el campo $_adminPasswordField.');
          return null; // El campo específico no existe
        }
      } else {
        print(
            'No se encontró el documento de configuración de acceso ($_configCollection/$_configDoc).');
        return null; // El documento no existe
      }
    } catch (e) {
      print('Error al obtener la contraseña de admin: $e');
      // Re-lanzar o devolver null para que la UI maneje el error
      throw Exception('Error al verificar credenciales: $e');
      // return null;
    }
  }
  
  static Future<void> eliminarCotizacion(String id) {
    return _db.collection('cotizaciones').doc(id).delete();
  }
  static Future<void> actualizarEstadoCotizacion(String id, String nuevoEstado) {
    return _db.collection('cotizaciones').doc(id).update({'estado': nuevoEstado});
  }

}
