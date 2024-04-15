import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as Path;

class Person {
  int? id;
  String name;
  String phoneNumber;
  String imageUrl;
  Uint8List? imageBytes;

  Person({
    this.id,
    required this.name,
    required this.phoneNumber,
    required this.imageUrl,
    required this.imageBytes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'imageUrl': imageUrl,
      'imageBytes': imageBytes,
    };
  }

  Map<String, dynamic> toMapNoId() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'imageUrl': imageUrl,
      'imageBytes': imageBytes,
    };
  }

  Person.fromJson(Map<String, dynamic> json)
      : id = null,
        name = "${json["name"]["title"]} ${json["name"]["first"]} ${json["name"]["last"]}",
        phoneNumber = json["phone"],
        imageUrl = json["picture"]["large"];

  Future<void> loadImageBytes() async {
    if (imageUrl.isNotEmpty) {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        imageBytes = response.bodyBytes;
      }
    }
  }
}

class PersonDatabase {
  static const dbFileName = 'person_database.db';
  static const dbVersion = 1;
  static const personsTableName = 'persons';
  static const idColumn = 'id';
  static const nameColumn = 'name';
  static const phoneNumberColumn = 'phoneNumber';
  static const imageUrlColumn = 'imageUrl';
  static const imageBytesColumn = 'imageBytes';
  static const createDbSql = 'CREATE TABLE $personsTableName'
      '($idColumn INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,'
      '$nameColumn TEXT,'
      '$phoneNumberColumn TEXT,'
      '$imageUrlColumn TEXT,'
      '$imageBytesColumn BLOB)';

  static Future<Database> openPersonDatabase() async {
    return openDatabase(
      Path.join(await getDatabasesPath(), dbFileName),
      onCreate: (db, version) {
        return db.execute(createDbSql);
      },
      version: dbVersion,
    );
  }

  static Future<List<Person>> getPersons() async {
    final personDatabase = await openPersonDatabase();
    final List<Map<String, dynamic>> personMapList =
    await personDatabase.query(personsTableName);
    return List.generate(personMapList.length, (i) {
      return Person(
        id: personMapList[i][idColumn],
        name: personMapList[i][nameColumn],
        phoneNumber: personMapList[i][phoneNumberColumn],
        imageUrl: personMapList[i][imageUrlColumn],
        imageBytes: personMapList[i][imageBytesColumn],
      );
    });
  }

  static Future<int> insertPerson(Person person) async {
    final personDatabase = await openPersonDatabase();
    final newItemId = await personDatabase.insert(
      personsTableName,
      person.toMapNoId(),
    );
    return newItemId;
  }

  static Future<int> updatePerson(Person person) async {
    final personDatabase = await openPersonDatabase();
    final updatedCount = await personDatabase.update(
      personsTableName,
      person.toMap(),
      where: '$idColumn = ?',
      whereArgs: [person.id],
    );
    return updatedCount;
  }

  static Future<int> deletePerson(int id) async {
    final personDatabase = await openPersonDatabase();
    final deletedCount = await personDatabase.delete(
      personsTableName,
      where: '$idColumn = ?',
      whereArgs: [id],
    );
    return deletedCount;
  }

  static Future<int> deleteAllPersons() async {
    final personDatabase = await openPersonDatabase();
    final deletedCount = await personDatabase.delete(
      personsTableName,
    );
    return deletedCount;
  }
}

const String randomPersonURL = "https://randomuser.me/api/";

class PersonNetworkService {
  Future<List<Person>> fetchPersons(int amount) async {
    http.Response response =
    await http.get(Uri.parse('$randomPersonURL?results=$amount'));
    if (response.statusCode == 200) {
      Map peopleData = jsonDecode(response.body);
      List<dynamic> peoples = peopleData["results"];
      return peoples.map((json) => Person.fromJson(json)).toList();
    } else {
      throw Exception("Something went wrong: ${response.statusCode}");
    }
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool online = true;
  final PersonNetworkService personService = PersonNetworkService();
  TextEditingController amountController = TextEditingController();
  int amount = 10;
  List<Person> savedPersons = [];

  Future<void> refreshData() async {
    setState(() {
      amount = int.tryParse(amountController.text) ?? amount;
    });
    final persons = await personService.fetchPersons(amount);
    for (var person in persons) {
      await person.loadImageBytes();
    }
    setState(() {
      savedPersons = persons;
    });
  }

  Future<void> saveData() async {
    for (var person in savedPersons) {
      person.imageBytes ?? await person.loadImageBytes();
      await PersonDatabase.insertPerson(person);
    }
  }

  Future<void> loadSavedData() async {
    final persons = await PersonDatabase.getPersons();
    setState(() {
      savedPersons = persons;
    });
  }

  Future<void> clearSavedData() async {
    await PersonDatabase.deleteAllPersons();
    setState(() {
      savedPersons = [];
    });
  }

  Future<void> editPerson(BuildContext context, Person person) async {
    if (person.id == null) {
      return;
    }
    final updatedPerson = await showDialog<Person>(
      context: context,
      builder: (BuildContext context) {
        String name = person.name;
        String phoneNumber = person.phoneNumber;

        return AlertDialog(
          title: const Text('Edit Person'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  onChanged: (value) {
                    name = value;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Name',
                  ),
                  controller: TextEditingController(text: person.name),
                ),
                TextField(
                  onChanged: (value) {
                    phoneNumber = value;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                  ),
                  controller: TextEditingController(text: person.phoneNumber),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                person.name = name;
                person.phoneNumber = phoneNumber;
                Navigator.of(context).pop(person);
              },
            ),
          ],
        );
      },
    );

    if (updatedPerson != null) {
      await PersonDatabase.updatePerson(updatedPerson);
      await loadSavedData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lab5',
      theme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Lab5'),
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (online)
                const Text("Online")
              else
                const Text("Offline"),
              Container(
                alignment: Alignment.center,
                margin: const EdgeInsets.all(10),
                height: 50,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        textAlign: TextAlign.center,
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Ilosc do pobrania',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: online ? refreshData : null,
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: online ? saveData : null,
                    child: const Text('Save Data'),
                  ),
                  ElevatedButton(
                    onPressed: online ? loadSavedData : null,
                    child: const Text('Load Saved Data'),
                  ),
                  ElevatedButton(
                    onPressed: clearSavedData,
                    child: const Text('Clear Saved Data'),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Switch(
                    value: online,
                    activeColor: Colors.blue,
                    onChanged: (bool value) {
                      if (!value) {
                        loadSavedData();
                      }
                      // This is called when the user toggles the switch.
                      setState(() {
                        online = value;
                      });
                    },
                  )
                ],
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: savedPersons.length,
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                      leading: savedPersons[index].imageBytes != null
                          ? Image.memory(savedPersons[index].imageBytes!)
                          : const CircularProgressIndicator(),
                      title: Text(savedPersons[index].name),
                      subtitle: Text(savedPersons[index].phoneNumber),
                      onTap: () {
                        editPerson(context, savedPersons[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
