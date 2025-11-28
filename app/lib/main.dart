import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';

// API en localhost (Chrome NO usa 0.0.0.0)
const String apiUrl = "http://localhost:8000";

void main() {
	runApp(const MyApp());
}

class MyApp extends StatelessWidget {
	const MyApp({super.key});

	@override
	Widget build(BuildContext context) {
		return MaterialApp(
			debugShowCheckedModeBanner: false,
			title: 'Práctica 10 - Flutter',
			theme: ThemeData(primarySwatch: Colors.blue),
			home: const HomePage(),
		);
	}
}

class HomePage extends StatefulWidget {
	const HomePage({super.key});

	@override
	_HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
	File? imagenLocal;
	Uint8List? imagenWeb;
	String? nombreArchivo;
	final TextEditingController descCtrl = TextEditingController();

	Future<void> seleccionarImagen() async {
		final picker = ImagePicker();
		final XFile? img = await picker.pickImage(source: ImageSource.gallery);

		if (img == null) return;

		nombreArchivo = img.name;

		if (kIsWeb) {
			imagenWeb = await img.readAsBytes();
			imagenLocal = null;
		} else {
			imagenLocal = File(img.path);
			imagenWeb = null;
		}

		setState(() {});
	}

	Future<void> subirImagen() async {
		if (imagenLocal == null && imagenWeb == null) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text("Selecciona una imagen primero")),
			);
			return;
		}

		try {
			final url = Uri.parse("$apiUrl/fotos/");
			var request = http.MultipartRequest("POST", url);

			request.fields["descripcion"] = descCtrl.text.trim();

			if (kIsWeb) {
				request.files.add(
					http.MultipartFile.fromBytes(
						'file',
						imagenWeb!,
						filename: nombreArchivo ?? "imagen.png",
					),
				);
			} else {
				request.files.add(
					await http.MultipartFile.fromPath(
						"file",
						imagenLocal!.path,
						filename: nombreArchivo,
					),
				);
			}

			final response = await request.send();

			if (response.statusCode == 200) {
				ScaffoldMessenger.of(context).showSnackBar(
					const SnackBar(
						content: Text("Imagen subida correctamente"),
						backgroundColor: Colors.green,
					),
				);

				descCtrl.clear();
				imagenLocal = null;
				imagenWeb = null;
				nombreArchivo = null;

				setState(() {});
			} else {
				print("Error al subir (status): ${response.statusCode}");
			}
		} catch (e) {
			print("Error al subir imagen: $e");
		}
	}

	Widget vistaPrevia() {
		if (imagenLocal == null && imagenWeb == null) {
			return Container(
				height: 220,
				alignment: Alignment.center,
				child: const Text("No hay imagen seleccionada"),
			);
		}

		return Container(
			constraints: const BoxConstraints(maxHeight: 400),
			margin: const EdgeInsets.only(bottom: 20),
			child: kIsWeb
					? Image.memory(imagenWeb!, fit: BoxFit.contain)
					: Image.file(imagenLocal!, fit: BoxFit.contain),
		);
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: const Text("Práctica 10 - Flutter")),
			body: ListView(
				padding: const EdgeInsets.all(15),
				children: [
					const Text(
						"Subir Foto",
						style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
					),

					const SizedBox(height: 20),

					vistaPrevia(),

					TextField(
						controller: descCtrl,
						decoration: const InputDecoration(
							labelText: "Descripción",
							border: OutlineInputBorder(),
						),
					),

					const SizedBox(height: 20),

					ElevatedButton.icon(
						onPressed: seleccionarImagen,
						icon: const Icon(Icons.photo),
						label: const Text("Seleccionar Imagen"),
						style: ElevatedButton.styleFrom(
							backgroundColor: Colors.blue,
							minimumSize: const Size(double.infinity, 50),
						),
					),

					const SizedBox(height: 10),

					ElevatedButton.icon(
						onPressed: subirImagen,
						icon: const Icon(Icons.cloud_upload),
						label: const Text("Subir a la API"),
						style: ElevatedButton.styleFrom(
							backgroundColor: Colors.green,
							minimumSize: const Size(double.infinity, 50),
						),
					),
				],
			),
		);
	}
}
