import 'dart:typed_data';
import 'dart:html' as html; // Solo para descarga web

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

// Importa el servicio de Firebase para acceder a precios y formateo
import 'firebase_service.dart';

class PdfService {
  // Variables para almacenar las fuentes cargadas
  pw.Font? _robotoRegular;
  pw.Font? _robotoBold;
  pw.Font? _robotoItalic;
  bool _fontsLoaded = false;

  // --- Carga de Fuentes PDF ---
  Future<void> loadFonts() async {
    // Evita recargar si ya están listas
    if (_fontsLoaded) return;

    try {
      final fontDataRegular = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      final fontDataBold = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
      final fontDataItalic = await rootBundle.load('assets/fonts/Roboto-Italic.ttf');

      _robotoRegular = pw.Font.ttf(fontDataRegular.buffer.asByteData());
      _robotoBold = pw.Font.ttf(fontDataBold.buffer.asByteData());
      _robotoItalic = pw.Font.ttf(fontDataItalic.buffer.asByteData());
      _fontsLoaded = true; // Marcar como cargadas
      print("Fuentes PDF cargadas correctamente por PdfService.");
    } catch (e) {
      _fontsLoaded = false; // Marcar como fallidas
      print("Error cargando fuentes PDF en PdfService: $e");
      // Relanzar la excepción para que el llamador pueda manejarla
      throw Exception("Error al cargar las fuentes para el PDF: $e");
    }
  }

