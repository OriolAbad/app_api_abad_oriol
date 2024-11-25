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
  double score; 

  Character({
    required this.name,
    required this.house,
    required this.imageUrl,
    this.score = 5.0, // Valor predeterminado 5/10
  });

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      name: json['name'],
      house: json['house'] ?? 'Unknown',  
      imageUrl: json['image'] ?? '',  
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
  List<Character> characterList = [];  

  Future<List<Character>> fetchCharacters() async {
    final response = await http.get(Uri.parse('https://hp-api.onrender.com/api/characters'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((item) => Character.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load characters');
    }
  }

  void _showCharacterDetails(BuildContext context, int index) {
    final character = characterList[index];  
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder( 
          builder: (context, setState) {
            return AlertDialog(
              title: Text(character.name),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  character.imageUrl.isNotEmpty
                      ? Image.network(character.imageUrl)
                      : Icon(Icons.person, size: 100),
                  SizedBox(height: 10),
                  Text('House: ${character.house}'),
                  SizedBox(height: 10),
                  Text('Rating: ${character.score.toStringAsFixed(1)} / 10'),
                  Slider(
                    value: character.score,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: character.score.toStringAsFixed(1),
                    onChanged: (newScore) {
                      setState(() {
                        character.score = newScore; 
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      characterList[index] = character; 
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
            characterList = snapshot.data!;  
            return Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/background.jpg'),
                  fit: BoxFit.cover, 
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
                          : Icon(Icons.person, size: 50), 
                      title: Text(character.name),
                      subtitle: Text('House: ${character.house}\nRating: ${character.score.toStringAsFixed(1)} / 10'),
                      onTap: () => _showCharacterDetails(context, index),
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
