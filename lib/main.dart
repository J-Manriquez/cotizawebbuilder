import 'package:flutter/material.dart'; // Importa el paquete de Flutter para la creación de interfaces de usuario.
import 'package:cloud_firestore/cloud_firestore.dart'; // Importa Firestore para el uso de la base de datos en tiempo real.
import 'package:firebase_core/firebase_core.dart'; // Importa Firebase Core para inicializar Firebase.
import 'firebase_options.dart'; // Importa opciones de configuración de Firebase.

void main() async { // Función principal asíncrona de la aplicación.
  WidgetsFlutterBinding.ensureInitialized(); // Asegura que los widgets de Flutter estén inicializados.
  await Firebase.initializeApp( // Inicializa Firebase con las opciones predeterminadas.
    options: DefaultFirebaseOptions.currentPlatform, // Utiliza las opciones de Firebase para la plataforma actual.
  );
  runApp(const MyApp()); // Ejecuta la aplicación MyApp.
}

class MyApp extends StatefulWidget { // Clase que define un widget con estado.
  const MyApp({super.key}); // Constructor de MyApp que permite claves únicas.
  
  @override
  MyAppState createState() => MyAppState(); // Crea el estado para MyApp.
}

class MyAppState extends State<MyApp> { // Clase que maneja el estado de MyApp.
  Map<String, dynamic> precios = {}; // Mapa para almacenar los precios obtenidos de Firestore.
  final Map<String, String?> _selectedOptions = {}; // Mapa para almacenar las opciones seleccionadas por el usuario.
  final TextEditingController _resultController = TextEditingController(); // Controlador para el campo de texto que muestra el resultado.

  @override
  void initState() { // Método que se ejecuta al iniciar el estado.
    super.initState(); // Llama al método initState de la clase base.
    _fetchPricesFromFirestore(); // Llama a la función para obtener precios de Firestore.
  }

  Future<void> _fetchPricesFromFirestore() async { // Método asíncrono para obtener precios de Firestore.
    print('Intentando obtener el documento de Firestore...'); // Imprime un mensaje de intento.
    try { // Intenta ejecutar el bloque de código.
      DocumentSnapshot doc = await FirebaseFirestore.instance // Obtiene un documento de Firestore.
         .collection('precios') // Selecciona la colección 'precios'.
         .doc('lista_precios') // Selecciona el documento 'lista_precios'.
         .get(); // Obtiene el documento.

      if (doc.exists) { // Verifica si el documento existe.
        print('Documento encontrado en Firestore.'); // Imprime un mensaje de éxito.
        setState(() { // Actualiza el estado del widget.
          precios = doc.data() as Map<String, dynamic>; // Almacena los datos del documento en precios.
        });
      } else { // Si el documento no existe.
        print('No se encontró el documento.'); // Imprime un mensaje de error.
      }
    } catch (e) { // Captura cualquier error que ocurra.
      print('Error al obtener el documento: $e'); // Imprime el error.
    }
  }

  String _formatOptionWithPrice(String optionKey, [String priceKey = 'valor_ofrecido']) { // Método para formatear la opción con el precio.
    if (precios.containsKey(optionKey)) { // Verifica si la clave de opción está en precios.
      // Obtener el precio y formatearlo
      int price = (precios[optionKey][priceKey] as num).round(); // Obtiene el precio y lo redondea.
      return '${_formatOptionName(optionKey)} - \$${_formatNumberWithDots(price)}'; // Devuelve el nombre de la opción y el precio formateado.
    } else { // Si la clave no se encuentra en precios.
      print('Clave $optionKey no encontrada en los precios.'); // Imprime un mensaje de error.
      return '${_formatOptionName(optionKey)} - Precio no disponible'; // Devuelve un mensaje indicando que el precio no está disponible.
    }
  }

  // Función para formatear el número con separadores de miles
  String _formatNumberWithDots(int number) { // Método para formatear números.
    return number.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.'); // Reemplaza los números con separadores de miles.
  }

