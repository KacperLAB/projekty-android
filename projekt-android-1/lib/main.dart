import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Formularz',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ScaffoldMessenger(
        key: GlobalKey<ScaffoldMessengerState>(),
        child: const MyHomePage(title: 'Formularz'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _levelController = TextEditingController();
  double _sliderValue = 0;
  bool _isFormValid = false;
  bool _isSliderActive = false;
  File? _imageFile;

  final FocusNode _firstNameNode = FocusNode();
  final FocusNode _lastNameNode = FocusNode();
  final FocusNode _levelNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _firstNameNode.addListener(_onFocusChange1);
    _lastNameNode.addListener(_onFocusChange2);
    _levelNode.addListener(_onFocusChange3);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _firstNameNode.removeListener(_onFocusChange1);
    _firstNameNode.dispose();

    _lastNameController.dispose();
    _lastNameNode.removeListener(_onFocusChange2);
    _lastNameNode.dispose();

    _levelController.dispose();
    _levelNode.removeListener(_onFocusChange3);
    _levelNode.dispose();

    super.dispose();
  }

  void _onFocusChange1() {
    if (!_firstNameNode.hasFocus && _firstNameController.text.isEmpty) {
      _showSnackbar('Podaj poprawne imie');
    }
  }
  void _onFocusChange2() {
    if (!_lastNameNode.hasFocus && _lastNameController.text.isEmpty) {
      _showSnackbar('Podaj poprawne nazwisko');
    }
  }
  void _onFocusChange3() {

    if (!_levelNode.hasFocus && _levelController.text.isEmpty) {
      _showSnackbar('Podaj poprawny poziom');
    }
    if (!_levelNode.hasFocus && _levelController.text.isNotEmpty)
    {
      int level = int.tryParse(_levelController.text)!;
      if(level<0 || level>100 || level%4!=0) {
        _showSnackbar('Poziom musi byc z zakresu <0-100> i podzielny przez 4');
      }
    }
  }
  void _showSnackbar(String message) {
    //final snackBar = SnackBar(content: Text(message));
    //ScaffoldMessenger.of(context).showSnackBar(snackBar);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: "OK",
          onPressed: () {},
        ),
      ),
    );
  }


  Future<void> _pickImage() async {
    final pickedImage =
    await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _imageFile = File(pickedImage.path);
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('Wynik'),
            ),
            body: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('Imie: ${_firstNameController.text}'),
                      Text('Nazwisko: ${_lastNameController.text}'),
                      Text('Poziom: ${_levelController.text}'),
                      const SizedBox(height: 20),
                      if (_imageFile != null)
                        Image.file(
                          _imageFile!,
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Edytuj'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Formularz'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            onChanged: () {
              setState(() {
                _isFormValid = _formKey.currentState?.validate() ?? false;
              });
            },
            child: Column(
              children: <Widget>[
                TextFormField(
                  controller: _firstNameController,
                  focusNode: _firstNameNode,
                  decoration: const InputDecoration(
                    labelText: 'Imię',
                  ),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Pole imienia nie może być puste';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _lastNameController,
                  focusNode: _lastNameNode,
                  decoration: const InputDecoration(
                    labelText: 'Nazwisko',
                  ),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Pole nazwiska nie może być puste';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _levelController,
                  focusNode: _levelNode,
                  decoration: const InputDecoration(
                    labelText: 'Poziom',
                  ),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Pole poziomu nie może być puste';
                    }
                    final int level = int.tryParse(value)!;
                    if (level < 0 || level > 100 || level % 4 != 0) {
                      return 'Poziom musi być liczbą z przedziału <0, 100> podzielną przez 4';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _pickImage,
                  child: const Text('Wybierz zdjęcie'),
                ),

                const SizedBox(height: 20),
                if (_imageFile != null)
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: Image.file(
                          _imageFile!,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Text(
                        _levelController.text,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isFormValid && _imageFile!=null
                      ? () {
                    setState(() {
                      _isSliderActive = true;
                    });
                    _submitForm();
                  }
                      : null,
                  child: const Text('Wyślij'),
                ),
                const SizedBox(height: 20),
                Slider(
                  value: _sliderValue,
                  min: 0,
                  max: 100,
                  divisions: 25,
                  label: _sliderValue.round().toString(),
                  onChanged: _isSliderActive
                      ? (value) {
                    setState(() {
                      _sliderValue = value;
                      _levelController.text = value.toString();
                    });
                  }
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
