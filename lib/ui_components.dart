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
    final double progressValue =
        totalSteps > 0 ? (currentIndex + 1) / totalSteps : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              // El título podría venir como parámetro si cambia mucho
              'Selección Etapa ${currentIndex + 1}: ',
              style: GoogleFonts.poppins(
                  // Usar fuentes del tema si es posible
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
          borderRadius:
              BorderRadius.circular(2), // Bordes ligeramente redondeados
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
          style: GoogleFonts.poppins(
            // Estilo consistente
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
          width: 120, // Ancho fijo
          color: secondaryColor, // Usa color secundario
          margin: const EdgeInsets.only(bottom: 20), // Margen inferior
        ),
        // Mapea las descripciones a widgets de Texto
        ...descripciones.map((desc) => Padding(
              padding: const EdgeInsets.only(
                  bottom: 10), // Espacio entre descripciones
              child: Text(
                desc,
                style: GoogleFonts.poppins(
                    // Estilo consistente para cuerpo
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
          icon: Icon(Icons.keyboard_arrow_down,
              color: primaryColor), // Icono del dropdown
          isExpanded: true, // Ocupa todo el ancho disponible
          // Mapea la lista de strings de opciones a DropdownMenuItems
          items: opciones.map((opcion) {
            return DropdownMenuItem<String?>(
              value: opcion, // El valor interno de la opción
              child: Text(
                // Formatea el texto de la opción para mostrar (ej: con precio)
                // Asume que ServicioFirebase tiene esta función
                ServicioFirebase.formatearOpcionConPrecio(opcion),
                style: GoogleFonts.poppins(
                    // Estilo para los items del dropdown
                    fontSize: 15,
                    letterSpacing: 0.3,
                    color: Colors.black87 // Color de texto estándar
                    ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Define el punto de quiebre (breakpoint)
  static const double narrowScreenWidthThreshold = 767.0;

  // 3. Botones de Navegación (Anterior/Siguiente/Finalizar) - ¡Ahora recibe context!
  static Widget buildNavigationButtons({
    required BuildContext context, // <--- Añadido BuildContext
    required int currentIndex,
    required int totalSteps,
    required bool canProceed,
    required bool isLastVisibleStep,
    required VoidCallback? onBackPressed,
    required VoidCallback onNextPressed,
    required Color primaryColor,
  }) {
    final bool isFirstStep = currentIndex == 0;
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isNarrowScreen = screenWidth <= narrowScreenWidthThreshold;

    // --- Define la lista de botones ---
    // Siempre incluimos el botón Siguiente/Finalizar
    List<Widget> buttons = [
      ElevatedButton.icon(
        icon: Icon(
          isLastVisibleStep ? Icons.check : Icons.arrow_forward,
          size: 16,
          color: Colors.white,
        ),
        label: Text(isLastVisibleStep ? 'Finalizar' : 'Siguiente',
            style: GoogleFonts.poppins(
                letterSpacing: 0.5, fontWeight: FontWeight.w400)),
        onPressed: canProceed ? onNextPressed : null,
        style: ElevatedButton.styleFrom(
          disabledBackgroundColor: primaryColor.withOpacity(0.4),
          disabledForegroundColor: Colors.white.withOpacity(0.7),
          // En Column, podríamos querer que se estire
          minimumSize: isNarrowScreen ? const Size(double.infinity, 40) : null,
        ),
      ),
    ];

    // Añadimos el botón Anterior al PRINCIPIO de la lista si es necesario
    if (!isFirstStep && onBackPressed != null) {
      buttons.insert(
          // Inserta al inicio
          0,
          TextButton.icon(
              icon: const Icon(Icons.arrow_back,
                  size: 16,
                  color: Colors
                      .white), // Color blanco para TextButton? Asegúrate que el tema lo soporte o especifica aquí
              label: Text('Anterior',
                  style: GoogleFonts.poppins(
                      letterSpacing: 0.5, fontWeight: FontWeight.w400)),
              onPressed: onBackPressed,
              style: TextButton.styleFrom(
                // En Column, podríamos querer que se estire
                minimumSize:
                    isNarrowScreen ? const Size(double.infinity, 40) : null,
                // Asegúrate que el color del texto sea visible sobre el fondo
                // foregroundColor: Colors.white, // O el color que defina tu tema para TextButton
              )));
    } else if (!isNarrowScreen) {
      // Si es pantalla ancha y NO hay botón anterior,
      // insertamos un espacio para empujar el botón Siguiente a la derecha
      buttons.insert(
          0, const SizedBox(width: 80)); // Ajusta este ancho si es necesario
    }

    // --- Construye Row o Column ---
    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: isNarrowScreen
          ? Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch, // Estira los botones
              mainAxisSize:
                  MainAxisSize.min, // Ocupa el mínimo espacio vertical
              children: buttons.isNotEmpty
                  ? List.generate(buttons.length * 2 - 1, (index) {
                      if (index.isEven) {
                        return buttons[index ~/ 2]; // Botón
                      } else {
                        return const SizedBox(
                            height: 12); // Espacio entre botones en columna
                      }
                    })
                  : [], // Lista vacía si no hay botones
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children:
                  buttons, // Los botones ya tienen el espaciador (SizedBox) si es necesario
            ),
    );
  }

  // 4. Botones de Acción Final (Enviar/Descargar) 
  static Widget buildFinalActionButtons({
    required BuildContext context, 
    required VoidCallback onSendQuote,
    required VoidCallback onDownloadQuote,
    required Color primaryColor,
    required Color secondaryColor,
    required bool isDownloadEnabled,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isNarrowScreen = screenWidth <= narrowScreenWidthThreshold;

    // --- Define la lista de botones ---
    List<Widget> buttons = [
      // Botón Enviar Cotización
      ElevatedButton.icon(
        icon: const Icon(Icons.email_outlined, size: 16, color: Colors.white,),
        label: Text('Enviar Cotización',
            style: GoogleFonts.poppins(
                letterSpacing: 0.5, fontWeight: FontWeight.w400)),
        onPressed: isDownloadEnabled
            ? onSendQuote
            : null, // Deshabilitar si la descarga no está lista? O manejar independientemente? Asumo que sí.
        style: ElevatedButton.styleFrom(
          backgroundColor: secondaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          disabledBackgroundColor: secondaryColor.withOpacity(0.4),
          disabledForegroundColor: Colors.white.withOpacity(0.7),
          // En Column, podríamos querer que se estire
          minimumSize: isNarrowScreen ? const Size(double.infinity, 40) : null,
        ),
      ),
      // Botón Descargar Cotización
      ElevatedButton.icon(
        icon: const Icon(Icons.download_outlined, size: 16, color: Colors.white,),
        label: Text('Descargar',
            style: GoogleFonts.poppins(
                letterSpacing: 0.5, fontWeight: FontWeight.w400)),
        onPressed: isDownloadEnabled ? onDownloadQuote : null,
        style: ElevatedButton.styleFrom(
          // backgroundColor: primaryColor, // Heredado del tema
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          disabledBackgroundColor:
              primaryColor.withOpacity(0.4), // Usa el primario deshabilitado
          disabledForegroundColor: Colors.white.withOpacity(0.7),
          // En Column, podríamos querer que se estire
          minimumSize: isNarrowScreen ? const Size(double.infinity, 40) : null,
        ),
      ),
    ];

    // --- Construye Row o Column ---
    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch, // Estira los botones
              mainAxisSize: MainAxisSize.min,
              children: List.generate(buttons.length * 2 - 1, (index) {
                if (index.isEven) {
                  return buttons[index ~/ 2]; // Botón
                } else {
                  return const SizedBox(
                      height: 12); // Espacio entre botones en columna
                }
              }),
            )
          // : Row(
          //     mainAxisAlignment:
          //         MainAxisAlignment.end, // O spaceBetween si prefieres
          //     children: [
          //         // Reconstruye la lista para Row con el SizedBox en medio
          //         buttons[0], // Botón Enviar
          //         const SizedBox(width: 16), // Espacio entre botones en Row
          //         buttons[1], // Botón Descargar
          //       ]),
    );
  }

  
// Helper para InputDecoration (puedes moverlo a UIComponents si prefieres)

   static InputDecoration getInputDecoration({
    required String labelText,
    required String hintText,
    required Color primaryColor,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: primaryColor.withOpacity(0.7)) : null,
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 12.0),
    );
  }
}



