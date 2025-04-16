import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Importa el servicio para formatear opciones si es necesario
import 'firebase_service.dart';

// Clase estática para agrupar los constructores de componentes de UI
class UIComponents {

  // 1. Indicador de Progreso
  static Widget buildProgressIndicator({
    required int currentIndex,
    required int totalSteps,
    required Color primaryColor,
    required Color secondaryColor,
  }) {
    // Asegurarse de que totalSteps no sea 0 para evitar división por cero
    final double progressValue = totalSteps > 0 ? (currentIndex + 1) / totalSteps : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
               // El título podría venir como parámetro si cambia mucho
              'Etapa ${currentIndex + 1}: Selección',
              style: GoogleFonts.poppins( // Usar fuentes del tema si es posible
                  fontSize: 20, // Ajustado ligeramente
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.8,
                  color: Colors.black87),
            ),
            Text(
              '${currentIndex + 1}/$totalSteps',
              style: GoogleFonts.poppins(
                  color: primaryColor, // Usa el color primario pasado
                  fontWeight: FontWeight.w500, // Un poco más de peso
                  letterSpacing: 1.0),
            ),
          ],
        ),
        const SizedBox(height: 10), // Espacio ajustado
        // Indicador de progreso lineal
        LinearProgressIndicator(
          value: progressValue,
          backgroundColor: secondaryColor.withOpacity(0.3), // Fondo más sutil
          color: primaryColor, // Color de la barra de progreso
          minHeight: 4, // Un poco más grueso para visibilidad
           borderRadius: BorderRadius.circular(2), // Bordes ligeramente redondeados
        ),
      ],
    );
  }

  // 2. Sección de Dropdown con Descripciones
  static Widget buildDropdownSection({
    required String etiqueta,
    required List<String> descripciones,
    required List<String> opciones,
    required String? valorSeleccionado,
    required ValueChanged<String?> onChanged,
    required Color primaryColor,
    required Color secondaryColor,
    bool visible = true, // Parámetro para controlar visibilidad
  }) {
    // Si no es visible, retorna un widget vacío que no ocupa espacio
    if (!visible) {
      return const SizedBox.shrink();
    }

    // El widget principal que se mostrará si es visible
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de la sección
        Text(
          etiqueta,
           style: GoogleFonts.poppins( // Estilo consistente
               fontSize: 20,
               fontWeight: FontWeight.w300,
               color: Colors.black87,
               letterSpacing: 0.8,
           ),
        ),
        const SizedBox(height: 4),
        // Línea divisoria decorativa
        Container(
          height: 1.5, // Ligeramente más gruesa
          width: 120,  // Ancho fijo
          color: secondaryColor, // Usa color secundario
          margin: const EdgeInsets.only(bottom: 20), // Margen inferior
        ),
        // Mapea las descripciones a widgets de Texto
        ...descripciones.map((desc) => Padding(
              padding: const EdgeInsets.only(bottom: 10), // Espacio entre descripciones
              child: Text(
                desc,
                style: GoogleFonts.poppins( // Estilo consistente para cuerpo
                    color: Colors.black54, // Un gris más suave
                    fontSize: 15,
                    height: 1.6,
                    letterSpacing: 0.3),
              ),
            )),
        const SizedBox(height: 24), // Espacio antes del Dropdown

        // Dropdown para seleccionar la opción
        DropdownButtonFormField<String?>(
          value: valorSeleccionado, // Valor actualmente seleccionado
          onChanged: onChanged, // Callback cuando cambia la selección
          dropdownColor: Colors.white, // Fondo del menú desplegable
          // Decoración (usa el InputDecorationTheme global, pero puede sobreescribirse)
          decoration: const InputDecoration(
            labelText: 'Seleccione una opción', // Texto de ayuda
             // Estilos de borde, relleno, etc., heredados del tema en main.dart
             // Asegúrate de que el tema esté bien configurado
          ),
          icon: Icon(Icons.keyboard_arrow_down, color: primaryColor), // Icono del dropdown
          isExpanded: true, // Ocupa todo el ancho disponible
          // Mapea la lista de strings de opciones a DropdownMenuItems
          items: opciones.map((opcion) {
            return DropdownMenuItem<String?>(
              value: opcion, // El valor interno de la opción
              child: Text(
                 // Formatea el texto de la opción para mostrar (ej: con precio)
                 // Asume que ServicioFirebase tiene esta función
                ServicioFirebase.formatearOpcionConPrecio(opcion),
                style: GoogleFonts.poppins( // Estilo para los items del dropdown
                    fontSize: 15,
                    letterSpacing: 0.3,
                    color: Colors.black87 // Color de texto estándar
                 ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 32), // Espacio adicional al final
      ],
    );
  }

  // 3. Botones de Navegación (Anterior/Siguiente/Finalizar)
  static Widget buildNavigationButtons({
    required int currentIndex,
    required int totalSteps,
    required bool canProceed,
    required bool isLastVisibleStep, // Indica si es el último paso VISIBLE
    required VoidCallback? onBackPressed, // Null si no hay botón "Anterior"
    required VoidCallback onNextPressed,
    required Color primaryColor,
    // required Color secondaryColor, // No se usa directamente aquí ahora
  }) {
     final bool isFirstStep = currentIndex == 0;
    // final bool isTrulyLastStep = currentIndex == totalSteps - 1; // Ya no se usa directamente

    return Padding(
      padding: const EdgeInsets.only(top: 24.0), // Espacio sobre los botones
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Alinea botones a los extremos
        children: [
          // Botón "Anterior" (visible solo si no es el primer paso)
          if (!isFirstStep && onBackPressed != null)
            TextButton.icon(
              icon: const Icon(Icons.arrow_back, size: 16, color: Colors.white),
              label: Text(
                 'Anterior',
                 style: GoogleFonts.poppins(letterSpacing: 0.5, fontWeight: FontWeight.w400)
              ),
              onPressed: onBackPressed, // Llama a la función pasada
              // Estilo heredado del TextButtonThemeData en main.dart
            )
          else
            // Ocupa espacio para mantener el botón Siguiente a la derecha
            const SizedBox(width: 80), // Ajusta el ancho según sea necesario

          // Botón "Siguiente" o "Finalizar"
          ElevatedButton.icon(
            icon: Icon(
              isLastVisibleStep ? Icons.check : Icons.arrow_forward, // Cambia icono si es el último
              size: 16,
              color: Colors.white,
            ),
            label: Text(
              isLastVisibleStep ? 'Finalizar' : 'Siguiente', // Cambia texto si es el último
               style: GoogleFonts.poppins(letterSpacing: 0.5, fontWeight: FontWeight.w400)
            ),
             // Habilita/deshabilita basado en canProceed
             // Llama a la función onNextPressed
            onPressed: canProceed ? onNextPressed : null,
            style: ElevatedButton.styleFrom(
               // Estilo heredado del tema, pero podemos especificar el color de deshabilitado
              disabledBackgroundColor: primaryColor.withOpacity(0.4),
              disabledForegroundColor: Colors.white.withOpacity(0.7),
               // El backgroundColor y foregroundColor normales vienen del tema
            ),
          ),
        ],
      ),
    );
  }

  // 4. Botones de Acción Final (Enviar/Descargar)
  static Widget buildFinalActionButtons({
    required VoidCallback onSendQuote,
    required VoidCallback onDownloadQuote,
    required Color primaryColor,
    required Color secondaryColor, required bool isDownloadEnabled, // Usado para el botón de enviar
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0), // Espacio sobre los botones
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // O `MainAxisAlignment.end` si prefieres a la derecha
        children: [
           // Botón Enviar Cotización
           ElevatedButton.icon(
             icon: const Icon(Icons.email_outlined, size: 16), // Icono de email
             label: Text(
                'Enviar Cotización',
                 style: GoogleFonts.poppins(letterSpacing: 0.5, fontWeight: FontWeight.w400)
             ),
             onPressed: onSendQuote,
             style: ElevatedButton.styleFrom(
                // Usar color secundario para diferenciarlo
               backgroundColor: secondaryColor,
               foregroundColor: Colors.white, // Texto blanco sobre color secundario
               padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12), // Padding ajustado
                // Forma heredada del tema
             ),
           ),
           const SizedBox(width: 16), // Espacio entre botones
           // Botón Descargar Cotización
           ElevatedButton.icon(
             icon: const Icon(Icons.download_outlined, size: 16, color: Colors.white), // Icono de descarga
             label: Text(
                'Descargar',
                 style: GoogleFonts.poppins(letterSpacing: 0.5, fontWeight: FontWeight.w400)
             ),
             onPressed: onDownloadQuote,
              style: ElevatedButton.styleFrom(
                 // Usa el color primario (o el estilo por defecto del tema)
                 // backgroundColor: primaryColor, // Ya viene del tema
                 padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  // Forma heredada del tema
              ),
           ),
         ],
      ),
    );
  }
}