import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

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
  }

  Future _fetchImages() async {
    if (!_formKey.currentState!.validate()) return;

    final dio = Dio();
    dio.interceptors.add(PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
        maxWidth: 90));

    try {
      debugPrint('Requesting... ${_textController.text}');
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
          'num': 10,
          // 'imgType': 'STOCK',
          // 'imgType': 'LINEART',
        },
      );

      setState(() {
        _images = response.data['items'].map<String>((dynamic item) => item['link'] as String).toList();
      });

      debugPrint(_images.toString());
    } on DioException catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Builded Images URL: $_images');
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _textController,
                decoration: const InputDecoration(hintText: 'Digite o que deseja buscar'),
                validator: (String? value) {
                  if (value == null || value.isEmpty) return 'Por favor, digite algo';
                  return null;
                },
              ),
            ),
            GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              shrinkWrap: true,
              itemCount: _images.length,
              itemBuilder: (context, index) {
                return Image.network(
                  _images[index],
                  fit: BoxFit.cover,
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _fetchImages();
        },
        tooltip: 'Buscar',
        child: const Icon(Icons.search),
      ),
    );
  }
}