  /// Genera el contenido del PDF como bytes (Uint8List)
  /// Requiere las opciones seleccionadas del formulario.
  /// Opcionalmente, recibe datos del cliente para incluirlos.
  Future<Uint8List> _generarPdfBytes(
    Map<String, String?> opcionesSeleccionadas, {
    Map<String, String>? datosCliente, // Nuevo parámetro opcional
  }) async {
    // Asegura que las fuentes estén cargadas antes de proceder
    if (!_fontsLoaded || _robotoRegular == null || _robotoBold == null || _robotoItalic == null) {
      print("Intento de generar PDF sin fuentes cargadas. Intentando cargar...");
      await loadFonts(); // Intenta cargar si no lo estaban
      if (!_fontsLoaded) { // Si la carga falla de nuevo
          throw Exception("Las fuentes PDF no están disponibles para generar el documento.");
      }
    }

    final pdf = pw.Document();

    // Define estilos usando las fuentes cargadas
    final baseTextStyle = pw.TextStyle(font: _robotoRegular!, fontSize: 11);
    final boldTextStyle = pw.TextStyle(font: _robotoBold!, fontSize: 11);
    final italicTextStyle = pw.TextStyle(font: _robotoItalic!, fontSize: 10, color: PdfColors.grey600);
    final titleTextStyle = pw.TextStyle(font: _robotoBold!, fontSize: 24);
    final headerTextStyle = pw.TextStyle(font: _robotoBold!, fontSize: 16);

    // --- Cálculo de precios y items ---
    int precioValorOfrecido = 0;
    int precioNacional = 0;
    int precioInternacional = 0;
    List<pw.Widget> itemsSeleccionadosWidgets = [];

    opcionesSeleccionadas.forEach((clave, valor) {
      if (valor != null && ServicioFirebase.precios.containsKey(valor)) {
        final precioData = ServicioFirebase.precios[valor]!;
        precioValorOfrecido += (precioData['valor_ofrecido'] as num? ?? 0).round();
        precioNacional += (precioData['nacional'] as num? ?? 0).round();
        precioInternacional += (precioData['internacional'] as num? ?? 0).round();

        itemsSeleccionadosWidgets.add(pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 3),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(width: 150, child: pw.Text('$clave:', style: boldTextStyle)),
              pw.Expanded(child: pw.Text(ServicioFirebase.formatearOpcionConPrecio(valor), style: baseTextStyle)),
            ],
          ),
        ));
      }
    });

    // --- Construcción de la página del PDF ---
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: _robotoRegular!,
          bold: _robotoBold!,
          italic: _robotoItalic!,
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(level: 0, child: pw.Text('Cotización de Desarrollo Web', style: titleTextStyle)),
              pw.SizedBox(height: 20),
              pw.Text('Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}', style: baseTextStyle),
              pw.SizedBox(height: 20),

              // --- Sección de Datos del Cliente (Condicional) ---
              if (datosCliente != null && datosCliente.isNotEmpty) ...[
                pw.Header(level: 1, textStyle: headerTextStyle, child: pw.Text('Datos del Cliente:')),
                pw.Divider(),
                pw.Table(
                  columnWidths: const {
                    0: pw.FixedColumnWidth(150), // Ancho para la etiqueta (Nombre:)
                    1: pw.FlexColumnWidth(), // Ancho flexible para el valor
                  },
                  children: [
                    // Construye filas para cada dato del cliente
                    if (datosCliente['nombre'] != null && datosCliente['nombre']!.isNotEmpty)
                      _buildInfoRow('Nombre:', datosCliente['nombre']!, baseFont: baseTextStyle, boldFont: boldTextStyle),
                    if (datosCliente['telefono'] != null && datosCliente['telefono']!.isNotEmpty)
                      _buildInfoRow('Teléfono:', datosCliente['telefono']!, baseFont: baseTextStyle, boldFont: boldTextStyle),
                    if (datosCliente['correo'] != null && datosCliente['correo']!.isNotEmpty)
                      _buildInfoRow('Correo Electrónico:', datosCliente['correo']!, baseFont: baseTextStyle, boldFont: boldTextStyle),
                     if (datosCliente['nombreWeb'] != null && datosCliente['nombreWeb']!.isNotEmpty)
                      _buildInfoRow('Nombre Sitio Web:', datosCliente['nombreWeb']!, baseFont: baseTextStyle, boldFont: boldTextStyle),
                  ],
                ),
                pw.SizedBox(height: 30), // Espacio después de los datos del cliente
              ],

              // --- Sección de Servicios Seleccionados ---
              pw.Header(level: 1, textStyle: headerTextStyle, child: pw.Text('Servicios Seleccionados:')),
              pw.Divider(),
              ...itemsSeleccionadosWidgets,
              pw.SizedBox(height: 30),

              // --- Sección de Precios Estimados ---
              pw.Header(level: 1, textStyle: headerTextStyle, child: pw.Text('Precios Estimados:')),
              pw.Divider(),
              pw.Table(columnWidths: const {
                0: pw.FixedColumnWidth(200),
                1: pw.FlexColumnWidth(),
              }, children: [
                _buildPriceRow('Precio Valor Ofrecido:', precioValorOfrecido, baseFont: baseTextStyle, boldFont: boldTextStyle),
                _buildPriceRow('Precio Nacional:', precioNacional, baseFont: baseTextStyle, boldFont: boldTextStyle),
                _buildPriceRow('Precio Internacional (USD aprox.):', precioInternacional, isUSD: true, baseFont: baseTextStyle, boldFont: boldTextStyle),
              ]),
              pw.SizedBox(height: 40),

              // --- Nota Final ---
              pw.Text(
                'Nota: Esta es una cotización preliminar. Los precios finales pueden variar al añadir nuevos requisitos y/o segun negociaciones adicionales. Contacta con nosotros para más detalles.',
                style: italicTextStyle,
                textAlign: pw.TextAlign.justify,
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Construye una fila para la tabla de precios en el PDF
  pw.TableRow _buildPriceRow(String label, int value, {bool isUSD = false, required pw.TextStyle baseFont, required pw.TextStyle boldFont}) {
    final String formattedValue = ServicioFirebase.formatearNumeroConPuntos(value);
    final String prefix = isUSD ? 'USD \$' : '\$'; // Asumiendo moneda local para precios no USD
    return pw.TableRow(
      children: [
        pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            child: pw.Text(label, style: boldFont)),
        pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            child: pw.Text('$prefix$formattedValue', style: baseFont, textAlign: pw.TextAlign.right)),
      ],
    );
  }

  /// Construye una fila para la tabla de información general (como datos del cliente)
  pw.TableRow _buildInfoRow(String label, String value, {required pw.TextStyle baseFont, required pw.TextStyle boldFont}) {
     return pw.TableRow(
      children: [
        pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            child: pw.Text(label, style: boldFont)),
        pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            child: pw.Text(value, style: baseFont)),
      ],
    );
  }


  /// Genera y luego descarga (web) o comparte (móvil/escritorio) el PDF.
  /// Permite incluir datos del cliente opcionalmente.
  Future<void> generateAndHandlePdf({
    required Map<String, String?> opcionesSeleccionadas,
    String? baseFilename = 'cotizacion-web', // Nombre base opcional
    Map<String, String>? datosCliente, // Nuevo parámetro opcional
  }) async {
      // Asegurarse que las fuentes estén cargadas es manejado dentro de _generarPdfBytes
    try {
      print('Generando PDF desde PdfService...');
      final Uint8List pdfBytes = await _generarPdfBytes(
        opcionesSeleccionadas,
        datosCliente: datosCliente, // Pasar los datos del cliente
      );
      final String filename = '$baseFilename-${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
      print('PDF generado (${pdfBytes.lengthInBytes} bytes). Manejando salida...');

      if (kIsWeb) {
        print('Plataforma Web detectada. Iniciando descarga...');
        _downloadPdfWeb(pdfBytes, filename);
        print('Descarga iniciada (Web).');
      } else {
        print('Plataforma no Web. Usando Printing.sharePdf...');
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: filename,
        );
        print('Diálogo de compartición iniciado.');
      }
    } catch (e) {
      print('Error en generateAndHandlePdf: $e');
      // Relanzar la excepción para que la UI pueda mostrar un mensaje
      throw Exception('Error al procesar el PDF: ${e.toString()}'); // Mejorar mensaje
    }
  }

  /// Función auxiliar para descargar el PDF en la web
  void _downloadPdfWeb(Uint8List bytes, String filename) {
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = filename;
    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }

  /// Getter para saber si las fuentes están listas
  bool get areFontsLoaded => _fontsLoaded;
}