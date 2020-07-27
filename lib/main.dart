import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Speech To Text Flutter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SpeechScreen(),
    );
  }
}

class SpeechScreen extends StatefulWidget {
  @override
  _SpeechScreenState createState() => _SpeechScreenState();
}

class _SpeechScreenState extends State<SpeechScreen> {

  SpeechToText _speech;
  LocaleName _localeName;
  bool _initialized = false;

  bool _isListening = false;
  String _text = '< Press the button and start speaking >';
  double _confidence = 1.0;

  @override
  void initState() {
    super.initState();
    _speech = SpeechToText();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      _initialized = await _speech.initialize(onStatus: (status) async {
        print('on status: $status');
        if (status == "listening" || status == "notListening") {
          setState(() {
            _isListening = status == "listening";
          });
        }
      }, onError: (e) async {
        print(e);
        showSnack('$e');
        await _speech.stop();
      });
      //
      final systemLocale = await _speech.systemLocale();
      setState(() {
        _localeName = systemLocale;
      });
      print('Initialized: $_initialized, ${systemLocale.localeId} ${systemLocale.name}');
    });
  }

  showSnack(String text) {
    scafKey.currentState.showSnackBar(SnackBar(
      content: Text(text),
    ));
  }

  final scafKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scafKey,
      appBar: AppBar(
        title: Text("Speech To Text"),
      ),
      body: Column(
        children: [
          Container(
            height: MediaQuery.of(context).size.height*.15,
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: FutureBuilder<List<LocaleName>>(
                future: _speech.locales(),
                builder: (context, snapshot) {
                  print("_speech.locales(): ${snapshot.data?.map((e) => e.localeId)}");
                  if (!snapshot.hasData) return SizedBox.shrink();
                  final locales = snapshot.data;
                  locales.sort((l1, l2) => l1.name.compareTo(l2.name));
                  print(
                      "_localeName: ${_localeName.localeId + " " + _localeName.name}");
                  print(
                      "locales.contains(_localeName): ${locales.contains(_localeName)}");
                  if (_localeName != null) {
                    _localeName = locales.firstWhere((element) =>
                    element.name == _localeName.name &&
                        element.localeId == _localeName.localeId);
                  }
                  return Center(
                    child: DropdownButton<LocaleName>(
                      onTap: () async {
                        await _speech.stop();
                      },
                      value: _localeName,
                      items: locales.map((value) {
                        return DropdownMenuItem<LocaleName>(
                          value: value,
                          child: LimitedBox(
                            maxWidth: MediaQuery.of(context).size.width*.7,
                            child: Text(
                              value.name + " - ${value.localeId}",
                              style: Theme.of(context).textTheme.bodyText1,
                            ),
                          ),
                        );
                      })?.toList(),
                      onChanged: (LocaleName value) async {
                        print('changed to ${value.localeId + " " + value.name}');
                        setState(() {
                          _localeName = value;
                        });
                        await _speech.stop();
                      },
                    ),
                  );
                }),
          ),
          SizedBox(height: MediaQuery.of(context).size.height*.05,),
          Flexible(
            child: Container(
              alignment: Alignment.center,
              child: SingleChildScrollView(
                reverse: true,
                child: Container(
                  padding: const EdgeInsets.all(30),
                  child: Text(
                    _text ?? "",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 32.0,
                      color: Colors.black,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
//              child: TextHighlight(
//                text: _text,
//                words: _highlights,
//                textStyle: const TextStyle(
//                  fontSize: 32.0,
//                  color: Colors.black,
//                  fontWeight: FontWeight.w400,
//                ),
//              ),
                ),
              ),
            ),
          ),
          Text(
            'Confidence: ${(_confidence * 100.0).toStringAsFixed(1)}%',
            style: TextStyle(
              color: Colors.grey
            ),
          ),
          Container(
            height: MediaQuery.of(context).size.height*.3,
            child: AvatarGlow(
              animate: _isListening,
              glowColor: Theme.of(context).primaryColor,
              endRadius: 75.0,
              duration: const Duration(milliseconds: 2000),
              repeatPauseDuration: const Duration(milliseconds: 100),
              repeat: true,
              child: FloatingActionButton(
                onPressed: _initialized ? _listen : null,
                child: Icon(_isListening ? Icons.mic : Icons.mic_none),
              ),
            )
          ),
        ],
      ),
    );
  }

  void _listen() async {
    if (!_isListening) {
      _speech.listen(
        localeId: _localeName?.localeId,
        onResult: (val) => setState(() {
          _text = val.recognizedWords;
          if (val.hasConfidenceRating && val.confidence > 0) {
            _confidence = val.confidence;
          }
        }),
      );
    } else {
      _speech.stop();
    }
  }

//  final Map<String, HighlightedWord> _highlights = {
//    'flutter': HighlightedWord(
//      onTap: () => print('flutter'),
//      textStyle: const TextStyle(
//        color: Colors.blue,
//        fontWeight: FontWeight.bold,
//      ),
//    ),
//    'voice': HighlightedWord(
//      onTap: () => print('voice'),
//      textStyle: const TextStyle(
//        color: Colors.green,
//        fontWeight: FontWeight.bold,
//      ),
//    ),
//    'subscribe': HighlightedWord(
//      onTap: () => print('subscribe'),
//      textStyle: const TextStyle(
//        color: Colors.red,
//        fontWeight: FontWeight.bold,
//      ),
//    ),
//    'like': HighlightedWord(
//      onTap: () => print('like'),
//      textStyle: const TextStyle(
//        color: Colors.blueAccent,
//        fontWeight: FontWeight.bold,
//      ),
//    ),
//    'comment': HighlightedWord(
//      onTap: () => print('comment'),
//      textStyle: const TextStyle(
//        color: Colors.green,
//        fontWeight: FontWeight.bold,
//      ),
//    ),
//  };

}
