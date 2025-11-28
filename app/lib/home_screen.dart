import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'main.dart';         // Importa modelos
import 'login_screen.dart'; // Para poder salir (logout)
import 'dart:io';

// --- PANTALLA DE LISTA DE PAQUETES ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text("Hola, ${auth.usuario?.nombre ?? 'Repartidor'}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              auth.logout();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          )
        ],
      ),
      body: FutureBuilder<List<Paquete>>(
        future: auth.obtenerPaquetes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No tienes entregas pendientes."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final p = snapshot.data![index];
              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                elevation: 3,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(15),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE3F2FD),
                    child: Icon(Icons.inventory_2, color: Color(0xFF1565C0)),
                  ),
                  title: Text(p.descripcion, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(p.direccion),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    // Al regresar, recargamos la lista por si entregó
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => DetalleEntregaScreen(paquete: p)));
                    setState(() {}); 
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// --- PANTALLA DE DETALLE Y ENTREGA ---
class DetalleEntregaScreen extends StatefulWidget {
  final Paquete paquete;
  const DetalleEntregaScreen({super.key, required this.paquete});

  @override
  State<DetalleEntregaScreen> createState() => _DetalleEntregaScreenState();
}

class _DetalleEntregaScreenState extends State<DetalleEntregaScreen> {
  XFile? _imagen;
  bool _enviando = false;

  Future<void> _abrirMapa() async {
    // Codificar dirección para URL
    final query = Uri.encodeComponent(widget.paquete.direccion);
    // Usamos el buscador genérico de Google Maps
    final googleUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$query");
    
    if (await canLaunchUrl(googleUrl)) {
      await launchUrl(googleUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No se pudo abrir el mapa")));
    }
  }

  Future<void> _tomarFoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery); 
    if (image != null) {
      setState(() => _imagen = image);
    }
  }

  Future<void> _confirmarEntrega() async {
    if (_imagen == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Debes tomar una foto de evidencia")));
      return;
    }

    setState(() => _enviando = true);
    
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final exito = await auth.entregarPaquete(widget.paquete.id, _imagen!, position.latitude, position.longitude);

      if (exito && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Entrega registrada con éxito"), backgroundColor: Colors.green));
        Navigator.pop(context); // Regresa a la lista
      } else {
        throw Exception("Error en API");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al entregar: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Detalle de Entrega")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // INFORMACIÓN
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Paquete #${widget.paquete.id}", style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 10),
                    Text(widget.paquete.descripcion, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const Divider(height: 30),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Color(0xFF1565C0)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(widget.paquete.direccion, style: const TextStyle(fontSize: 16))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),

            // BOTÓN MAPA
            OutlinedButton.icon(
              onPressed: _abrirMapa,
              icon: const Icon(Icons.map),
              label: const Text("VER RUTA EN MAPA"),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(15),
                foregroundColor: const Color(0xFF1565C0),
              ),
            ),

            const SizedBox(height: 30),
            const Text("Evidencia de Entrega", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),

            // AREA DE FOTO
            InkWell(
              onTap: _tomarFoto,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _imagen == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                          Text("Tocar para subir foto"),
                        ],
                      )
                    : kIsWeb 
                        ? Image.network(_imagen!.path, fit: BoxFit.cover) 
                        : Image.file(File(_imagen!.path), fit: BoxFit.cover), // Corrección para que no de error
              ),
            ),

            const SizedBox(height: 30),

            // BOTÓN FINAL
            ElevatedButton(
              onPressed: _enviando ? null : _confirmarEntrega,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: _enviando 
                ? const Text("Procesando...") 
                : const Text("CONFIRMAR ENTREGA"),
            )
          ],
        ),
      ),
    );
  }
}
