import 'package:flutter/material.dart';
// Importa el script de servicio de Firebase
import 'firebase_service.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ServicioFirebase.inicializarFirebase();
  await ServicioFirebase.obtenerPrecios();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  AppState createState() => AppState();
}

class AppState extends State<MyApp> {
  final Map<String, String?> _opcionesSeleccionadas = {};
  final TextEditingController _controladorResultado = TextEditingController();

  // Definir los colores personalizados - mantenemos los mismos
  final Color colorPrimario =
      const Color.fromARGB(255, 59, 59, 59); // #2ccacbff
  final Color colorSecundario =
      const Color.fromARGB(255, 155, 154, 154); // #ff7387ff
  final Color colorFondo = const Color.fromARGB(
      255, 240, 240, 240); // Cambiado a blanco para más elegancia

  // Índice del formulario actual
  int _indiceFormularioActual = 0;

  // Estado de finalización
  bool _formularioFinalizado = false;

  // Lista de etiquetas para controlar la navegación
  final List<String> _etiquetasFormularios = [
    'Creación',
    'SEO',
    'Blogs',
    'Mantenimiento',
    'Productos',
    'Dominio',
    'Hosting'
  ];

  @override
  Widget build(BuildContext context) {
    // Determinar si la pantalla es pequeña (vertical) o grande (horizontal)
    final bool esPantallaHorizontal = MediaQuery.of(context).size.width > 767;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'COTIZA WEB BUILDER',
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: colorPrimario,
          secondary: colorSecundario,
          background: colorFondo,
          surface: Colors.white,
          onSurface: Colors.black87,
        ),
        scaffoldBackgroundColor: colorFondo,
        appBarTheme: AppBarTheme(
          backgroundColor: colorPrimario,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorPrimario,
            foregroundColor: Colors.white,
            // padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30), // Bordes cuadrados
            ),
            elevation: 0, // Sin sombra para un look más plano y formal
          ),
        ),
        cardTheme: CardTheme(
          elevation: 0, // Sin sombras
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30), // Bordes cuadrados
            side: BorderSide(
                color: Colors.grey.shade300, width: 1), // Borde sutil
          ),
          color: Colors.white,
        ),
        textTheme: const TextTheme(
          headlineMedium:
              TextStyle(fontWeight: FontWeight.w500, letterSpacing: 0.5),
          titleLarge:
              TextStyle(fontWeight: FontWeight.w500, letterSpacing: 0.5),
          titleMedium: TextStyle(
              fontWeight: FontWeight.w400), // Más ligero para elegancia
          bodyLarge: TextStyle(fontSize: 16),
          bodyMedium: TextStyle(fontSize: 15),
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Stack(
            children: [
              // Texto con borde blanco
              Text(
                'COTIZA TU WEB',
                style: GoogleFonts.poppins(
                  fontSize: 24, // Ajusta el tamaño
                  letterSpacing: 1,
                  fontWeight: FontWeight.w900,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 3
                    ..color = Colors.white, // Borde blanco
                ),
              ),
              // Texto principal
              Text(
                'COTIZA TU WEB',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w900,
                  color: colorSecundario, // Color principal
                ),
              ),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(
              24.0), // Más padding para más espaciado elegante
          child: esPantallaHorizontal
              ? _construirLayoutHorizontal()
              : _construirLayoutVertical(),
        ),
      ),
    );
  }

  // Layout para pantallas horizontales (más de 767px)
  Widget _construirLayoutHorizontal() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sección A (70% del ancho)
        Expanded(
          flex: 7,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: colorPrimario, width: 2.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32.0), // Más padding para elegancia
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Indicador de progreso
                  _construirIndicadorProgreso(),
                  const SizedBox(height: 32), // Más espacio
                  // const Text(
                  //   'Selección de Servicios',
                  //   style: TextStyle(
                  //     fontSize: 24,
                  //     fontWeight: FontWeight.w300, // Más ligero para elegancia
                  //     color: Colors.black87,
                  //     letterSpacing: 1.0, // Más espaciado para elegancia
                  //   ),
                  // ),
                  // Container(
                  //   height: 1, // Línea divisoria más fina
                  //   color: const Color.fromARGB(60, 0, 0, 0),
                  //   margin: const EdgeInsets.symmetric(
                  //       vertical: 4, horizontal: 60), // Espacio para respirar
                  // ),
                  // Formulario actual
                  Expanded(
                    child: SingleChildScrollView(
                      child: _construirFormularioActual(),
                    ),
                  ),
                  // Botones de navegación
                  _construirBotonesNavegacion(),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 24), // Más espacio entre columnas
        // Sección B (30% del ancho)
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: colorPrimario, width: 2.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32.0), // Más padding para elegancia
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formularioFinalizado
                        ? 'Cotización de su Web'
                        : 'Cotización Parcial',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w300, // Más ligero para elegancia
                      color: Colors.black87,
                      letterSpacing: 1.0, // Más espaciado para elegancia
                    ),
                  ),
                  Container(
                    height: 1, // Línea divisoria más fina
                    color: colorPrimario,
                    margin: const EdgeInsets.symmetric(
                        vertical: 14), // Espacio para respirar
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controladorResultado,
                      maxLines: 15,
                      readOnly: true,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.6, // Más altura de línea
                      ),
                      decoration: InputDecoration(
                        hintText: 'Aún no hay items seleccionados',
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(0), // Bordes cuadrados
                          borderSide: const BorderSide(
                            color: Color.fromARGB(112, 95, 95, 95),
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          // Borde cuando NO está enfocado
                          borderRadius: BorderRadius.circular(0),
                          borderSide: BorderSide(
                              color: Colors
                                  .grey.shade300), // ¡Correcto! Borde gris
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(0), // Bordes cuadrados
                          borderSide: BorderSide(
                            color: colorPrimario, // Color al enfocarse
                            width: 1,
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                        filled: false,
                        fillColor: const Color.fromARGB(
                            255, 255, 255, 255), // Fondo blanco
                      ),
                    ),
                  ),
                  _mostrarBotonesCotizacion(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Layout para pantallas verticales (menos de 767px)
  Widget _construirLayoutVertical() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sección de título
        Text(
          'Selección de Servicios',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w300, // Más ligero para elegancia
            color: Colors.black87,
            letterSpacing: 1.0, // Más espaciado para elegancia
          ),
        ),
        const SizedBox(height: 20),
        // Indicador de progreso
        _construirIndicadorProgreso(),
        const SizedBox(height: 24),
        // Sección A
        Expanded(
          flex: 6,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Formulario actual
                  Expanded(
                    child: SingleChildScrollView(
                      child: _construirFormularioActual(),
                    ),
                  ),
                  // Botones de navegación
                  _construirBotonesNavegacion(),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24), // Más espacio entre secciones
        // Sección B
        Expanded(
          flex: 4,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formularioFinalizado
                        ? 'Cotización de su Web'
                        : 'Cotización Parcial',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w300, // Más ligero para elegancia
                      color: Colors.black87,
                      letterSpacing: 1.0, // Más espaciado para elegancia
                    ),
                  ),
                  Container(
                    height: 1, // Línea divisoria más fina
                    color: Colors.grey.shade200,
                    margin: const EdgeInsets.symmetric(
                        vertical: 20), // Espacio para respirar
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controladorResultado,
                      maxLines: null,
                      readOnly: true,
                      style: const TextStyle(
                          fontSize: 14, height: 1.6), // Más altura de línea
                      decoration: InputDecoration(
                        hintText: 'Aún no hay items seleccionados',
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(0), // Bordes cuadrados
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(0), // Bordes cuadrados
                          borderSide:
                              BorderSide(color: colorPrimario, width: 1),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                  ),
                  _mostrarBotonesCotizacion(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Construye el indicador de progreso - rediseñado para ser más elegante
  Widget _construirIndicadorProgreso() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Selección Etapa ${_indiceFormularioActual + 1}',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w400,
                letterSpacing: 1.0,
                color: Colors.black,
              ),
            ),
            Text(
              '${_indiceFormularioActual + 1}/${_etiquetasFormularios.length}',
              style: TextStyle(
                color: colorPrimario,
                fontWeight: FontWeight.w400,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Indicador de progreso elegante
        Container(
          height: 2, // Barra fina para elegancia
          child: LinearProgressIndicator(
            value: (_indiceFormularioActual + 1) / _etiquetasFormularios.length,
            backgroundColor: colorSecundario,
            color: colorPrimario,
            minHeight: 2,
            borderRadius: BorderRadius.zero, // Sin bordes redondeados
          ),
        ),
      ],
    );
  }

  // Construye el formulario actual según el índice
  Widget _construirFormularioActual() {
    String etiquetaActual = _etiquetasFormularios[_indiceFormularioActual];

    // Determina si el formulario de Blogs debe ser visible (solo si SEO avanzado está seleccionado)
    bool mostrarBlogs = etiquetaActual == 'Blogs' &&
        _opcionesSeleccionadas['SEO'] == 'seo_avanzado';

    // Si es el formulario de Blogs y SEO no es avanzado, saltamos al siguiente formulario
    if (etiquetaActual == 'Blogs' &&
        _opcionesSeleccionadas['SEO'] != 'seo_avanzado') {
      // Avanzamos automáticamente al siguiente formulario
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _indiceFormularioActual++;
          // Eliminamos Blogs de las opciones seleccionadas si no es SEO avanzado
          _opcionesSeleccionadas.remove('Blogs');
          _actualizarCotizacion();
        });
      });
      return const Center(child: CircularProgressIndicator());
    }

    switch (etiquetaActual) {
      case 'Creación':
        return _construirDescripcionYDropdown(
          'Creación',
          [
            'Adaptación de plantilla: Uso y ajuste de una plantilla preexistente.',
            'Personalización de plantilla: Modificación de una plantilla existente según requerimientos específicos.',
            'Creación personalizada desde cero: Diseño y desarrollo de un sitio web totalmente a medida.',
          ],
          [
            'adaptacion_plantilla',
            'personalizacion_plantilla',
            'creacion_personalizada',
          ],
        );
      case 'SEO':
        return _construirDescripcionYDropdown(
          'SEO',
          [
            'SEO Básico: Optimización básica para motores de búsqueda.',
            'SEO Avanzado: Optimización avanzada para motores de búsqueda, incluyendo creación de blogs.',
            'Sin SEO: No se aplica optimización para motores de búsqueda.',
          ],
          [
            'seo_basico',
            'seo_avanzado',
            'sin_seo',
          ],
        );
      case 'Blogs':
        return _construirDescripcionYDropdown(
          'Blogs',
          [
            'Blogs: Creación de contenido de blogs, sólo disponible con SEO Avanzado.',
          ],
          [
            '0_blogs',
            '1_blog',
            '2_blog',
            '3_blog',
            '4_blog',
          ],
          visible: mostrarBlogs,
        );
      case 'Mantenimiento':
        return _construirDescripcionYDropdown(
          'Mantenimiento',
          [
            'Mantenimiento Básico: Soporte básico y actualizaciones periódicas.',
            'Mantenimiento Estándar: Soporte intermedio con actualizaciones más frecuentes.',
            'Mantenimiento Avanzado: Soporte completo con actualizaciones regulares y soporte prioritario dentro del horario laboral. Incluye creación de un blog al mes.',
            'Sin Mantenimiento: No se incluye servicio de mantenimiento.',
          ],
          [
            'mantenimiento_basico',
            'mantenimiento_estandar',
            'mantenimiento_avanzado',
            'sin_mantenimiento',
          ],
        );
      case 'Productos':
        return _construirDescripcionYDropdown(
          'Productos',
          [
            'Limite de Productos: Restricción en el número de productos gestionables en la web.',
          ],
          [
            'limite_25_productos',
            'limite_50_productos',
            'limite_100_productos',
            'limite_150_productos',
            'limite_500_productos',
            'ilimitado_productos',
          ],
        );
      case 'Dominio':
        return _construirDescripcionYDropdown(
          'Dominio',
          [
            'Dominio: Incluye la gestión del dominio.',
          ],
          [
            'dominio_previo',
            'sin_dominio_previo',
          ],
        );
      case 'Hosting':
        return _construirDescripcionYDropdown(
          'Hosting',
          [
            'Hosting: Incluye el servicio de hosting para la web.',
          ],
          [
            'hosting_previo',
            'sin_hosting_previo',
          ],
        );
      default:
        return const SizedBox();
    }
  }

  // Construye los botones de navegación (Anterior/Siguiente) - Rediseñados para ser más elegantes
  Widget _construirBotonesNavegacion() {
    bool esPrimerFormulario = _indiceFormularioActual == 0;
    bool esUltimoFormulario =
        _indiceFormularioActual == _etiquetasFormularios.length - 1;

    return Padding(
      padding: const EdgeInsets.only(top: 32.0), // Más espacio arriba
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Botón Anterior (no mostrar en el primer formulario)
          if (!esPrimerFormulario)
            TextButton.icon(
              icon: const Icon(
                Icons.arrow_back,
                size: 16,
                color: Colors.white,
              ),
              label: const Text('Anterior',
                  style: TextStyle(
                      letterSpacing: 0.5, fontWeight: FontWeight.w400)),
              onPressed: () {
                setState(() {
                  _indiceFormularioActual--;

                  if (_etiquetasFormularios[_indiceFormularioActual] ==
                          'Blogs' &&
                      _opcionesSeleccionadas['SEO'] != 'seo_avanzado') {
                    _indiceFormularioActual--;
                  }

                  _formularioFinalizado = false;
                  _actualizarCotizacion();
                });
              },
              style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color.fromARGB(255, 0, 0, 0)),
            )
          else
            const SizedBox(),

          // Botón Siguiente o Finalizar
          if (!esUltimoFormulario)
            ElevatedButton.icon(
              icon: const Icon(
                Icons.arrow_forward,
                size: 16,
                color: Colors.white,
              ),
              label: const Text('Siguiente',
                  style: TextStyle(
                      letterSpacing: 0.5, fontWeight: FontWeight.w400)),
              onPressed: _puedeAvanzarAlSiguiente()
                  ? () {
                      setState(() {
                        _indiceFormularioActual++;

                        if (_etiquetasFormularios[_indiceFormularioActual] ==
                                'Blogs' &&
                            _opcionesSeleccionadas['SEO'] != 'seo_avanzado') {
                          _indiceFormularioActual++;
                        }

                        _actualizarCotizacion();
                      });
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                  disabledBackgroundColor: colorPrimario.withOpacity(0.3),
                  foregroundColor: Colors.white,
                  backgroundColor: const Color.fromARGB(255, 0, 0, 0)),
            )
          else
            ElevatedButton.icon(
              icon: const Icon(
                Icons.check,
                size: 16,
                color: Color.fromARGB(255, 255, 255, 255),
              ),
              label: const Text('Finalizar',
                  style: TextStyle(
                      letterSpacing: 0.5, fontWeight: FontWeight.w400)),
              onPressed: _puedeAvanzarAlSiguiente()
                  ? () {
                      setState(() {
                        _formularioFinalizado = true;
                        _actualizarCotizacion();
                      });
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                disabledBackgroundColor: colorPrimario.withOpacity(0.3),
                foregroundColor: Colors.white,
                backgroundColor: const Color.fromARGB(255, 0, 0, 0),
              ),
            ),
        ],
      ),
    );
  }

  // Verifica si se puede avanzar al siguiente formulario
  bool _puedeAvanzarAlSiguiente() {
    String etiquetaActual = _etiquetasFormularios[_indiceFormularioActual];

    // Si es el formulario de Blogs y SEO no es avanzado, permitimos avanzar
    if (etiquetaActual == 'Blogs' &&
        _opcionesSeleccionadas['SEO'] != 'seo_avanzado') {
      return true;
    }

    // Para otros formularios, verificamos que haya una opción seleccionada
    return _opcionesSeleccionadas.containsKey(etiquetaActual) &&
        _opcionesSeleccionadas[etiquetaActual] != null;
  }

  // Actualiza la cotización parcial
  void _actualizarCotizacion() {
    int precioValorOfrecido = 0;
    int precioNacional = 0;
    int precioInternacional = 0;

    String cotizacionParcial = 'Resumen de Cotización\n\n';

    _opcionesSeleccionadas.forEach((clave, valor) {
      if (valor != null && ServicioFirebase.precios.containsKey(valor)) {
        precioValorOfrecido +=
            (ServicioFirebase.precios[valor]?['valor_ofrecido'] as num? ?? 0)
                .round();
        precioNacional +=
            (ServicioFirebase.precios[valor]?['nacional'] as num? ?? 0).round();
        precioInternacional +=
            (ServicioFirebase.precios[valor]?['internacional'] as num? ?? 0)
                .round();

        // Agregamos esta opción al resumen
        cotizacionParcial += '$clave: ${_obtenerTextoOpcion(valor, clave)}\n';
      }
    });

    cotizacionParcial += '\nPrecios Estimados\n\n';
    cotizacionParcial +=
        'Precio Valor Ofrecido: \$${ServicioFirebase.formatearNumeroConPuntos(precioValorOfrecido)}\n';
    cotizacionParcial +=
        'Precio Nacional: \$${ServicioFirebase.formatearNumeroConPuntos(precioNacional)}\n';
    cotizacionParcial +=
        'Precio Internacional: \$${ServicioFirebase.formatearNumeroConPuntos(precioInternacional)}';

    _controladorResultado.text = cotizacionParcial;
  }

  // Muestra u oculta los botones de cotización final - rediseñados para ser más elegantes
  Widget _mostrarBotonesCotizacion() {
    if (_formularioFinalizado && _todoFormularioCompleto()) {
      return Padding(
        padding: const EdgeInsets.only(top: 24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.email, size: 16),
              label: const Text('Enviar Cotización',
                  style: TextStyle(
                      letterSpacing: 0.5, fontWeight: FontWeight.w400)),
              onPressed: () {
                // TODO: Implementar envío de cotización
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorSecundario,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.download, size: 16, color: Colors.white,),
              label: const Text('Descargar',
                  style: TextStyle(
                      letterSpacing: 0.5, fontWeight: FontWeight.w400)),
              onPressed: () {
                // TODO: Implementar descarga de cotización
              },
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox();
  }

  // Verifica si todo el formulario está completo
  bool _todoFormularioCompleto() {
    List<String> formularioObligatorios = [
      'Creación',
      'SEO',
      'Mantenimiento',
      'Productos',
      'Dominio',
      'Hosting'
    ];

    if (_opcionesSeleccionadas['SEO'] == 'seo_avanzado') {
      formularioObligatorios.add('Blogs');
    }

    for (String formulario in formularioObligatorios) {
      if (!_opcionesSeleccionadas.containsKey(formulario) ||
          _opcionesSeleccionadas[formulario] == null) {
        return false;
      }
    }

    return true;
  }

  // Rediseñado para un aspecto más profesional y formal
  Widget _construirDescripcionYDropdown(
      String etiqueta, List<String> descripciones, List<String> opciones,
      {bool visible = true}) {
    return Visibility(
      visible: visible,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiqueta,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w300, // Más ligero para elegancia
              color: Colors.black87,
              letterSpacing: 0.8, // Más espaciado para elegancia
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 1, // Línea más fina
            width: 150,
            color: colorSecundario,
            margin: const EdgeInsets.only(bottom: 20),
          ),
          ...descripciones.map((desc) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  desc,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    height:
                        1.6, // Mayor espacio entre líneas para mejor lectura
                    letterSpacing: 0.3, // Ligero espaciado para más elegancia
                  ),
                ),
              )),
          const SizedBox(height: 24), // Más espacio
          DropdownButtonFormField<String?>(
            value: _opcionesSeleccionadas[etiqueta],
            onChanged: (valor) {
              setState(() {
                _opcionesSeleccionadas[etiqueta] = valor;

                // Si cambiamos SEO de avanzado a otra opción, eliminamos Blogs
                if (etiqueta == 'SEO' && valor != 'seo_avanzado') {
                  _opcionesSeleccionadas.remove('Blogs');
                  _actualizarCotizacion();
                }
              });
            },
            dropdownColor: Colors.white,
            decoration: InputDecoration(
              labelText: 'Seleccione una opción',
              labelStyle:
                  TextStyle(color: Colors.grey.shade600, letterSpacing: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(0), // Bordes cuadrados
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(0), // Bordes cuadrados
                borderSide: BorderSide(color: colorPrimario, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(0), // Bordes cuadrados
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            icon: Icon(Icons.keyboard_arrow_down, color: colorPrimario),
            isExpanded: true,
            items: opciones.map((opcion) {
              return DropdownMenuItem<String?>(
                value: opcion,
                child: Text(
                  ServicioFirebase.formatearOpcionConPrecio(opcion),
                  style: const TextStyle(
                    fontSize: 15,
                    letterSpacing: 0.3, // Ligero espaciado para más elegancia
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32), // Más espacio para dar "aire" al diseño
        ],
      ),
    );
  }

  String? _obtenerTextoOpcion(String? valor, String etiqueta) {
    if (valor == null) return null;
    return ServicioFirebase.formatearOpcionConPrecio(valor);
  }
}
