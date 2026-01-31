# AutoGestión Max - Configuración Pendiente

##  Completado:
- [x] Proyecto clonado
- [x] Nombre cambiado a 'AutoGestión Max'
- [x] Package ID cambiado a: com.fartinara.autogestionmax
- [x] Dependencias actualizadas
- [x] Archivos de Firebase antiguos eliminados

##  Pendiente:

### 1. Configurar nuevo proyecto Firebase
- Crear nuevo proyecto en Firebase Console
- Agregar app Android: com.fartinara.autogestionmax
- Agregar app iOS: com.fartinara.autogestionmax
- Descargar google-services.json y GoogleService-Info.plist
- Ejecutar: flutterfire configure

### 2. Actualizar colores del tema
Cambiar en lib/main.dart o crear archivo lib/utils/theme.dart:
- Color primario: #0088CC (azul screenshot)
- Color secundario: #00BFA5 (cyan/turquesa)
- Considerar agregar animación de fondo sutil

### 3. Implementar autenticación
- Firebase Authentication
- Pantallas de login/registro
- Persistencia de sesión

### 4. Implementar sistema Freemium
- Límite de 1 vehículo gratis
- Pantalla de planes/precios
- Bloqueo de funciones premium

### 5. Integrar pasarela de pagos
- Stripe / Conekta / Mercado Pago
- Webhooks para verificar suscripciones
- Tracking en Firestore

##  Tabla de precios implementar:
| Vehículos | Precio/unidad | Total mensual |
|-----------|---------------|---------------|
| 1         | GRATIS        |  MXN        |
| 2-5       |  MXN      | -     |
| 6-10      |  MXN      | -,485   |
| 11-20     |  MXN      | ,705-,945 |
| 21-35     |  MXN      | ,045-,930 |
| 36-50     |  MXN      | ,860-,615 |

*Nota: El primer vehículo siempre es gratis (se resta una unidad)*

