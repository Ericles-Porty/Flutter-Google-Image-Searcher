import 'package:flutter/material.dart';
import 'package:googleapis/customsearch/v1.dart';
import 'package:dio/dio.dart';

class HomePage extends StatefulWidget {
  final String title;

  const HomePage({
    super.key,
    required this.title,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> _images = <String>[];
  late bool _canRequest;
  final _textController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _canRequest = false;
  }

  Future<void> _fetchImagesButton() async {
    _canRequest = true;
    await _fetchImages();
  }

  Future _fetchImages() async {
    debugPrint('Called _fetchImages');
    if (_textController.text.isEmpty) return;
    debugPrint('Passed _textController.text.isEmpty');
    if (!_formKey.currentState!.validate()) return;
    debugPrint('Passed _formKey.currentState!.validate()');

    final dio = Dio();

    try {
      if (!_canRequest) {
        debugPrint('Can\'t request');
        return;
      }

      final response = await dio.get(
        'https://www.googleapis.com/customsearch/v1',
        queryParameters: <String, dynamic>{
          'key': const String.fromEnvironment('GOOGLE_API_KEY'),
          'cx': const String.fromEnvironment('GOOGLE_SEARCH_ID'),
          'q': _textController.text,
          'searchType': 'image',
          'safe': 'active',
          'hl': 'pt-BR',
          'gl': 'br',
          'num': 2,
          // 'imgType': 'STOCK',
          // 'imgType': 'LINEART',
        },
      );

      _images = response.data['items'].map<String>((dynamic item) {
        return item['link'] as String;
      });
      _canRequest = false;

      debugPrint(_images.toString());
    } on DioException catch (e) {
      debugPrint(e.toString());
    }
  }

  Widget _mapStateToWidget(BuildContext context, AsyncSnapshot<dynamic> snapshot) {
    final ConnectionState state = snapshot.connectionState;
    if (state == ConnectionState.none) {
      debugPrint('No connection');
      return const Center(child: Text('No connection'));
    }

    if (state == ConnectionState.waiting) {
      debugPrint('Awaiting result...');
      return const Center(child: Text('Awaiting result...'));
    }

    if (state == ConnectionState.active) {
      debugPrint('Connection active');
      return const Text('Awaiting result...');
    }

    if (snapshot.hasError) {
      debugPrint('Error: ${snapshot.error}');
      return Text('Error: ${snapshot.error}');
    }

    if (state == ConnectionState.done && snapshot.hasData) {
      debugPrint('Done!');
      return ListView.builder(itemBuilder: (BuildContext context, int index) {
        return Image.network(
          _images[index],
          fit: BoxFit.cover,
          height: 200,
          width: 200,
        );
      });
    }

    if (state == ConnectionState.done && !snapshot.hasData) {
      debugPrint('No results found');
      return const Text('No results found');
    }

    debugPrint('Loading...');
    return const CircularProgressIndicator();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: 'Digite o que deseja buscar',
                ),
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, digite algo';
                  }
                  return null;
                },
              ),
            ),
            FutureBuilder(
              future: _fetchImages(),
              builder: _mapStateToWidget,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _fetchImagesButton();
        },
        tooltip: 'Buscar',
        child: const Icon(Icons.search),
      ),
    );
  }
}
