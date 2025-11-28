import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import 'login_screen.dart';
class Usuario {
  final int id;
  final String nombre;
  final String rol;

  Usuario({required this.id, required this.nombre, required this.rol});

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id_usuario'],
      nombre: json['nombre'],
      rol: json['rol'],
    );
  }
}

class Paquete {
  final int id;
  final String descripcion;
  final String direccion;
  final String estado;

  Paquete({
    required this.id,
    required this.descripcion,
    required this.direccion,
    required this.estado,
  });

  factory Paquete.fromJson(Map<String, dynamic> json) {
    return Paquete(
      id: json['id_paquete'],
      descripcion: json['descripcion'],
      direccion: json['direccion_destino'],
      estado: json['estado'],
    );
  }
}
class AuthProvider with ChangeNotifier {
  // OJO: Si usas Chrome, localhost está bien.
  final String baseUrl = 'http://localhost:8000';
  
  Usuario? _usuario;
  Usuario? get usuario => _usuario;
  bool get estaAutenticado => _usuario != null;

  // --- LOGIN ---
  Future<bool> login(String correo, String password) async {
    try {
      final url = Uri.parse('$baseUrl/login');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"correo": correo, "password": password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _usuario = Usuario.fromJson(data);
        notifyListeners();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print("Error Login: $e");
      return false;
    }
  }

  Future<List<Paquete>> obtenerPaquetes() async {
    if (_usuario == null) return [];
    try {
      final url = Uri.parse('$baseUrl/mis-paquetes/${_usuario!.id}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((e) => Paquete.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print("Error Paquetes: $e");
      return [];
    }
  }

  Future<bool> entregarPaquete(int idPaquete, XFile foto, double lat, double lon) async {
    try {
      final url = Uri.parse('$baseUrl/entregar/$idPaquete');
      var request = http.MultipartRequest("POST", url);

      request.fields['latitud'] = lat.toString();
      request.fields['longitud'] = lon.toString();

      if (kIsWeb) {
        Uint8List bytes = await foto.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: foto.name,
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath('file', foto.path));
      }

      final response = await request.send();
      return response.statusCode == 200;
    } catch (e) {
      print("Error Entrega: $e");
      return false;
    }
  }

  void logout() {
    _usuario = null;
    notifyListeners();
  }
}

void main() {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Paquexpress',
      theme: ThemeData(
        primaryColor: const Color(0xFF0D47A1),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1565C0),
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1565C0),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}