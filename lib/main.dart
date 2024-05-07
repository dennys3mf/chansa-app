import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:chansa_app/openai.dart';


void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    var appState =
        Provider.of<MyAppState>(context); // Obtener el estado de la aplicación
    return MaterialApp(
      title: 'Chansa',
      theme: appState.currentTheme,
      home: MyHomePage(),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();
  var history = <WordPair>[];
  var _darkMode = false;

  String mood = 'Desconocido';
  void predictMood() {
    var moods = ['Feliz', 'Triste', 'Enojado', 'Confundido', 'Cansado'];
    var random = Random();
    mood = moods[random.nextInt(moods.length)];
    notifyListeners();
  }

  bool get isDarkMode => _darkMode;
  bool get isLightMode => !_darkMode;

  ThemeData get currentTheme =>
      _darkMode ? ThemeData.dark() : ThemeData.light();

  void updateTheme(bool isDarkMode) {
    _darkMode = isDarkMode;
    notifyListeners();
  }

  GlobalKey? historyListKey;

  void getNext() {
    history.insert(0, current);
    var animatedList = historyListKey?.currentState as AnimatedListState?;
    animatedList?.insertItem(0);
    current = WordPair.random();
    notifyListeners();
  }

  var favorites = <WordPair>[];

  void toggleFavorite([WordPair? pair]) {
    pair = pair ?? current;
    if (favorites.contains(pair)) {
      favorites.remove(pair);
    } else {
      favorites.add(pair);
    }
    notifyListeners();
  }

  void removeFavorite(WordPair pair) {
    favorites.remove(pair);
    notifyListeners();
  }
}

class MoodDisplay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<MyAppState>(
      builder: (context, appState, child) {
        return Text('Estado de ánimo: ${appState.mood}');
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;

    Widget page;
    switch (selectedIndex) {
      case 0:
        page = GeneratorPage();
        break;
      case 1:
        page = FavoritesPage();
        break;
      case 2:
        page = SettingsPage();
        break;
      case 3:
        page = MoodSelector();
        break;
      case 4:
        page = ChatPage();
        break;
      default:
        throw UnimplementedError('No hay widget para $selectedIndex');
    }

    // The container for the current page, with its background color
    // and subtle switching animation.
    var mainArea = ColoredBox(
      color: colorScheme.surfaceVariant,
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: 340),
        child: page,
      ),
    );

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 450) {
            // Use a more mobile-friendly layout with BottomNavigationBar
            // on narrow screens.
            return Column(
              children: [
                Expanded(child: mainArea),
                SafeArea(
                  child: BottomNavigationBar(
                    items: [
                      BottomNavigationBarItem(
                        icon: Icon(Icons.home,
                            color: Colors.black), // Forzar el color del ícono
                        label: 'Inicio',
                        backgroundColor:
                            Colors.white, // Forzar el color de fondo
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.favorite,
                            color: Colors.black), // Forzar el color del ícono
                        label: 'Favoritos',
                        backgroundColor:
                            Colors.white, // Forzar el color de fondo
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.settings,
                            color: Colors.black), // Forzar el color del ícono
                        label: 'Configuración',
                        backgroundColor:
                            Colors.white, // Forzar el color de fondo
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.mood,
                            color: Colors.black), // Forzar el color del ícono
                        label: 'Estado de ánimo',
                        backgroundColor:
                            Colors.white, // Forzar el color de fondo
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.chat,
                            color: Colors.black), // Forzar el color del ícono
                        label: 'ChatMood',
                        backgroundColor:
                            Colors.white, // Forzar el color de fondo
                      ),
                    ],
                    currentIndex: selectedIndex,
                    onTap: (value) {
                      setState(() {
                        selectedIndex = value;
                      });
                    },
                    selectedItemColor:
                        Colors.black, // Forzar el color del ítem seleccionado
                    unselectedItemColor:
                        Colors.grey, // Forzar el color del ítem no seleccionado
                  ),
                )
              ],
            );
          } else {
            return Row(
              children: [
                SafeArea(
                  child: NavigationRail(
                    extended: constraints.maxWidth >= 600,
                    destinations: [
                      NavigationRailDestination(
                        icon: Icon(Icons.home),
                        label: Text('Inicio'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.favorite),
                        label: Text('Favoritos'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.settings),
                        label: Text('Configuración'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.mood),
                        label: Text('Estado de ánimo'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.chat),
                        label: Text('ChatMood'),
                      ),
                    ],
                    selectedIndex: selectedIndex,
                    onDestinationSelected: (value) {
                      setState(() {
                        selectedIndex = value;
                      });
                    },
                  ),
                ),
                Expanded(child: mainArea),
              ],
            );
          }
        },
      ),
    );
  }
}

class GeneratorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;

    IconData icon;
    if (appState.favorites.contains(pair)) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: HistoryListView(),
          ),
          SizedBox(height: 10),
          BigCard(pair: pair),
          SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  appState.toggleFavorite();
                },
                icon: Icon(icon),
                label: Text('Me gusta'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  appState.getNext();
                },
                child: Text('Siguiente'),
              ),
            ],
          ),
          Spacer(flex: 2),
        ],
      ),
    );
  }
}