  String _formatOptionName(String optionKey) { // Método para formatear el nombre de la opción.
    return optionKey
        .replaceAll('_', ' ') // Reemplaza guiones bajos con espacios.
        .split(' ') // Divide la cadena en palabras.
        .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '') // Capitaliza la primera letra de cada palabra.
        .join(' ') // Une las palabras de nuevo en una cadena.
        .trim(); // Elimina espacios en blanco al inicio y al final.
  }

  @override
  Widget build(BuildContext context) { // Método que construye la interfaz de usuario.
    return MaterialApp( // Crea la aplicación material.
      debugShowCheckedModeBanner: false, // Oculta el banner de depuración en modo debug.
      title: 'CotizaWebBuilder', // Título de la aplicación.
      theme: ThemeData.dark(), // Aplica un tema oscuro.
      home: Scaffold( // Crea un Scaffold para la estructura de la página.
        appBar: AppBar( // Crea una barra de aplicación.
          title: const Text('CotizaWebBuilder'), // Título de la barra de aplicación.
        ),
        body: Padding( // Aplica un relleno alrededor del cuerpo de la página.
          padding: const EdgeInsets.all(20.0), // Establece el relleno a 20.0 píxeles en todos los lados.
          child: Column( // Crea una columna para organizar los widgets verticalmente.
            crossAxisAlignment: CrossAxisAlignment.start, // Alinea los widgets al inicio de la columna.
            children: [ // Lista de hijos para la columna.
              const Text( // Widget de texto constante.
                'Selección de Servicios', // Contenido del texto.
                style: TextStyle( // Estilo del texto.
                  fontSize: 30, // Tamaño de fuente.
                  fontWeight: FontWeight.bold, // Peso de fuente en negrita.
                ),
                textAlign: TextAlign.center, // Alinea el texto al centro.
              ),
              const SizedBox(height: 20), // Espacio vertical de 20 píxeles.
              Expanded( // Widget que expande su hijo para llenar el espacio disponible.
                child: SingleChildScrollView( // Permite desplazamiento cuando el contenido es más grande que la pantalla.
                  child: Column( // Crea otra columna para organizar más widgets.
                    crossAxisAlignment: CrossAxisAlignment.start, // Alinea los hijos al inicio.
                    children: [ // Lista de hijos para la columna.
                      _buildDescriptionAndDropdown( // Llama al método para construir descripción y dropdown para 'Creación'.
                        'Creación', // Etiqueta del dropdown.
                        [ // Descripciones asociadas a la opción.
                          'Adaptación de plantilla: Uso y ajuste de una plantilla preexistente.',
                          'Personalización de plantilla: Modificación de una plantilla existente según requerimientos específicos.',
                          'Creación personalizada desde cero: Diseño y desarrollo de un sitio web totalmente a medida.',
                        ],
                        [ // Claves de opciones para seleccionar.
                          'adaptacion_plantilla',
                          'personalizacion_plantilla',
                          'creacion_personalizada',
                        ],
                      ),
                      _buildDescriptionAndDropdown( // Llama al método para 'SEO'.
                        'SEO', // Etiqueta del dropdown.
                        [ // Descripciones asociadas a la opción.
                          'SEO Básico: Optimización básica para motores de búsqueda.',
                          'SEO Avanzado: Optimización avanzada para motores de búsqueda, incluyendo creación de blogs.',
                          'Sin SEO: No se aplica optimización para motores de búsqueda.',
                        ],
                        [ // Claves de opciones para seleccionar.
                          'seo_basico',
                          'seo_avanzado',
                          'sin_seo',
                        ],
                      ),
                      _buildDescriptionAndDropdown( // Llama al método para 'Blogs'.
                        'Blogs', // Etiqueta del dropdown.
                        [ // Descripciones asociadas a la opción.
                          'Blogs: Creación de contenido de blogs, sólo disponible con SEO Avanzado.',
                        ],
                        [ // Claves de opciones para seleccionar.
                          '0_blogs',
                          '1_blog',
                          '2_blog',
                          '3_blog',
                          '4_blog',
                        ],
                        visible: _selectedOptions['SEO'] == 'seo_avanzado', // Visibilidad depende de la opción de SEO seleccionada.
                      ),
                      _buildDescriptionAndDropdown( // Llama al método para 'Mantenimiento'.
                        'Mantenimiento', // Etiqueta del dropdown.
                        [ // Descripciones asociadas a la opción.
                          'Mantenimiento Básico: Soporte básico y actualizaciones periódicas.',
                          'Mantenimiento Estándar: Soporte intermedio con actualizaciones más frecuentes.',
                          'Mantenimiento Avanzado: Soporte completo con actualizaciones regulares y soporte prioritario dentro del horario laboral. Incluye creación de un blog al mes.',
                          'Sin Mantenimiento: No se incluye servicio de mantenimiento.',
                        ],
                        [ // Claves de opciones para seleccionar.
                          'mantenimiento_basico',
                          'mantenimiento_estandar',
                          'mantenimiento_avanzado',
                          'sin_mantenimiento',
                        ],
                      ),
                      _buildDescriptionAndDropdown( // Llama al método para 'Productos'.
                        'Productos', // Etiqueta del dropdown.
                        [ // Descripciones asociadas a la opción.
                          'Limite de Productos: Restricción en el número de productos gestionables en la web.',
                        ],
                        [ // Claves de opciones para seleccionar.
                          'limite_25_productos',
                          'limite_50_productos',
                          'limite_100_productos',
                          'limite_150_productos',
                          'limite_500_productos',
                          'ilimitado_productos',
                        ],
                      ),
                      _buildDescriptionAndDropdown( // Llama al método para 'Dominio'.
                        'Dominio', // Etiqueta del dropdown.
                        [ // Descripciones asociadas a la opción.
                          'Dominio: Incluye la gestión del dominio.',
                        ],
                        [ // Claves de opciones para seleccionar.
                          'dominio_previo',
                          'sin_dominio_previo',
                        ],
                      ),
                      _buildDescriptionAndDropdown( // Llama al método para 'Hosting'.
                        'Hosting', // Etiqueta del dropdown.
                        [ // Descripciones asociadas a la opción.
                          'Hosting: Incluye el servicio de hosting para la web.',
                        ],
                        [ // Claves de opciones para seleccionar.
                          'hosting_previo',
                          'sin_hosting_previo',
                        ],
                      ),
                      const SizedBox(height: 20), // Espacio vertical de 20 píxeles.
                      Center( // Envuelve el botón en un widget Center para centrarlo.
                        child: SizedBox( // Usa un Container para establecer el ancho del botón.
                          width: double.infinity, // Establece el ancho al 100%.
                          child: ElevatedButton( // Crea un botón elevado.
                            onPressed: _calculateAndDisplayResult, // Acción a realizar al presionar el botón.
                            child: const Text('Calcular'), // Texto del botón.
                          ),
                        ),
                      ),
                      const SizedBox(height: 20), // Espacio vertical de 20 píxeles.
                      TextField( // Crea un campo de texto.
                        controller: _resultController, // Controlador del campo de texto.
                        maxLines: 10, // Número máximo de líneas.
                        readOnly: true, // Hace que el campo de texto sea de solo lectura.
                        decoration: const InputDecoration( // Estilo del campo de texto.
                          hintText: 'Resultado', // Texto de sugerencia cuando está vacío.
                          border: OutlineInputBorder(), // Añade un borde al campo de texto.
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionAndDropdown(String label, List<String> descriptions, List<String> options, {bool visible = true}) { // Método para construir descripción y dropdown.
    return Visibility( // Controla la visibilidad del widget.
      visible: visible, // Determina si el widget es visible o no.
      child: Column( // Crea una columna para organizar los elementos.
        crossAxisAlignment: CrossAxisAlignment.start, // Alinea los hijos al inicio.
        children: [ // Lista de hijos para la columna.
          Text( // Crea un widget de texto para la etiqueta.
            label, // Contenido de la etiqueta.
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), // Estilo del texto.
          ),
          const SizedBox(height: 8), // Espacio vertical de 8 píxeles.
          ...descriptions.map((desc) => Padding( // Mapea sobre las descripciones y crea un widget de relleno.
            padding: const EdgeInsets.symmetric(vertical: 4), // Aplica relleno vertical.
            child: Text(desc), // Crea un widget de texto para la descripción.
          )),
          const SizedBox(height: 8), // Espacio vertical de 8 píxeles.
          DropdownButtonFormField<String?>( // Crea un campo de dropdown.
            value: _selectedOptions[label], // Establece el valor seleccionado.
            onChanged: (value) { // Callback que se ejecuta al cambiar el valor.
              setState(() { // Actualiza el estado del widget.
                _selectedOptions[label] = value; // Almacena el nuevo valor seleccionado.
              });
            },
            items: options.map((option) { // Mapea sobre las opciones para crear los elementos del dropdown.
              return DropdownMenuItem<String?>( // Crea un item para el dropdown.
                value: option, // Establece el valor del item.
                child: Text(_formatOptionWithPrice(option)), // Muestra el texto del item formateado.
              );
            }).toList(), // Convierte el iterable a una lista.
          ),
          const SizedBox(height: 16), // Espacio vertical de 16 píxeles.
        ],
      ),
    );
  }

  void _calculateAndDisplayResult() { // Método para calcular y mostrar el resultado.
    List<String?> missingFields = []; // Lista para almacenar campos faltantes.
    
    // Revisar campos obligatorios
    for (String field in ['Creación', 'SEO', 'Mantenimiento', 'Productos', 'Dominio', 'Hosting']) { // Itera sobre los campos obligatorios.
      if (_selectedOptions[field] == null) { // Verifica si el campo está vacío.
        missingFields.add(field); // Añade el campo faltante a la lista.
      }
    }

    // Revisar campo de Blogs solo si SEO Avanzado está seleccionado
    if (_selectedOptions['SEO'] == 'seo_avanzado' && _selectedOptions['Blogs'] == null) { // Verifica si SEO Avanzado está seleccionado y Blogs está vacío.
      missingFields.add('Blogs'); // Añade 'Blogs' a la lista de campos faltantes.
    }

    // Si hay campos faltantes, mostrar un mensaje
    if (missingFields.isNotEmpty) { // Si hay campos faltantes.
      String message = 'Por favor, selecciona una opción en los siguientes campos antes de continuar:\n'; // Mensaje de advertencia.
      message += missingFields.join(', '); // Agrega los campos faltantes al mensaje.
      _resultController.text = message; // Muestra el mensaje en el controlador de texto.
      return; // Sale del método.
    }

    int precioValorOfrecido = 0; // Inicializa el precio total ofrecido.
    int precioNacional = 0; // Inicializa el precio nacional.
    int precioInternacional = 0; // Inicializa el precio internacional.

    _selectedOptions.forEach((key, value) { // Itera sobre las opciones seleccionadas.
      if (value != null && precios.containsKey(value)) { // Verifica que la opción no sea nula y esté en precios.
        precioValorOfrecido += (precios[value]?['valor_ofrecido'] as num? ?? 0).round(); // Suma el precio ofrecido.
        precioNacional += (precios[value]?['nacional'] as num? ?? 0).round(); // Suma el precio nacional.
        precioInternacional += (precios[value]?['internacional'] as num? ?? 0).round(); // Suma el precio internacional.
      }
    });

    String blogsText = ''; // Inicializa el texto de blogs.
    if (_selectedOptions['SEO'] == 'seo_avanzado') { // Verifica si SEO Avanzado está seleccionado.
      blogsText = 'Opción de Blogs: ${_getOptionText(_selectedOptions['Blogs'], 'Blogs')}'; // Agrega el texto de la opción de blogs.
    }

    String result = ''' 
Resumen de Cotización

Opción de Creación: ${_getOptionText(_selectedOptions['Creación'], 'Creación')}
Opción de SEO: ${_getOptionText(_selectedOptions['SEO'], 'SEO')}
$blogsText
Opción de Mantenimiento: ${_getOptionText(_selectedOptions['Mantenimiento'], 'Mantenimiento')}
Opción de Productos: ${_getOptionText(_selectedOptions['Productos'], 'Productos')}
Opción de Dominio: ${_getOptionText(_selectedOptions['Dominio'], 'Dominio')}
Opción de Hosting: ${_getOptionText(_selectedOptions['Hosting'], 'Hosting')}

Precios

Precio Valor Ofrecido: \$${_formatNumberWithDots(precioValorOfrecido)} 
Precio Nacional: \$${_formatNumberWithDots(precioNacional)} 
Precio Internacional: \$${_formatNumberWithDots(precioInternacional)} 
''';

    _resultController.text = result; // Muestra el resultado en el controlador de texto.
  }

  String? _getOptionText(String? value, String label) { // Método para obtener el texto de la opción seleccionada.
    if (value == null) return null; // Si el valor es nulo, retorna nulo.
    return _formatOptionWithPrice(value); // Devuelve el texto de la opción formateado.
  }
}
