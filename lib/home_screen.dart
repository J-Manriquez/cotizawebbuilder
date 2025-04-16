// ignore_for_file: unused_local_variable, unused_import

// Importaciones estándar de Flutter y Dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Para fuentes personalizadas en la UI

// Importa el servicio de Firebase para acceder a precios y formateo
import 'firebase_service.dart';
// Importa los componentes de UI reutilizables
import 'ui_components.dart';
// Importa MyApp para acceder a los colores estáticos
import 'main.dart'; // Para acceder a MyApp.colorPrimario, etc.
// Importa el NUEVO servicio para manejar la lógica del PDF
import 'pdf_service.dart';
import 'confirmation_screen.dart'; // Importa la nueva pantalla
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- Estado de la Aplicación ---
  final Map<String, String?> _opcionesSeleccionadas = {};
  final TextEditingController _controladorResultado = TextEditingController();
  int _indiceFormularioActual = 0;
  bool _formularioFinalizado = false;

  // Lista de etiquetas para controlar la navegación y formularios
  final List<String> _etiquetasFormularios = [
    'Creación',
    'SEO',
    'Blogs', // Se manejará la lógica de visibilidad
    'Mantenimiento',
    'Productos',
    'Dominio',
    'Hosting'
  ];

  // --- Instancia del Servicio PDF ---
  // Se crea una instancia del servicio que encapsula la lógica del PDF
  final PdfService _pdfService = PdfService();
  bool _pdfFontsReady =
      false; // Estado para saber si las fuentes PDF están listas

  // --- Ciclo de Vida del Widget ---

  @override
  void initState() {
    super.initState();
    // Llama a la inicialización asíncrona que carga las fuentes del PDF
    _initializeAsyncDependencies();
  }

  // Método para manejar inicializaciones asíncronas como la carga de fuentes
  Future<void> _initializeAsyncDependencies() async {
    try {
      // Llama al método del servicio para cargar las fuentes necesarias para el PDF
      await _pdfService.loadFonts();
      setState(() {
        _pdfFontsReady =
            true; // Actualiza el estado indicando que las fuentes están listas
      });
      print("Fuentes PDF inicializadas correctamente desde HomeScreen.");
    } catch (e) {
      // Si ocurre un error al cargar las fuentes, se informa y se actualiza el estado
      print("Error al inicializar fuentes PDF desde HomeScreen: $e");
      setState(() {
        _pdfFontsReady = false;
      });
      // Muestra un mensaje al usuario sobre el error
      if (mounted) {
        // Verifica si el widget todavía está montado antes de mostrar el SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Error al preparar las fuentes para PDF: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _controladorResultado.dispose(); // Limpiar el controlador de texto
    super.dispose();
  }

  // --- Lógica de Negocio (Formulario y Cotización) ---

  // Verifica si se puede avanzar al siguiente formulario
  bool _puedeAvanzarAlSiguiente() {
    String etiquetaActual = _etiquetasFormularios[_indiceFormularioActual];

    // Caso especial: Blogs no requiere selección si SEO no es avanzado
    if (etiquetaActual == 'Blogs' &&
        _opcionesSeleccionadas['SEO'] != 'seo_avanzado') {
      return true; // Se permite avanzar (saltará automáticamente)
    }

    // Para otros formularios, se requiere una selección
    return _opcionesSeleccionadas.containsKey(etiquetaActual) &&
        _opcionesSeleccionadas[etiquetaActual] != null;
  }

  // Actualiza la cotización mostrada en el TextField
  void _actualizarCotizacion() {
    int precioValorOfrecido = 0;
    int precioNacional = 0;
    int precioInternacional = 0;
    String cotizacionTexto = 'Resumen de Cotización\n\n';

    _opcionesSeleccionadas.forEach((clave, valor) {
      if (valor != null && ServicioFirebase.precios.containsKey(valor)) {
        // Usa la función del servicio Firebase para formatear la descripción y precios
        cotizacionTexto +=
            '$clave: ${ServicioFirebase.formatearOpcionConPrecio(valor)}\n';

        final precioData = ServicioFirebase.precios[valor]!;
        precioValorOfrecido +=
            (precioData['valor_ofrecido'] as num? ?? 0).round();
        precioNacional += (precioData['nacional'] as num? ?? 0).round();
        precioInternacional +=
            (precioData['internacional'] as num? ?? 0).round();
      }
    });

    cotizacionTexto += '\nPrecios Estimados\n\n';
    // Usa la función del servicio Firebase para formatear los números totales
    cotizacionTexto +=
        'Precio Valor Ofrecido: \$${ServicioFirebase.formatearNumeroConPuntos(precioValorOfrecido)}\n';
    cotizacionTexto +=
        'Precio Nacional: \$${ServicioFirebase.formatearNumeroConPuntos(precioNacional)}\n';
    cotizacionTexto +=
        'Precio Internacional: \$${ServicioFirebase.formatearNumeroConPuntos(precioInternacional)}';

    _controladorResultado.text = cotizacionTexto;
  }

  // Verifica si todos los formularios obligatorios están completos
  bool _todoFormularioCompleto() {
    List<String> formulariosObligatorios =
        _etiquetasFormularios.where((etiqueta) => etiqueta != 'Blogs').toList();

    if (_opcionesSeleccionadas['SEO'] == 'seo_avanzado') {
      formulariosObligatorios.add('Blogs');
    }

    for (String etiqueta in formulariosObligatorios) {
      if (!_opcionesSeleccionadas.containsKey(etiqueta) ||
          _opcionesSeleccionadas[etiqueta] == null) {
        return false;
      }
    }
    return true;
  }

  // Navega al formulario anterior
  void _irAFormularioAnterior() {
    setState(() {
      _indiceFormularioActual--;
      if (_indiceFormularioActual > 0 &&
          _etiquetasFormularios[_indiceFormularioActual] == 'Blogs' &&
          _opcionesSeleccionadas['SEO'] != 'seo_avanzado') {
        _indiceFormularioActual--;
      }
      _formularioFinalizado = false;
      _actualizarCotizacion();
    });
  }

  // Navega al siguiente formulario o finaliza
  void _irAFormularioSiguienteOFinalizar() {
    if (!_puedeAvanzarAlSiguiente()) return;

    setState(() {
      bool esUltimoPasoVisibleAntesDeFinalizar = _esUltimoFormularioVisible();

      if (esUltimoPasoVisibleAntesDeFinalizar) {
        _formularioFinalizado = true;
      } else {
        _indiceFormularioActual++;
        _formularioFinalizado = false;

        int indiceBlogs = _etiquetasFormularios.indexOf('Blogs');
        bool seoAvanzadoSeleccionado =
            _opcionesSeleccionadas['SEO'] == 'seo_avanzado';

        if (_indiceFormularioActual == indiceBlogs &&
            !seoAvanzadoSeleccionado) {
          if (_indiceFormularioActual < _etiquetasFormularios.length - 1) {
            _indiceFormularioActual++;
          } else {
            _formularioFinalizado = true;
          }
        }
      }
      _actualizarCotizacion();
    });
  }

  // Determina si el índice actual corresponde al último *visible* formulario
  bool _esUltimoFormularioVisible() {
    int indiceActual = _indiceFormularioActual;
    int totalPasos = _etiquetasFormularios.length;
    int ultimoIndiceReal = totalPasos - 1;

    if (indiceActual == ultimoIndiceReal) {
      return true;
    }

    int indiceBlogs = _etiquetasFormularios.indexOf('Blogs');
    bool seoAvanzadoSeleccionado =
        _opcionesSeleccionadas['SEO'] == 'seo_avanzado';

    if (indiceActual == indiceBlogs - 1 && !seoAvanzadoSeleccionado) {
      int indiceDestino = indiceBlogs + 1;
      return indiceDestino >= ultimoIndiceReal;
    }

    return false;
  }

  // Maneja el cambio de selección en un dropdown
  void _onDropdownChanged(String etiqueta, String? valor) {
    setState(() {
      _opcionesSeleccionadas[etiqueta] = valor;

      if (etiqueta == 'SEO' && valor != 'seo_avanzado') {
        if (_opcionesSeleccionadas.containsKey('Blogs')) {
          _opcionesSeleccionadas.remove('Blogs');
        }
      }
      _actualizarCotizacion();
    });
  }

  // --- Manejador para la Generación/Descarga/Compartir PDF ---
  // Este método ahora llama al servicio PDF
  Future<void> _handlePdfGeneration() async {
    // Verifica si las fuentes PDF están listas (cargadas en initState)
    if (!_pdfFontsReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Las fuentes para el PDF aún no están listas. Por favor, espere.')),
      );
      // Podrías intentar cargarlas de nuevo o simplemente informar al usuario
      // await _initializeAsyncDependencies(); // Opcional: Reintentar carga
      // if (!_pdfFontsReady) return; // Salir si aún no están listas
      return;
    }

    // Opcional: Mostrar un indicador de progreso mientras se genera el PDF
    showDialog(
      context: context,
      barrierDismissible: false, // El usuario no puede cerrar el diálogo
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      // Llama al método del servicio PDF para generar y manejar el archivo
      await _pdfService.generateAndHandlePdf(
        opcionesSeleccionadas:
            _opcionesSeleccionadas, // Pasa las opciones actuales
        // baseFilename: 'cotizacion-mi-empresa', // Opcional: nombre de archivo base personalizado
      );

      // Cierra el diálogo de progreso si la operación fue exitosa
      if (mounted) Navigator.of(context).pop();

      // Muestra un mensaje de éxito (opcional)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF procesado correctamente.')),
        );
      }
    } catch (e) {
      // Cierra el diálogo de progreso en caso de error
      if (mounted) Navigator.of(context).pop();

      // Muestra un mensaje de error detallado al usuario
      print('Error capturado en HomeScreen al generar/manejar PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar el PDF: ${e.toString()}')),
        );
      }
    }
  }

  // --- Construcción de la UI ---

  @override
  Widget build(BuildContext context) {
    final bool esPantallaHorizontal = MediaQuery.of(context).size.width > 767;
    const Color colorPrimario = MyApp.colorPrimario;
    const Color colorSecundario = MyApp.colorSecundario;

    return Scaffold(
      appBar: AppBar(
        title: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              'COTIZA TU WEB',
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
              'COTIZA TU WEB',
              style: GoogleFonts.poppins(
                fontSize: 24,
                letterSpacing: 1,
                fontWeight: FontWeight.w900,
                color: colorSecundario,
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: esPantallaHorizontal
            ? _buildHorizontalLayout(context)
            : _buildVerticalLayout(context),
      ),
    );
  }

  // Layout para pantallas horizontales (anchas)
  Widget _buildHorizontalLayout(BuildContext context) {
    const Color colorPrimario = MyApp.colorPrimario;
    const Color colorSecundario = MyApp.colorSecundario;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sección Izquierda (Formulario)
        Expanded(
          flex: 7,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: colorPrimario, width: 2.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UIComponents.buildProgressIndicator(
                    currentIndex: _indiceFormularioActual,
                    totalSteps: _etiquetasFormularios.length,
                    primaryColor: colorPrimario,
                    secondaryColor: colorSecundario,
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: SingleChildScrollView(
                      child: _buildCurrentFormSection(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  UIComponents.buildNavigationButtons(
                    currentIndex: _indiceFormularioActual,
                    totalSteps: _etiquetasFormularios.length,
                    canProceed: _puedeAvanzarAlSiguiente(),
                    isLastVisibleStep: _esUltimoFormularioVisible(),
                    onBackPressed: _indiceFormularioActual > 0
                        ? _irAFormularioAnterior
                        : null,
                    onNextPressed: _irAFormularioSiguienteOFinalizar,
                    primaryColor: colorPrimario,
                    context: context,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        // Sección Derecha (Cotización)
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: colorPrimario, width: 2.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formularioFinalizado
                        ? 'Cotización Final'
                        : 'Cotización Parcial',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1.0,
                        color: Colors.black87),
                  ),
                  Container(
                    height: 1,
                    color: colorPrimario,
                    margin: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controladorResultado,
                      maxLines: 18,
                      readOnly: true,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontSize: 14),
                      decoration: const InputDecoration(
                        hintText:
                            'Seleccione opciones para ver la cotización...',
                        contentPadding: EdgeInsets.all(16),
                        filled: false,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // --- BOTONES DE ACCIÓN FINAL RESTAURADOS ---
                  if (_formularioFinalizado && _todoFormularioCompleto())
                    UIComponents.buildFinalActionButtons(
                      context: context, // Pasa el contexto
                      onSendQuote: () {
                        // <--- AQUÍ VA LA NAVEGACIÓN
                        // Asegúrate que la cotización esté actualizada
                        _actualizarCotizacion();
                        // Navega a la pantalla de confirmación
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ConfirmationScreen(
                              opcionesSeleccionadas:
                                  Map.from(_opcionesSeleccionadas),
                              cotizacionTextoResumen:
                                  _controladorResultado.text,
                              pdfService: _pdfService,
                              pdfFontsReady: _pdfFontsReady,
                            ),
                          ),
                        );
                      },
                      onDownloadQuote:
                          _handlePdfGeneration, // La descarga sigue igual
                      primaryColor: colorPrimario,
                      secondaryColor: colorSecundario,
                      isDownloadEnabled: _pdfFontsReady,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Layout para pantallas verticales (estrechas)
  Widget _buildVerticalLayout(BuildContext context) {
    const Color colorPrimario = MyApp.colorPrimario;
    const Color colorSecundario = MyApp.colorSecundario;

    // Envuelve TODO en un SingleChildScrollView para evitar overflows
    return SingleChildScrollView(
        child: Padding(
      // Puedes ajustar el padding general aquí si es necesario
      padding: const EdgeInsets.all(0), // Ejemplo de padding general
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize
            .min, // Hace que la Column principal también se ajuste a su contenido
        children: [
          UIComponents.buildProgressIndicator(
            currentIndex: _indiceFormularioActual,
            totalSteps: _etiquetasFormularios.length,
            primaryColor: colorPrimario,
            secondaryColor: colorSecundario,
          ),
          const SizedBox(
              height: 24), // Espacio entre indicador y primer contenedor

          // --- Sección del Formulario con Altura Dinámica ---
          Container(
            // SIN height explícita
            width: double.infinity, // Ocupa todo el ancho disponible
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              // Considera añadir borderRadius si quieres esquinas redondeadas
              // borderRadius: BorderRadius.circular(8.0),
            ),
            padding: const EdgeInsets.all(15.0),
            child: Column(
              mainAxisSize: MainAxisSize
                  .min, // Clave: La columna interna se ajusta a sus hijos
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SIN Expanded aquí. El contenido determina la altura.
                _buildCurrentFormSection(),
                const SizedBox(height: 0), // Espacio antes de los botones
                UIComponents.buildNavigationButtons(
                  currentIndex: _indiceFormularioActual,
                  totalSteps: _etiquetasFormularios.length,
                  canProceed: _puedeAvanzarAlSiguiente(),
                  isLastVisibleStep: _esUltimoFormularioVisible(),
                  onBackPressed: _indiceFormularioActual > 0
                      ? _irAFormularioAnterior
                      : null,
                  onNextPressed: _irAFormularioSiguienteOFinalizar,
                  primaryColor: colorPrimario,
                  context: context,
                ),
              ],
            ),
          ),
          // --- ------------------------------------- ---

          const SizedBox(height: 24), // Espacio entre contenedores

          // --- Sección de Cotización con Altura Dinámica ---
          Container(
            // SIN height explícita
            width: double.infinity, // Ocupa todo el ancho disponible
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              // borderRadius: BorderRadius.circular(8.0),
            ),
            padding: const EdgeInsets.all(15.0),
            child: Column(
              mainAxisSize: MainAxisSize
                  .min, // Clave: La columna interna se ajusta a sus hijos
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formularioFinalizado
                      ? 'Cotización Final'
                      : 'Cotización Parcial',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1.0,
                      color: Colors.black87),
                ),
                Container(
                  height: 1,
                  color: Colors.grey.shade300,
                  margin: const EdgeInsets.symmetric(vertical: 14),
                ),
                // SIN Expanded aquí. El TextField tomará su altura natural (o la definida por maxLines)
                TextField(
                  controller: _controladorResultado,
                  // maxLines: null, // Permitirá crecer indefinidamente (puede ser mucho)
                  maxLines:
                      30, // O un número razonable de líneas visibles inicialmente
                  minLines: 8, // Mínimo de líneas a mostrar
                  readOnly: true,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Seleccione opciones para ver la cotización...',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.all(16),
                    border: InputBorder
                        .none, // Puedes usar OutlineInputBorder si prefieres
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
                const SizedBox(height: 16),
                // --- BOTONES DE ACCIÓN FINAL RESTAURADOS ---
                if (_formularioFinalizado && _todoFormularioCompleto())
                  UIComponents.buildFinalActionButtons(
                    context: context, // Pasa el contexto
                    onSendQuote: () {
                      // <--- AQUÍ VA LA NAVEGACIÓN
                      // Asegúrate que la cotización esté actualizada
                      _actualizarCotizacion();
                      // Navega a la pantalla de confirmación
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ConfirmationScreen(
                            opcionesSeleccionadas:
                                Map.from(_opcionesSeleccionadas),
                            cotizacionTextoResumen: _controladorResultado.text,
                            pdfService: _pdfService,
                            pdfFontsReady: _pdfFontsReady,
                          ),
                        ),
                      );
                    },
                    onDownloadQuote:
                        _handlePdfGeneration, // La descarga sigue igual
                    primaryColor: colorPrimario,
                    secondaryColor: colorSecundario,
                    isDownloadEnabled: _pdfFontsReady,
                  ),
              ],
            ),
          ),
          // --- ------------------------------------ ---
        ],
      ),
    ));
  }

  // Construye la sección del formulario correspondiente al índice actual
  // (Esta función permanece igual, ya que solo depende de los componentes UI y el estado local)
  Widget _buildCurrentFormSection() {
    if (ServicioFirebase.precios.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando precios...'),
          ],
        ),
      );
    }

    String etiquetaActual = _etiquetasFormularios[_indiceFormularioActual];
    bool esVisibleBlogs = etiquetaActual == 'Blogs' &&
        _opcionesSeleccionadas['SEO'] == 'seo_avanzado';

    switch (etiquetaActual) {
      case 'Creación':
        return UIComponents.buildDropdownSection(
          etiqueta: 'Creación',
          descripciones: const [
            'Adaptación de plantilla: Uso y ajuste de una plantilla preexistente.',
            'Personalización de plantilla: Modificación de una plantilla existente.',
            'Creación personalizada: Diseño y desarrollo a medida.',
          ],
          opciones: const [
            'adaptacion_plantilla',
            'personalizacion_plantilla',
            'creacion_personalizada',
          ],
          valorSeleccionado: _opcionesSeleccionadas[etiquetaActual],
          onChanged: (valor) => _onDropdownChanged(etiquetaActual, valor),
          primaryColor: MyApp.colorPrimario,
          secondaryColor: MyApp.colorSecundario,
        );
      case 'SEO':
        return UIComponents.buildDropdownSection(
          etiqueta: 'Optimización SEO',
          descripciones: const [
            'SEO Básico: Optimización esencial para motores de búsqueda.',
            'SEO Avanzado: Optimización completa, incluye estrategia de contenidos (blogs).',
            'Sin SEO: No se aplicará optimización específica.',
          ],
          opciones: const [
            'seo_basico',
            'seo_avanzado',
            'sin_seo',
          ],
          valorSeleccionado: _opcionesSeleccionadas[etiquetaActual],
          onChanged: (valor) => _onDropdownChanged(etiquetaActual, valor),
          primaryColor: MyApp.colorPrimario,
          secondaryColor: MyApp.colorSecundario,
        );
      case 'Blogs':
        return UIComponents.buildDropdownSection(
          etiqueta: 'Gestión de Blogs',
          descripciones: const [
            'Número de entradas de blog a crear por mes (requiere SEO Avanzado).',
          ],
          opciones: const [
            '0_blogs',
            '1_blog',
            '2_blog',
            '3_blog',
            '4_blog',
          ],
          valorSeleccionado: _opcionesSeleccionadas[etiquetaActual],
          onChanged: (valor) => _onDropdownChanged(etiquetaActual, valor),
          visible: esVisibleBlogs, // Controla si se muestra o no este widget
          primaryColor: MyApp.colorPrimario,
          secondaryColor: MyApp.colorSecundario,
        );
      case 'Mantenimiento':
        return UIComponents.buildDropdownSection(
          etiqueta: 'Mantenimiento Web Mensual',
          descripciones: const [
            'Básico: Soporte esencial y actualizaciones.',
            'Estándar: Soporte ampliado y actualizaciones frecuentes.',
            'Avanzado: Soporte prioritario, act. regulares, 1 blog/mes incluido.',
            'Sin Mantenimiento: El cliente gestiona el mantenimiento.',
          ],
          opciones: const [
            'mantenimiento_basico',
            'mantenimiento_estandar',
            'mantenimiento_avanzado',
            'sin_mantenimiento',
          ],
          valorSeleccionado: _opcionesSeleccionadas[etiquetaActual],
          onChanged: (valor) => _onDropdownChanged(etiquetaActual, valor),
          primaryColor: MyApp.colorPrimario,
          secondaryColor: MyApp.colorSecundario,
        );
      case 'Productos':
        return UIComponents.buildDropdownSection(
          etiqueta: 'Límite de Productos (e-commerce)',
          descripciones: const [
            'Número máximo de productos para tiendas online.',
          ],
          opciones: const [
            'limite_25_productos',
            'limite_50_productos',
            'limite_100_productos',
            'limite_150_productos',
            'limite_500_productos',
            'ilimitado_productos',
          ],
          valorSeleccionado: _opcionesSeleccionadas[etiquetaActual],
          onChanged: (valor) => _onDropdownChanged(etiquetaActual, valor),
          primaryColor: MyApp.colorPrimario,
          secondaryColor: MyApp.colorSecundario,
        );
      case 'Dominio':
        return UIComponents.buildDropdownSection(
          etiqueta: 'Gestión de Dominio',
          descripciones: const [
            '¿Necesitas registrar o transferir un dominio?',
          ],
          opciones: const [
            'dominio_previo', // El cliente ya tiene dominio
            'sin_dominio_previo', // Necesita registrar/gestionar
          ],
          valorSeleccionado: _opcionesSeleccionadas[etiquetaActual],
          onChanged: (valor) => _onDropdownChanged(etiquetaActual, valor),
          primaryColor: MyApp.colorPrimario,
          secondaryColor: MyApp.colorSecundario,
        );
      case 'Hosting':
        return UIComponents.buildDropdownSection(
          etiqueta: 'Alojamiento Web (Hosting)',
          descripciones: const [
            '¿Necesitas servicio de alojamiento para tu web?',
          ],
          opciones: const [
            'hosting_previo', // El cliente ya tiene hosting
            'sin_hosting_previo', // Necesita contratar/gestionar
          ],
          valorSeleccionado: _opcionesSeleccionadas[etiquetaActual],
          onChanged: (valor) => _onDropdownChanged(etiquetaActual, valor),
          primaryColor: MyApp.colorPrimario,
          secondaryColor: MyApp.colorSecundario,
        );

      default: // Caso por defecto si la etiqueta no coincide con ninguna esperada
        print(
            "Advertencia: Etiqueta de formulario no reconocida: $etiquetaActual");
        // Devuelve un widget vacío para evitar errores, pero indica que algo inesperado ocurrió.
        return const SizedBox.shrink();
    } // Fin del switch
  } // Fin del método _buildCurrentFormSection
} // Fin de la clase _HomeScreenState
