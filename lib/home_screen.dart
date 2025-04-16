// ignore_for_file: unused_local_variable

import 'dart:typed_data';
import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:google_fonts/google_fonts.dart';

// Importa el servicio de Firebase para acceder a precios y formateo
import 'firebase_service.dart';
// Importa los componentes de UI reutilizables
import 'ui_components.dart';
// Importa MyApp para acceder a los colores estáticos si es necesario (o defínelos aquí)
import 'main.dart'; // Para acceder a MyApp.colorPrimario, etc.

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

  // Variable para almacenar la fuente cargada para el PDF
  pw.Font? _robotoRegular;
  pw.Font? _robotoBold;
  pw.Font? _robotoItalic;

// --- Carga de Fuentes PDF ---
  Future<void> _loadPdfFonts() async {
    try {
      // assets/fonts/Roboto-Bold.ttf
      // Asegúrate que las rutas coincidan con tu estructura en assets/fonts/
      final fontDataRegular =
          await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      final fontDataBold =
          await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
      final fontDataItalic =
          await rootBundle.load('assets/fonts/Roboto-Italic.ttf');

      setState(() {
        // Actualiza el estado cuando las fuentes estén listas
        _robotoRegular = pw.Font.ttf(fontDataRegular.buffer.asByteData());
        _robotoBold = pw.Font.ttf(fontDataBold.buffer.asByteData());
        _robotoItalic = pw.Font.ttf(fontDataItalic.buffer.asByteData());
        print("Fuentes PDF cargadas correctamente.");
      });
    } catch (e) {
      print("Error cargando fuentes PDF: $e");
      // Manejar el error, quizás mostrar un mensaje o usar fuentes por defecto con advertencia
    }
  }

  // --- Lógica de Negocio ---
  @override
  void initState() {
    super.initState();
    _loadPdfFonts(); // Carga las fuentes al iniciar el estado
  }

  @override
  void dispose() {
    _controladorResultado.dispose(); // Limpiar el controlador
    super.dispose();
  }

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
    // Inicializa el texto del resumen
    String cotizacionTexto = 'Resumen de Cotización\n\n'; // Título inicial

    // Itera sobre las opciones seleccionadas válidas
    _opcionesSeleccionadas.forEach((clave, valor) {
      // Asegúrate de que la opción tenga un valor y exista en los precios
      if (valor != null && ServicioFirebase.precios.containsKey(valor)) {
        // --- ESTA ES LA PARTE CLAVE QUE FALTA O ES INCORRECTA ---
        // Añade la descripción formateada de la opción seleccionada al texto.
        // Usa directamente la función del servicio Firebase que formatea la opción.
        cotizacionTexto +=
            '$clave: ${ServicioFirebase.formatearOpcionConPrecio(valor)}\n';
        // ---------------------------------------------------------

        // Suma los precios correspondientes (esta parte parece estar bien)
        final precioData =
            ServicioFirebase.precios[valor]!; // Obtener datos del precio
        precioValorOfrecido +=
            (precioData['valor_ofrecido'] as num? ?? 0).round();
        precioNacional += (precioData['nacional'] as num? ?? 0).round();
        precioInternacional +=
            (precioData['internacional'] as num? ?? 0).round();
      }
    }); // Fin del forEach

    // Añade la sección de precios estimados
    cotizacionTexto += '\nPrecios Estimados\n\n'; // Título para los totales

    // Formatea los números totales con puntos usando el servicio de Firebase
    cotizacionTexto +=
        'Precio Valor Ofrecido: \$${ServicioFirebase.formatearNumeroConPuntos(precioValorOfrecido)}\n';
    cotizacionTexto +=
        'Precio Nacional: \$${ServicioFirebase.formatearNumeroConPuntos(precioNacional)}\n';
    cotizacionTexto +=
        'Precio Internacional: \$${ServicioFirebase.formatearNumeroConPuntos(precioInternacional)}'; // O usa 'USD $' si prefieres

    // Actualiza el controlador del TextField, lo que debería refrescar la UI
    _controladorResultado.text = cotizacionTexto;
  }

  // Verifica si todos los formularios obligatorios están completos
  bool _todoFormularioCompleto() {
    // Define las etiquetas obligatorias base
    List<String> formulariosObligatorios =
        _etiquetasFormularios.where((etiqueta) => etiqueta != 'Blogs').toList();

    // Añade 'Blogs' solo si SEO avanzado está seleccionado
    if (_opcionesSeleccionadas['SEO'] == 'seo_avanzado') {
      formulariosObligatorios.add('Blogs');
    }

    // Verifica que cada formulario obligatorio tenga una selección
    for (String etiqueta in formulariosObligatorios) {
      if (!_opcionesSeleccionadas.containsKey(etiqueta) ||
          _opcionesSeleccionadas[etiqueta] == null) {
        return false; // Falta completar un formulario obligatorio
      }
    }
    return true; // Todos completos
  }

  // Navega al formulario anterior
  void _irAFormularioAnterior() {
    setState(() {
      _indiceFormularioActual--;
      // Si al retroceder caemos en 'Blogs' y SEO no es avanzado, retrocedemos uno más
      if (_indiceFormularioActual > 0 && // Evitar índice negativo
          _etiquetasFormularios[_indiceFormularioActual] == 'Blogs' &&
          _opcionesSeleccionadas['SEO'] != 'seo_avanzado') {
        _indiceFormularioActual--;
      }
      _formularioFinalizado = false; // Al retroceder, ya no está finalizado
      _actualizarCotizacion(); // Actualiza la vista de cotización
    });
  }

  // Navega al siguiente formulario o finaliza
  void _irAFormularioSiguienteOFinalizar() {
    if (!_puedeAvanzarAlSiguiente())
      return; // No hacer nada si no se puede avanzar

    setState(() {
      // Comprueba si el PASO ACTUAL es el último visible ANTES de finalizar.
      bool esUltimoPasoVisibleAntesDeFinalizar = _esUltimoFormularioVisible();

      if (esUltimoPasoVisibleAntesDeFinalizar) {
        // Si estamos en el último paso visible, marcamos como finalizado.
        _formularioFinalizado = true;
      } else {
        // Si no es el último, avanzamos al siguiente índice.
        _indiceFormularioActual++;
        _formularioFinalizado =
            false; // Nos aseguramos de que no esté finalizado

        // Lógica para saltar 'Blogs' si corresponde.
        int indiceBlogs = _etiquetasFormularios.indexOf('Blogs');
        bool seoAvanzadoSeleccionado =
            _opcionesSeleccionadas['SEO'] == 'seo_avanzado';

        // Si el nuevo índice es 'Blogs' y NO es SEO avanzado
        if (_indiceFormularioActual == indiceBlogs &&
            !seoAvanzadoSeleccionado) {
          // Solo saltar si 'Blogs' no es el último elemento real de la lista
          if (_indiceFormularioActual < _etiquetasFormularios.length - 1) {
            _indiceFormularioActual++; // Saltar al siguiente después de Blogs
          } else {
            // Si intentamos saltar Blogs y era el último, entonces finalizamos.
            // (Aunque la lógica de _esUltimoFormularioVisible debería haberlo prevenido).
            _formularioFinalizado = true;
          }
        }
      }
      _actualizarCotizacion(); // Actualiza la vista de cotización
    });
  }

  // Determina si el índice actual corresponde al último *visible* formulario
  bool _esUltimoFormularioVisible() {
    int indiceActual = _indiceFormularioActual;
    int totalPasos = _etiquetasFormularios.length;
    int ultimoIndiceReal =
        totalPasos - 1; // El índice del último elemento en la lista

    // Verifica si estamos en el último índice real de la lista
    if (indiceActual == ultimoIndiceReal) {
      return true;
    }

    // Verifica si el *siguiente* paso sería el último o más allá,
    // considerando el salto de 'Blogs'.
    int indiceBlogs = _etiquetasFormularios.indexOf('Blogs');
    bool seoAvanzadoSeleccionado =
        _opcionesSeleccionadas['SEO'] == 'seo_avanzado';

    // Si estamos justo antes de Blogs ('SEO') y NO es SEO avanzado
    if (indiceActual == indiceBlogs - 1 && !seoAvanzadoSeleccionado) {
      // El siguiente paso saltará Blogs. El índice al que saltará es indiceBlogs + 1
      int indiceDestino = indiceBlogs + 1;
      // ¿Es este índice destino el último índice real o está fuera de los límites?
      return indiceDestino >= ultimoIndiceReal;
    }

    // En cualquier otro caso, no estamos en el último paso visible (aún quedan pasos intermedios)
    return false;
  }

  // Maneja el cambio de selección en un dropdown
  void _onDropdownChanged(String etiqueta, String? valor) {
    setState(() {
      _opcionesSeleccionadas[etiqueta] = valor;

      // Lógica específica al cambiar SEO: si no es avanzado, limpia la selección de Blogs
      if (etiqueta == 'SEO' && valor != 'seo_avanzado') {
        if (_opcionesSeleccionadas.containsKey('Blogs')) {
          _opcionesSeleccionadas.remove('Blogs');
        }
        // Si estábamos en Blogs y cambiamos SEO, necesitamos reevaluar el índice o estado
        if (_etiquetasFormularios[_indiceFormularioActual] == 'Blogs') {
          // Podríamos forzar ir al siguiente si existe, o manejarlo en _irAFormularioSiguiente
          // Por ahora, solo actualizamos cotización y dejamos que la lógica de avance/renderizado se encargue
        }
      }
      // Lógica específica al seleccionar Mantenimiento Avanzado (opcional)
      // Si se selecciona 'mantenimiento_avanzado', ¿debería afectar 'Blogs'?
      // Depende de la regla de negocio: "Incluye creación de un blog al mes".
      // Esto podría ser solo informativo en la descripción o forzar una selección en Blogs.
      // Por simplicidad actual, no forzamos selección en 'Blogs' aquí.

      _actualizarCotizacion(); // Actualiza la cotización siempre que cambia una opción
      // No es necesario llamar a _puedeAvanzar... aquí, se usa en los botones
    });
  }

  // --- Construcción de la UI ---

  @override
  Widget build(BuildContext context) {
    // Determina la orientación basada en el ancho
    final bool esPantallaHorizontal = MediaQuery.of(context).size.width > 767;
    // Acceder a los colores desde MyApp o definirlos localmente/pasarlos
    const Color colorPrimario = MyApp.colorPrimario;
    const Color colorSecundario = MyApp.colorSecundario;

    return Scaffold(
      appBar: AppBar(
        // Título estilizado para el AppBar
        title: Stack(
          alignment: Alignment.center, // Centra ambos textos
          children: [
            // Texto con borde blanco (detrás)
            Text(
              'COTIZA TU WEB',
              style: GoogleFonts.poppins(
                fontSize: 24,
                letterSpacing: 1,
                fontWeight: FontWeight.w900,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 3 // Grosor del borde
                  ..color = Colors.white, // Color del borde
              ),
            ),
            // Texto principal (delante)
            Text(
              'COTIZA TU WEB',
              style: GoogleFonts.poppins(
                fontSize: 24,
                letterSpacing: 1,
                fontWeight: FontWeight.w900,
                color: colorSecundario, // Color principal del texto
              ),
            ),
          ],
        ),
      ),
      // Cuerpo principal con padding
      body: Padding(
        padding: const EdgeInsets.all(24.0), // Padding general
        child: esPantallaHorizontal
            ? _buildHorizontalLayout(context) // Layout para pantallas anchas
            : _buildVerticalLayout(context), // Layout para pantallas estrechas
      ),
    );
  }

  // Construye el layout para pantallas horizontales (anchas)
  Widget _buildHorizontalLayout(BuildContext context) {
    const Color colorPrimario = MyApp.colorPrimario;
    const Color colorSecundario = MyApp.colorSecundario;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Sección Izquierda (Formulario) ---
        Expanded(
          flex: 7, // Ocupa el 70% del ancho
          child: Container(
            decoration: BoxDecoration(
              color:
                  Colors.white, // Fondo blanco para la sección del formulario
              border: Border.all(
                  color: colorPrimario, width: 2.5), // Borde distintivo
            ),
            child: Padding(
              padding: const EdgeInsets.all(32.0), // Padding interno generoso
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Indicador de Progreso
                  UIComponents.buildProgressIndicator(
                    currentIndex: _indiceFormularioActual,
                    totalSteps: _etiquetasFormularios.length,
                    primaryColor: colorPrimario,
                    secondaryColor: colorSecundario,
                  ),
                  const SizedBox(height: 32), // Espacio vertical

                  // 2. Formulario Actual (con scroll si es necesario)
                  Expanded(
                    child: SingleChildScrollView(
                      // Permite scroll si el contenido es largo
                      child: _buildCurrentFormSection(),
                    ),
                  ),
                  const SizedBox(height: 16), // Espacio antes de los botones
                  // 3. Botones de Navegación
                  UIComponents.buildNavigationButtons(
                    currentIndex: _indiceFormularioActual,
                    totalSteps: _etiquetasFormularios.length,
                    canProceed: _puedeAvanzarAlSiguiente(),
                    isLastVisibleStep:
                        _esUltimoFormularioVisible(), // Pasar si es el último visible
                    onBackPressed: _indiceFormularioActual > 0
                        ? _irAFormularioAnterior
                        : null, // Habilita atrás si no es el primero
                    onNextPressed:
                        _irAFormularioSiguienteOFinalizar, // Función para siguiente/finalizar
                    primaryColor: colorPrimario, // Pasar colores del tema
                    // secondaryColor: colorSecundario,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 24), // Espacio entre columnas

        // --- Sección Derecha (Cotización) ---
        Expanded(
          flex: 3, // Ocupa el 30% del ancho
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white, // Fondo blanco
              border: Border.all(
                  color: colorPrimario, width: 2.5), // Borde consistente
            ),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Título de la Sección de Cotización
                  Text(
                      _formularioFinalizado
                          ? 'Cotización Final'
                          : 'Cotización Parcial',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w300,
                          letterSpacing: 1.0,
                          color: Colors.black87)),
                  // 2. Línea Divisoria
                  Container(
                    height: 1,
                    color: colorPrimario, // Usa color primario para la línea
                    margin: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  // 3. Área de Texto de la Cotización
                  Expanded(
                    child: TextField(
                      controller: _controladorResultado,
                      maxLines: 15, // Suficientes líneas para el resumen
                      readOnly: true, // No editable por el usuario
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontSize: 14),
                      decoration: const InputDecoration(
                        // Usa el tema, pero podemos ajustar
                        hintText:
                            'Seleccione opciones para ver la cotización...',
                        // Los bordes y colores ya están definidos en el tema (main.dart)
                        // Ajustamos el relleno si es necesario
                        contentPadding: EdgeInsets.all(16),
                        // Aseguramos que no tenga relleno interno si usamos el tema
                        filled: false, // Ya definido en el tema
                      ),
                    ),
                  ),
                  const SizedBox(
                      height: 16), // Espacio antes de los botones finales
                  // 4. Botones de Acción Final (Enviar/Descargar)
                  if (_formularioFinalizado && _todoFormularioCompleto())
                    UIComponents.buildFinalActionButtons(
                      onSendQuote: () {/* TODO: Implementar lógica de envío */},
                      onDownloadQuote: _descargarOCompartirPdf,
                      primaryColor: colorPrimario,
                      secondaryColor: colorSecundario,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Construye el layout para pantallas verticales (estrechas)
  Widget _buildVerticalLayout(BuildContext context) {
    const Color colorPrimario = MyApp.colorPrimario;
    const Color colorSecundario = MyApp.colorSecundario;
    // Similar al horizontal pero en una columna
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Indicador de Progreso
        UIComponents.buildProgressIndicator(
          currentIndex: _indiceFormularioActual,
          totalSteps: _etiquetasFormularios.length,
          primaryColor: colorPrimario,
          secondaryColor: colorSecundario,
        ),
        const SizedBox(height: 24),

        // 2. Sección del Formulario Actual
        Expanded(
          flex: 6, // Más espacio para el formulario
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border:
                  Border.all(color: Colors.grey.shade300), // Borde más sutil
            ),
            padding: const EdgeInsets.all(24.0),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                onBackPressed:
                    _indiceFormularioActual > 0 ? _irAFormularioAnterior : null,
                onNextPressed: _irAFormularioSiguienteOFinalizar,
                primaryColor: colorPrimario,
                // secondaryColor: colorSecundario,
              ),
            ]),
          ),
        ),
        const SizedBox(height: 24), // Espacio entre secciones

        // 3. Sección de Cotización
        Expanded(
          flex: 4, // Menos espacio que el formulario
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
            ),
            padding: const EdgeInsets.all(24.0),
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
                        color: Colors.black87)),
                Container(
                  height: 1,
                  color: Colors.grey.shade300, // Línea sutil
                  margin: const EdgeInsets.symmetric(vertical: 14),
                ),
                Expanded(
                  child: TextField(
                    controller: _controladorResultado,
                    maxLines: null, // Permite expansión vertical automática
                    minLines: 5, // Un mínimo de líneas visible
                    readOnly: true,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Seleccione opciones...',
                      filled: true, // Ligeramente diferente en vertical
                      fillColor: Colors.grey.shade50, // Fondo grisáceo claro
                      contentPadding: const EdgeInsets.all(16),
                      // Bordes del tema
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_formularioFinalizado && _todoFormularioCompleto())
                  UIComponents.buildFinalActionButtons(
                    onSendQuote: () {/* ... */},
                    onDownloadQuote: _descargarOCompartirPdf,
                    primaryColor: colorPrimario,
                    secondaryColor: colorSecundario,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Construye la sección del formulario correspondiente al índice actual
  Widget _buildCurrentFormSection() {
    // Si no hay precios cargados, muestra un indicador
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

    // Lógica para saltar Blogs si SEO no es avanzado (se maneja en la navegación)
    // Aquí solo determinamos si debe ser visible o no
    bool esVisibleBlogs = etiquetaActual == 'Blogs' &&
        _opcionesSeleccionadas['SEO'] == 'seo_avanzado';

    // Devuelve el widget del formulario adecuado usando UIComponents
    switch (etiquetaActual) {
      case 'Creación':
        return UIComponents.buildDropdownSection(
          etiqueta: 'Creación',
          descripciones: const [
            'Adaptación de plantilla: Uso y ajuste de una plantilla preexistente.',
            'Personalización de plantilla: Modificación de una plantilla existente.',
            'Creación personalizada: Diseño y desarrollo a medida.', // Más corto
          ],
          opciones: const [
            'adaptacion_plantilla',
            'personalizacion_plantilla',
            'creacion_personalizada',
          ],
          valorSeleccionado: _opcionesSeleccionadas[etiquetaActual],
          onChanged: (valor) => _onDropdownChanged(etiquetaActual, valor),
          primaryColor: MyApp.colorPrimario, // Pasa los colores necesarios
          secondaryColor: MyApp.colorSecundario,
        );
      case 'SEO':
        return UIComponents.buildDropdownSection(
          etiqueta: 'Optimización SEO', // Título más descriptivo
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
        // Usa `visible` para ocultar completamente si no aplica
        return UIComponents.buildDropdownSection(
          etiqueta: 'Gestión de Blogs',
          descripciones: const [
            'Número de entradas de blog a crear por mes (requiere SEO Avanzado).',
          ],
          // Las opciones podrían venir de Firebase o estar fijas
          opciones: const [
            '0_blogs', // Opción explícita de "0 Blogs" si es necesario
            '1_blog',
            '2_blog',
            '3_blog',
            '4_blog',
          ],
          valorSeleccionado: _opcionesSeleccionadas[etiquetaActual],
          onChanged: (valor) => _onDropdownChanged(etiquetaActual, valor),
          visible: esVisibleBlogs, // Controla la visibilidad del widget entero
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

      default: // Caso inesperado, devuelve un contenedor vacío
        return const SizedBox.shrink();
    }
  }

  /// Genera el contenido del PDF como bytes (Uint8List)
   Future<Uint8List> _generarPdfCotizacion() async {
    final pdf = pw.Document();

    // Verifica si las fuentes se cargaron, si no, usa un valor por defecto o lanza error
     if (_robotoRegular == null || _robotoBold == null || _robotoItalic == null) {
        print("Advertencia: Fuentes PDF no cargadas, usando valores nulos.");
        // Podrías lanzar una excepción o retornar un PDF básico de error
        // throw Exception("Las fuentes para el PDF no se pudieron cargar.");
     }
     // Define un tema de texto base con la fuente cargada
     final baseTextStyle = pw.TextStyle(font: _robotoRegular, fontSize: 11);
     final boldTextStyle = pw.TextStyle(font: _robotoBold, fontSize: 11);
     final italicTextStyle = pw.TextStyle(font: _robotoItalic, fontSize: 10, color: PdfColors.grey600);
     final titleTextStyle = pw.TextStyle(font: _robotoBold, fontSize: 24);
     final headerTextStyle = pw.TextStyle(font: _robotoBold, fontSize: 16); // Para Headers nivel 1

    // --- Cálculo de precios y items (como lo tenías) ---
    int precioValorOfrecido = 0;
    int precioNacional = 0;
    int precioInternacional = 0;
    List<pw.Widget> itemsSeleccionadosWidgets = [];

    _opcionesSeleccionadas.forEach((clave, valor) {
      if (valor != null && ServicioFirebase.precios.containsKey(valor)) {
        final precioData = ServicioFirebase.precios[valor]!;
        precioValorOfrecido += (precioData['valor_ofrecido'] as num? ?? 0).round();
        precioNacional += (precioData['nacional'] as num? ?? 0).round();
        precioInternacional += (precioData['internacional'] as num? ?? 0).round();

        // Añadir item usando la fuente base y la descripción formateada
        itemsSeleccionadosWidgets.add(pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 3),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start, // Alinear mejor textos largos
            children: [
              pw.SizedBox(width: 150, child: pw.Text('$clave:', style: boldTextStyle)), // Clave en negrita
              pw.Expanded(child: pw.Text(ServicioFirebase.formatearOpcionConPrecio(valor), style: baseTextStyle)), // Valor con fuente base
            ],
          ),
        ));
      }
    });

    // --- Construcción de la página del PDF ---
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        // Aplica el tema de texto base a la página
        theme: pw.ThemeData.withFont(
             base: _robotoRegular ?? pw.Font.helvetica(), // Fallback a helvetica si falla la carga
             bold: _robotoBold ?? pw.Font.helveticaBold(),
             italic: _robotoItalic ?? pw.Font.helveticaOblique(),
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 1. Título (usa el estilo de fuente cargada)
              pw.Header( level: 0, child: pw.Text( 'Cotización de Desarrollo Web', style: titleTextStyle, ),),
              pw.SizedBox(height: 20),

              // 2. Fecha (usa fuente base)
              pw.Text( 'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}', style: baseTextStyle),
              pw.SizedBox(height: 20),

              // 3. Resumen de Servicios Seleccionados
              pw.Header(level: 1, textStyle: headerTextStyle, child: pw.Text('Servicios Seleccionados:')), // Estilo para Header
              pw.Divider(),
              ...itemsSeleccionadosWidgets, // Ya tienen el estilo aplicado
              pw.SizedBox(height: 30),

              // 4. Resumen de Precios Estimados
              pw.Header(level: 1, textStyle: headerTextStyle, child: pw.Text('Precios Estimados:')),
              pw.Divider(),
              pw.Table(columnWidths: const {
                0: pw.FixedColumnWidth(200),
                1: pw.FlexColumnWidth(),
              }, children: [
                 // _buildPriceRow necesita la fuente como parámetro ahora
                _buildPriceRow('Precio Valor Ofrecido:', precioValorOfrecido, baseFont: baseTextStyle, boldFont: boldTextStyle),
                _buildPriceRow('Precio Nacional:', precioNacional, baseFont: baseTextStyle, boldFont: boldTextStyle),
                _buildPriceRow( 'Precio Internacional (USD aprox.):', precioInternacional, isUSD: true, baseFont: baseTextStyle, boldFont: boldTextStyle),
              ]),
              pw.SizedBox(height: 40),

              // 5. Disclaimer (usa fuente itálica)
              pw.Text(
                'Nota: Esta es una cotización preliminar...', // tu texto
                style: italicTextStyle,
              ),
            ],
          );
        },
      ),
    );

    // Guarda el documento PDF
    return pdf.save();
  }

  /// Construye una fila para la tabla de precios en el PDF (modificado para aceptar fuentes)
  pw.TableRow _buildPriceRow(String label, int value, {bool isUSD = false, required pw.TextStyle baseFont, required pw.TextStyle boldFont}) {
    final String formattedValue = ServicioFirebase.formatearNumeroConPuntos(value);
    final String prefix = isUSD ? 'USD \$' : '\$';
    return pw.TableRow(
      children: [
        pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            child: pw.Text(label, style: boldFont) // Usa la fuente bold pasada
            ),
        pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            child: pw.Text('$prefix$formattedValue', style: baseFont, textAlign: pw.TextAlign.right) // Usa la fuente base pasada
            ),
      ],
    );
  }


  /// Descarga el PDF en Web o lo comparte en otras plataformas
  Future<void> _descargarOCompartirPdf() async {
    // Asegúrate que las fuentes estén cargadas antes de generar
    if (_robotoRegular == null || _robotoBold == null || _robotoItalic == null) {
        print("Esperando carga de fuentes PDF...");
        // Opcional: Mostrar un indicador de carga brevemente
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Preparando fuentes para PDF...'), duration: Duration(seconds: 2)),
        );
        // Espera un poco o reintenta la carga si es necesario.
        // Una mejor solución sería deshabilitar el botón hasta que las fuentes estén listas.
        await _loadPdfFonts(); // Reintenta la carga por si acaso
         if (_robotoRegular == null) { // Si aún falla
              ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Error: No se pudieron cargar las fuentes para el PDF.')),
              );
              return; // Salir si no se cargaron
         }
    }


    try {
      print('Generando PDF...');
      final Uint8List pdfBytes = await _generarPdfCotizacion();
      final String filename = 'cotizacion-web-${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
      print('PDF generado (${pdfBytes.lengthInBytes} bytes).');

      if (kIsWeb) {
        // --- Lógica para Web: Descarga directa ---
        print('Plataforma Web detectada. Iniciando descarga...');
        _descargarPdfWeb(pdfBytes, filename);
        print('Descarga iniciada (Web).');

      } else {
        // --- Lógica para otras plataformas (Móvil, Escritorio): Compartir ---
         print('Plataforma no Web. Usando Printing.sharePdf...');
        await Printing.sharePdf(
           bytes: pdfBytes,
           filename: filename,
        );
        print('Diálogo de compartición iniciado.');
      }

    } catch (e) {
      print('Error al generar o compartir/descargar PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al procesar el PDF: $e')),
      );
    }
  }

  /// Función auxiliar para descargar el PDF en la web
  void _descargarPdfWeb(Uint8List bytes, String filename) {
      // Crea un Blob con los bytes del PDF y el tipo MIME correcto
      final blob = html.Blob([bytes], 'application/pdf');
      // Crea una URL para el Blob
      final url = html.Url.createObjectUrlFromBlob(blob);
      // Crea un elemento 'a' (anchor) invisible en el DOM
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = filename; // Establece el nombre de archivo para la descarga
      // Añade el anchor al cuerpo del documento
      html.document.body?.children.add(anchor);
      // Simula un clic en el anchor para iniciar la descarga
      anchor.click();
      // Limpia removiendo el anchor y revocando la URL del Blob
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
  }
}
