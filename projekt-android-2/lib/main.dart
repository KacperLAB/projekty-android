import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as Path; //"as" żeby uniknąć problemów z kontekstem (context)
import 'package:sqflite/sqflite.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class Telefon {
  int id;
  String producent;
  String model;
  String wersja;
  String obrazek;
  Telefon({
    required this.id,
    required this.producent,
    required this.model,
    required this.wersja,
    required this.obrazek,
  });
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'producent': producent,
      'model': model,
      'wersja': wersja,
      'obrazek': obrazek,
    };
  }
  Map<String, dynamic> toMapNoId() {
    return {
      'producent': producent,
      'model': model,
      'wersja': wersja,
      'obrazek': obrazek,
    };
  }
  @override
  String toString() {
    return 'Telefon{id: $id, producent: $producent, model: $model, wersja: $wersja, obrazek: $obrazek}';
  }
}

class TelefonDatabase {
  static const dbFileName = 'telefon_database.db';
  static const dbVersion = 1;
  static const telefonyTableName = 'telefony';
  static const idColumn = 'id';
  static const producentColumn = 'producent';
  static const modelColumn = 'model';
  static const wersjaColumn = 'wersja';
  static const obrazekColumn = 'obrazek';
  static const createDbSql = 'CREATE TABLE $telefonyTableName'
      '($idColumn INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,'
      '$producentColumn TEXT,'
      '$modelColumn TEXT,'
      '$wersjaColumn TEXT,'
      '$obrazekColumn TEXT)';

  static Future<Database> openTelefonDatabase() async {
    return openDatabase(
      Path.join(await getDatabasesPath(), dbFileName),
      onCreate: (db, version) {
        return db.execute(createDbSql);
      },
      version: dbVersion,
    );
  }

  static Future<List<Telefon>> getTelefony() async {
    final TelefonDatabase = await openTelefonDatabase();
    final List<Map<String, dynamic>> TelefonMapList =
    await TelefonDatabase.query(telefonyTableName);
    return List.generate(TelefonMapList.length, (i) {
      return Telefon(
        id: TelefonMapList[i][idColumn],
        producent: TelefonMapList[i][producentColumn],
        model: TelefonMapList[i][modelColumn],
        wersja: TelefonMapList[i][wersjaColumn],
        obrazek: TelefonMapList[i][obrazekColumn],
      );
    });
  }

  static Future<int> insertTelefon(Telefon telefon) async {
    final TelefonDatabase = await openTelefonDatabase();
    final newItemId = await TelefonDatabase.insert(
      telefonyTableName,
      telefon.toMapNoId(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return newItemId;
  }

  static Future<int> updateTelefon(Telefon telefon) async {
    final telefonDatabase = await openTelefonDatabase();
    final updatedCount = await telefonDatabase.update(
      telefonyTableName,
      telefon.toMap(),
      where: '$idColumn = ?',
      whereArgs: [telefon.id],
    );
    return updatedCount;
  }

  static Future<int> deleteTelefon(int id) async {
    final telefonDatabase = await openTelefonDatabase();
    final deletedCount = await telefonDatabase.delete(
      telefonyTableName,
      where: '$idColumn = ?',
      whereArgs: [id],
    );
    return deletedCount;
  }

  static Future<int> deleteAll() async {
    final telefonDatabase = await openTelefonDatabase();
    final deletedCount = await telefonDatabase.delete(telefonyTableName);
    return deletedCount;
  }
}

// koniec kodu bazy //

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var telefon = Telefon(id: 0, producent: 'Prod1', model: 'Mod1', wersja: 'v1', obrazek: '');
  await TelefonDatabase.insertTelefon(telefon);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Telefony Database',
      home: HomeScreen(),

    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Telefon> _telefonList = [];
  bool _isLoadingData = true;

  void _deleteAllItems() async {
    await TelefonDatabase.deleteAll();
    _loadTelefonList();
  }

  void _loadTelefonList() async {
    final telefonList = await TelefonDatabase.getTelefony();
    setState(() {
      _telefonList = telefonList;
      _isLoadingData = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadTelefonList();
  }

  Widget _buildTelefonList() {
    return ListView.builder(
      itemCount: _telefonList.length,
      itemBuilder: (context, i) => Card(
        color: Colors.lightBlueAccent,
        margin: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
        child: ListTile(
          title: Column(
            children: [
              //Text("Producent: " + _telefonList[i].producent),
              Text("Model: ${_telefonList[i].model}"),
              //Text("Wersja: " + _telefonList[i].wersja),
              //_telefonList[i].obrazek != null
              //   ? Image.file(File(_telefonList[i].obrazek), width: 100, height: 100, fit: BoxFit.cover,) : Container(),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _navigateToEditTelefon(_telefonList[i].id),
                icon: const Icon(Icons.edit),
              ),
              IconButton(
                onPressed: () => _deleteItem(_telefonList[i].id),
                icon: const Icon(Icons.delete),
              ),
            ],
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Telefon database'),
      ),

      body: _isLoadingData
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : _buildTelefonList(),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () => _deleteAllItems(),
            child: const Icon(Icons.delete),
          ),
          const SizedBox(height: 16), // Odstęp między przyciskami
          FloatingActionButton(
            onPressed: () => _navigateToAddTelefon(),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }


  _deleteItem(int id) async {
    await TelefonDatabase.deleteTelefon(id);
    _loadTelefonList();
  }

  _navigateToEditTelefon(int telefonId) {
    final telefon = _telefonList.firstWhere((telefon) => telefon.id == telefonId);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTelefonScreen(telefon: telefon),
      ),
    ).then((value) {
      _loadTelefonList();
    });
  }

  _navigateToAddTelefon() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddTelefonScreen(),
      ),
    ).then((value) {
      _loadTelefonList();
    });
  }
}