class BigCard extends StatelessWidget {
  const BigCard({
    Key? key,
    required this.pair,
  }) : super(key: key);

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );

    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: AnimatedSize(
          duration: Duration(milliseconds: 200),
          // Make sure that the compound word wraps correctly when the window
          // is too narrow.
          child: MergeSemantics(
            child: Wrap(
              children: [
                Text(
                  pair.first,
                  style: style.copyWith(fontWeight: FontWeight.w200),
                ),
                Text(
                  pair.second,
                  style: style.copyWith(fontWeight: FontWeight.bold),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FavoritesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var appState = context.watch<MyAppState>();

    if (appState.favorites.isEmpty) {
      return Center(
        child: Text('No hay favoritos aun.'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(30),
          child: Text('Tu tienes '
              '${appState.favorites.length} favoritos:'),
        ),
        Expanded(
          // Make better use of wide windows with a grid.
          child: GridView(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 400,
              childAspectRatio: 400 / 80,
            ),
            children: [
              for (var pair in appState.favorites)
                ListTile(
                  leading: IconButton(
                    icon: Icon(Icons.delete_outline, semanticLabel: 'Eliminar'),
                    color: theme.colorScheme.primary,
                    onPressed: () {
                      appState.removeFavorite(pair);
                    },
                  ),
                  title: Text(
                    pair.asLowerCase,
                    semanticsLabel: pair.asPascalCase,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class DarkPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Modo oscuro',
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  @override
  // ignore: library_private_types_in_public_api
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configuración'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Modo oscuro',
                style: TextStyle(
                  fontSize: 20.0, // Cambia el tamaño de la fuente
                  fontWeight: FontWeight.bold, // Hace que la fuente sea negrita
                  color: Colors.blue, // Cambia el color del texto
                ),
              ),
              Switch(
                value: Provider.of<MyAppState>(context).isDarkMode,
                onChanged: (value) {
                  // Notificar a los widgets que escuchan el tema sobre el cambio
                  Provider.of<MyAppState>(context, listen: false)
                      .updateTheme(value);
                },
              ),
            ],
          ),
          AboutDialog(
            applicationName: 'Chansa',
            applicationVersion: '1.0.0',
            applicationIcon: Icon(Icons.favorite),
            children: [
              Text('Chansa es una aplicación de prueba.'),
              Text('Hecha por: Chansa'),
            ],
          ),
        ],
      ),
    );
  }
}

class HistoryListView extends StatefulWidget {
  const HistoryListView({Key? key}) : super(key: key);

  @override
  State<HistoryListView> createState() => _HistoryListViewState();
}

class _HistoryListViewState extends State<HistoryListView> {
  /// Needed so that [MyAppState] can tell [AnimatedList] below to animate
  /// new items.
  final _key = GlobalKey();

  /// Used to "fade out" the history items at the top, to suggest continuation.
  static const Gradient _maskingGradient = LinearGradient(
    // This gradient goes from fully transparent to fully opaque black...
    colors: [Colors.transparent, Colors.black],
    // ... from the top (transparent) to half (0.5) of the way to the bottom.
    stops: [0.0, 0.5],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<MyAppState>();
    appState.historyListKey = _key;

    return ShaderMask(
      shaderCallback: (bounds) => _maskingGradient.createShader(bounds),
      // This blend mode takes the opacity of the shader (i.e. our gradient)
      // and applies it to the destination (i.e. our animated list).
      blendMode: BlendMode.dstIn,
      child: AnimatedList(
        key: _key,
        reverse: true,
        padding: EdgeInsets.only(top: 100),
        initialItemCount: appState.history.length,
        itemBuilder: (context, index, animation) {
          final pair = appState.history[index];
          return SizeTransition(
            sizeFactor: animation,
            child: Center(
              child: TextButton.icon(
                onPressed: () {
                  appState.toggleFavorite(pair);
                },
                icon: appState.favorites.contains(pair)
                    ? Icon(Icons.favorite, size: 12)
                    : SizedBox(),
                label: Text(
                  pair.asLowerCase,
                  semanticsLabel: pair.asPascalCase,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class MoodSelector extends StatefulWidget {
  @override
  _MoodSelectorState createState() => _MoodSelectorState();
}

class _MoodSelectorState extends State<MoodSelector>
    with TickerProviderStateMixin {
  String? _selectedMood;
  String? _message;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Selecciona tu estado de ánimo'),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('./assets/images/background-chansa.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              DropdownButton<String>(
                value: _selectedMood,
                hint: Text('Selecciona un estado de ánimo'),
                items: <String>[
                  'Feliz',
                  'Triste',
                  'Enojado',
                  'Confundido',
                  'Cansado'
                ].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Row(
                      children: <Widget>[
                        Image.asset('assets/images/$value.png',
                            width: 25), // Añade esta línea
                        SizedBox(
                            width:
                                10), // Añade esta línea para dar un poco de espacio
                        Text(value),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedMood = newValue;
                    switch (_selectedMood) {
                      case 'Feliz':
                        _message = '¡Genial, sigue así!';
                        break;
                      case 'Triste':
                        _message = 'Espero que te sientas mejor pronto.';
                        break;
                      case 'Enojado':
                        _message = 'Respira hondo y trata de calmarte.';
                        break;
                      case 'Confundido':
                        _message =
                            'Tómate un momento para aclarar tus pensamientos.';
                        break;
                      case 'Cansado':
                        _message = 'Asegúrate de descansar bien.';
                        break;
                    }
                  });
                  _controller.reset();
                  _controller.forward();
                },
              ),
              if (_message != null)
                FadeTransition(
                  opacity: _animation,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _message!,
                      style: TextStyle(fontSize: 24),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  List<String> _messages = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat Page'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_messages[index]),
                  );
                },
              ),
            ),
            TextFormField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Escribe un mensaje',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, escribe un mensaje';
                }
                return null;
              },
            ),
            IconButton(
              icon: Icon(Icons.send),
              onPressed: () {
                if (_formKey.currentState?.validate() ?? false) {
                  setState(() {
                    _messages.add(_controller.text);
                    _controller.clear();
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
