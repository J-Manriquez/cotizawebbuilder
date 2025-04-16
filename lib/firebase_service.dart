import 'package:cloud_firestore/cloud_firestore.dart'; // Importa Firestore.
import 'package:firebase_core/firebase_core.dart'; // Importa Firebase Core.
import 'firebase_options.dart'; // Importa las opciones de Firebase.

class ServicioFirebase {
  static Map<String, dynamic> precios = {}; // Mapa estático para almacenar los precios.

  static Future<void> inicializarFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  static Future<void> obtenerPrecios() async {
    print('Intentando obtener el documento de Firestore...');
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('precios')
          .doc('lista_precios')
          .get();

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
    return number.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.');
  }

  // Función para formatear el nombre de la opción
  static String formatearNombreOpcion(String optionKey) {
    return optionKey
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
        .join(' ')
        .trim();
  }

  // Método para formatear la opción con el precio
  static String formatearOpcionConPrecio(String optionKey, [String priceKey = 'valor_ofrecido']) {
    if (precios.containsKey(optionKey)) {
      int price = (precios[optionKey][priceKey] as num).round();
      return '${formatearNombreOpcion(optionKey)} - \$${formatearNumeroConPuntos(price)}';
    } else {
      print('Clave $optionKey no encontrada en los precios.');
      return '${formatearNombreOpcion(optionKey)} - Precio no disponible';
    }
  }
}