class EditTelefonScreen extends StatefulWidget {
  final Telefon telefon;

  const EditTelefonScreen({super.key, required this.telefon});

  @override
  _EditTelefonScreenState createState() => _EditTelefonScreenState();
}

class AddTelefonScreen extends StatefulWidget {
  const AddTelefonScreen({super.key});


  @override
  _AddTelefonScreenState createState() => _AddTelefonScreenState();
}

class _EditTelefonScreenState extends State<EditTelefonScreen> {
  late TextEditingController _modelController;
  late TextEditingController _producentController;
  late TextEditingController _wersjaController;
  File? _selectedImage;


  @override
  void initState() {
    super.initState();
    _modelController = TextEditingController(text: widget.telefon.model);
    _producentController = TextEditingController(text: widget.telefon.producent);
    _wersjaController = TextEditingController(text: widget.telefon.wersja);
    _selectedImage = widget.telefon.obrazek.isNotEmpty ? File(widget.telefon.obrazek) : null;
  }

  @override
  void dispose() {
    _modelController.dispose();
    _producentController.dispose();
    _wersjaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edycja telefonu'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextField(
                  controller: _producentController,
                  autofocus: true,
                  decoration: const InputDecoration(hintText: 'Producent', labelText: 'Producent'),
                ),
                TextField(
                  controller: _modelController,
                  autofocus: false,
                  decoration: const InputDecoration(hintText: 'Model', labelText: 'Model'),
                ),
                TextField(
                  controller: _wersjaController,
                  autofocus: false,
                  decoration: const InputDecoration(hintText: 'Wersja', labelText: 'Wersja'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () => _selectImage(),
                          child: const Text('Wybierz nowy obraz'),
                        ),
                        const SizedBox(width: 16.0),
                        Image.file(_selectedImage!, width: 150, height: 150, fit: BoxFit.cover),
                      ],
                    ),
                  ),
                ),
                Center(child:
                ElevatedButton(
                  onPressed: () => _updateTelefon(),
                  child: const Text('Zapisz zmiany'),
                ),
                ),
                Center(child:
                ElevatedButton(
                  onPressed: () => _deleteItem(widget.telefon.id),
                  child: const Text('Usuń'),
                ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _selectImage() async {
    final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _selectedImage = File(pickedImage.path);
      });
    }
  }

  _deleteItem(int id) async {
    await TelefonDatabase.deleteTelefon(id);
    Navigator.pop(context);
  }

  void _updateTelefon() async {
    final telefon = Telefon(
      id: widget.telefon.id,
      producent: _producentController.text,
      model: _modelController.text,
      wersja: _wersjaController.text,
      obrazek: _selectedImage != null ? _selectedImage!.path : '',
    );

    await TelefonDatabase.updateTelefon(telefon);
    Navigator.pop(context);
  }
}

class _AddTelefonScreenState extends State<AddTelefonScreen> {
  late TextEditingController _modelController;
  late TextEditingController _producentController;
  late TextEditingController _wersjaController;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _modelController = TextEditingController(text: '');
    _producentController = TextEditingController(text: '');
    _wersjaController = TextEditingController(text: '');
    _selectedImage = null;
  }

  @override
  void dispose() {
    _modelController.dispose();
    _producentController.dispose();
    _wersjaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dodawanie telefonu'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextField(
                controller: _producentController,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Producent'),
              ),
              TextField(
                controller: _modelController,
                autofocus: false,
                decoration: const InputDecoration(hintText: 'Model'),
              ),
              TextField(
                controller: _wersjaController,
                autofocus: false,
                decoration: const InputDecoration(hintText: 'Wersja'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => _selectImage(),
                        child: const Text('Wybierz obraz'),
                      ),
                      const SizedBox(width: 16.0),
                      _selectedImage != null
                          ? Image.file(_selectedImage!, width: 150, height: 150, fit: BoxFit.cover)
                          : const Text('Nie wybrano obrazu'),
                    ],
                  ),
                ),
              ),

              Center(child: ElevatedButton(
                onPressed: () => _insertTelefon(),
                child: const Text('Dodaj'),
              ),),

            ],
          ),
        ),
      ),
    );
  }
  void _selectImage() async {
    final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _selectedImage = File(pickedImage.path);
      });
    }
  }
  void _insertTelefon() async {
    await TelefonDatabase.insertTelefon(
      Telefon(
        id: 0,
        producent: _producentController.text,
        model: _modelController.text,
        wersja: _wersjaController.text,
        obrazek: _selectedImage!.path,
      ),
    );
    Navigator.pop(context);
  }
}
