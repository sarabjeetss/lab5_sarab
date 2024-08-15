import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:async';
import 'dart:math';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pokémon Cards',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[200], // Set background color
      ),
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 5), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => PokemonListScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          'assets/splash.jpg',
          fit: BoxFit.cover,
          height: double.infinity,
          width: double.infinity,
          alignment: Alignment.center,
        ),
      ),
    );
  }
}

class PokemonListScreen extends StatefulWidget {
  @override
  _PokemonListScreenState createState() => _PokemonListScreenState();
}

class _PokemonListScreenState extends State<PokemonListScreen> {
  List<dynamic> pokemonCards = [];
  List<dynamic> filteredCards = [];
  List<dynamic> randomCards = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchPokemonCards();
  }

  Future<void> fetchPokemonCards() async {
    final dio = Dio();
    final response = await dio.get(
        'https://api.pokemontcg.io/v2/cards?q=name:gardevoir');

    setState(() {
      pokemonCards = response.data['data'];
      filteredCards = pokemonCards;
      randomCards = getRandomCards(); // Get ten random cards
      isLoading = false;
    });
  }

  List<dynamic> getRandomCards() {
    final random = Random();
    final randomSet = <dynamic>{};
    while (randomSet.length < 10 && pokemonCards.length > randomSet.length) {
      randomSet.add(pokemonCards[random.nextInt(pokemonCards.length)]);
    }
    return randomSet.toList();
  }

  void filterCards(String query) {
    setState(() {
      searchQuery = query;
      filteredCards = pokemonCards.where((card) {
        final name = card['name'].toLowerCase();
        final searchLower = query.toLowerCase();
        return name.contains(searchLower);
      }).toList();
    });
  }

  int extractHp(String hpString) {
    final match = RegExp(r'(\d+)').firstMatch(hpString);
    return match != null ? int.tryParse(match.group(0) ?? '0') ?? 0 : 0;
  }

  void showImageDialog(String imageUrl, String winnerText) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            color: Colors.black,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InteractiveViewer(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                  ),
                  minScale: 0.1,
                  maxScale: 4.0,
                ),
                SizedBox(height: 16.0),
                Text(
                  winnerText,
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                  ),
                ),
                SizedBox(height: 16.0),
              ],
            ),
          ),
        );
      },
    );
  }

  void selectWinner() {
    if (randomCards.isEmpty) return;

    dynamic winnerCard;
    int maxHp = 0;

    for (final card in randomCards) {
      final hp = card['hp'] != null ? extractHp(card['hp']) : 0;
      if (hp > maxHp) {
        maxHp = hp;
        winnerCard = card;
      }
    }

    if (winnerCard != null) {
      showImageDialog(winnerCard['images']['large'], 'Winner card with HP: $maxHp');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF87CEEB), // Set the AppBar color to sky blue
        title: Text(
          'Pokémon Cards',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(56.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              onChanged: filterCards,
              decoration: InputDecoration(
                hintText: 'Search Pokémon...',
                hintStyle: TextStyle(fontWeight: FontWeight.normal),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                fillColor: Colors.white, // Set background color to white
                filled: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8.0),
              ),
            ),
          ),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(8.0),
              itemCount: randomCards.length,
              itemBuilder: (context, index) {
                final card = randomCards[index];
                return Container(
                  color: index.isEven ? Colors.white : Color(0xFF87CEEB), // Alternate row colors
                  child: Card(
                    margin: EdgeInsets.symmetric(vertical: 4.0),
                    elevation: 4.0,
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16.0),
                      leading: SizedBox(
                        width: 60, // Reduced size to 40% of original
                        height: 60, // Reduced size to 40% of original
                        child: Image.network(card['images']['small'], fit: BoxFit.cover),
                      ),
                      title: Text(
                        card['name'],
                        style: TextStyle(fontWeight: FontWeight.bold), // Make text bold
                      ),
                      onTap: () {
                        showImageDialog(card['images']['large'], '');
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: selectWinner,
              child: Text('Select'),
            ),
          ),
        ],
      ),
    );
  }
}
