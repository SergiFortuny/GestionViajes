🧳 Gestión de Viajes

Una aplicación móvil desarrollada en Flutter para la gestión y planificación de viajes personales, con autenticación de usuarios y almacenamiento en la nube mediante Firebase.
✨ Características Principales
👥 Gestión de Usuarios

    Registro y Login seguro con Firebase Firestore

    Perfiles personalizables con foto, ubicación y datos de contacto

    Sistema de roles (Usuario/Administrador)

🗺️ Gestión de Viajes

    Crear, editar y eliminar viajes personalizados

    Campos completos: origen, destino, fechas, transporte, personas, notas

    Filtros avanzados por origen, destino y transporte

    Búsqueda en tiempo real

🎨 Interfaz Premium

    Diseño moderno con gradientes y animaciones

    Tema oscuro elegante (JetBlack)

    Navegación intuitiva con drawer personalizado

    Experiencia de usuario fluida y responsive

🔧 Funcionalidades Avanzadas

    Integración con mapas (OpenStreetMap)

    Geocoding inverso y directo

    Panel de administración completo

    Actualización en tiempo real

🛠️ Tecnologías Utilizadas

    Flutter (Dart) - Framework principal

    Firebase Firestore - Base de datos en tiempo real

    Flutter Map - Mapas interactivos

    OpenStreetMap - Servicios de mapas

    HTTP - Geocoding y APIs externas

📱 Pantallas
🔐 Autenticación

    LoginScreen - Inicio de sesión

    RegisterScreen - Registro de nuevos usuarios

🏠 Principal

    HomeScreen - Lista de viajes y gestión

    ProfileScreen - Perfil y configuración

    AdminDashboard - Panel de administración

🚀 Instalación y Configuración

    Clona el proyecto

    Configura Firebase con las credenciales proporcionadas

    Ejecuta flutter pub get

    Inicia la aplicación con flutter run

📊 Estructura de Datos
Colección users
dart

{
  username: String,
  email: String,
  password: String,
  rol: String ('user'/'admin'),
  phone: String,
  locationAddress: String,
  profileImage: String,
  createdAt: Timestamp,
  updatedAt: Timestamp
}

Subcolección trips
dart

{
  origen: String,
  destino: String,
  personas: int,
  transporte: String,
  fecha_salida: Timestamp,
  fecha_vuelta: Timestamp,
  notas: String,
  createdAt: Timestamp
}
