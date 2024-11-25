import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Harry Potter Characters',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CharacterListScreen(),
    );
  }
}

class Character {
  final String name;
  final String house;
  final String imageUrl;
  double score; // Agregamos el atributo score para la puntuación

  Character({
    required this.name,
    required this.house,
    required this.imageUrl,
    this.score = 5.0, // Valor predeterminado 5/10
  });

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      name: json['name'],
      house: json['house'] ?? 'Unknown',  // En caso de que 'house' sea nulo
      imageUrl: json['image'] ?? '',  // Suponiendo que 'image' es el campo para la imagen del personaje
    );
  }
}

class CharacterListScreen extends StatefulWidget {
  const CharacterListScreen({super.key});

  @override
  _CharacterListScreenState createState() => _CharacterListScreenState();
}

class _CharacterListScreenState extends State<CharacterListScreen> {
  late Future<List<Character>> characters;
  List<Character> characterList = [];  // Guardamos la lista de personajes en estado

  Future<List<Character>> fetchCharacters() async {
    final response = await http.get(Uri.parse('https://hp-api.onrender.com/api/characters'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((item) => Character.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load characters');
    }
  }

  // Método para mostrar el diálogo con la imagen grande y la barra deslizante
  void _showCharacterDetails(BuildContext context, int index) {
    final character = characterList[index];  // Obtener el personaje seleccionado
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(  // Usamos StatefulBuilder para actualizar el Slider
          builder: (context, setState) {
            return AlertDialog(
              title: Text(character.name),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Mostrar la imagen en grande
                  character.imageUrl.isNotEmpty
                      ? Image.network(character.imageUrl)
                      : Icon(Icons.person, size: 100),
                  SizedBox(height: 10),
                  // Mostrar la casa
                  Text('House: ${character.house}'),
                  SizedBox(height: 10),
                  // Barra deslizante para cambiar la puntuación
                  Text('Rating: ${character.score.toStringAsFixed(1)} / 10'),
                  Slider(
                    value: character.score,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: character.score.toStringAsFixed(1),
                    onChanged: (newScore) {
                      setState(() {
                        character.score = newScore;  // Actualiza la puntuación del personaje
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      characterList[index] = character;  // Actualizar la lista de personajes con el nuevo valor
                    });
                    Navigator.of(context).pop();
                  },
                  child: Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    characters = fetchCharacters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Harry Potter Characters'),
      ),
      body: FutureBuilder<List<Character>>(
        future: characters,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No characters found.'));
          } else {
            characterList = snapshot.data!;  // Guardamos los personajes en estado
            return Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/background.jpg'),
                  fit: BoxFit.cover, // Asegura que la imagen cubra toda la pantalla
                ),
              ),
              child: ListView.builder(
                itemCount: characterList.length,
                itemBuilder: (context, index) {
                  final character = characterList[index];
                  return Card(
                    margin: EdgeInsets.all(10),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(10),
                      leading: character.imageUrl.isNotEmpty
                          ? Image.network(character.imageUrl, width: 50, height: 50)
                          : Icon(Icons.person, size: 50), // Ícono de marcador si no hay imagen
                      title: Text(character.name),
                      subtitle: Text('House: ${character.house}\nRating: ${character.score.toStringAsFixed(1)} / 10'),
                      onTap: () => _showCharacterDetails(context, index), // Al hacer clic, se muestra el detalle
                    ),
                  );
                },
              ),
            );
          }
        },
      ),
    );
  }
}
