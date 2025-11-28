**Sistema de Gestión de Paquetería - Paquexpress**
Este proyecto es una solución para el seguimiento de entregas de un servicio de paquetería. Consta de una aplicación web (Frontend en Flutter Web), una API (Backend en FastAPI) y una base de datos relacional en MySQL.
El sistema permite a los repartidores consultar sus paquetes asignados, visualizar rutas y registrar la entrega con evidencia fotográfica y coordenadas de ubicación.

**Dependencias utilizadas**
Frontend: Flutter (Dart) ejecutado en Chrome
Backend: Python (FastAPI, SQLAlchemy, PyMySQL)
Base de datos: MySQL (XAMPP, Workbench o línea de comandos)
Seguridad: Hash MD5 para contraseñas
Herramientas recomendadas: Git, Visual Studio Code

**Estructura del proyecto**
Proyecto_Paquexpress/
    api/                 # Backend (FastAPI)
        env/             # Entorno virtual local (no debe subirse a Git)
        imagenes/        # Evidencias de entrega
        main.py          # Archivo principal de la API
    app/                 # Frontend (Flutter)
        lib/             # Pantallas de la aplicación
        pubspec.yaml     # Dependencias de Flutter
    bd/
        db.sql           # Script de la base de datos
    README.md
Nota: La carpeta env/ debe crearse de manera local en cada computadora.


**Instrucciones de instalación y ejecución**

**1. Configuración de la base de datos**
1. Iniciar el servicio MySQL.
2. Crear una base de datos con el nombre:
    db_paquexpress
3. Importar el archivo db.sql ubicado en la carpeta bd/.

# Configuración de conexión
En el archivo:
    api/main.py

Buscar la variable:
    DATABASE_URL = "mysql+pymysql://root:@localhost:3306/db_paquexpress"

Asegurarse de que coincida con los valores reales del servidor MySQL:
    Usuario: root
    Contraseña: (vacía) o root
    Host: localhost
    Puerto: 3306
    Base de datos: db_paquexpress
Si estos parámetros son distintos, deben modificarse en DATABASE_URL.

2. Ejecutar el backend (API)
Abrir una terminal dentro de la carpeta del proyecto y ejecutar:
    cd api
Crear o activar el entorno virtual (Windows PowerShell)
.\env\Scripts\Activate.ps1

Si el entorno no existe, crearlo antes con:
    python -m venv env

Instalar dependencias necesarias
    pip install pymysql sqlalchemy fastapi uvicorn python-multipart

Iniciar el servidor
    uvicorn main:app --host localhost --port 8000 --reload

Si todo es correcto, aparecerá:
    Uvicorn running on http://localhost:8000

3. Ejecutar el frontend (Flutter Web)
Abrir otra terminal en la carpeta raíz y ejecutar:
    cd app

Descargar dependencias:
    flutter pub get

Ejecutar el proyecto en Chrome:
    flutter run -d chrome

Credenciales de acceso de prueba:
    Correo: pedrop@gmail.com
    Contraseña: 12345

**Funcionalidades principales**
1. Inicio de sesión validado contra la base de datos mediante contraseñas en MD5.
2. Lista de entregas pendientes asignadas al usuario.
3. Detalle del paquete y botón para abrir la ruta en Google Maps.
4. Registro de entrega:
    Captura de fotografía.
    Registro automático de la ubicación GPS.
    Actualización del estado del paquete a “entregado”.