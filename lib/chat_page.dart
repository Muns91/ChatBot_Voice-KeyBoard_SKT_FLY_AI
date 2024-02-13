import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'chat_model.dart';
import 'api_services.dart';

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  
  List<ChatMessage> _messages = <ChatMessage>[];
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void _startListening() async {
    bool available = await _speech.initialize(
      onError: (val) => print('onError: $val'),
      onStatus: (val) => print('onStatus: $val'),
    );
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (val) => setState(() {
          _textController.text = val.recognizedWords;
        }),
        localeId: 'ko_KR',  // 한국어로 설정
      );
    }
  }

  void _stopListening() {
    if (_isListening) {
      _speech.stop();
      _handleSubmitted(_textController.text);
      _textController.clear();
      setState(() => _isListening = false);
    }
  }

  Future<void> _handleSubmitted(String text) async {
    _textController.clear();

    ChatMessage message = ChatMessage(
      text: text,
      type: ChatMessageType.user,
    );

    setState(() {
      _messages.insert(0, message);
    });

    var response = await ApiServices().sendMessage(text);
    if (response != null) {  // null check
      ChatMessage botMessage = ChatMessage(
        text: response,
        type: ChatMessageType.bot,
      );

      setState(() {
        _messages.insert(0, botMessage);
      });
    }
  }

  Widget _buildTextComposer() {
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).colorScheme.secondary),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(children: <Widget>[
          Flexible(
            child: TextField(
              controller: _textController,
              onSubmitted: _handleSubmitted,
              decoration: InputDecoration.collapsed(hintText: "Send a message"),
              style: TextStyle(fontSize: 24.0),  // 메시지 창의 텍스트 크기를 1.5배 더 크게
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 4.0),
            child: IconButton(
              icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
              iconSize: 36.0,  // 마이크 버튼의 크기를 늘림
              onPressed: _isListening ? _stopListening : _startListening,
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 4.0),
            child: IconButton(
              icon: const Icon(Icons.send),
              iconSize: 36.0,  // 보내기 버튼의 크기를 늘림
              onPressed: () => _handleSubmitted(_textController.text),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chatbot")),
      body: Column(children: <Widget>[
        Flexible(
          child: ListView.builder(
            padding: EdgeInsets.all(8.0),
            reverse: true,
            itemBuilder: (_, int index) => _buildChatMessage(_messages[index]),
            itemCount: _messages.length,
          ),
        ),
        Divider(height: 1.0),
        Container(
          decoration: BoxDecoration(color: Theme.of(context).cardColor),
          child: _buildTextComposer(),
        ),
      ]),
    );
  }

  Widget _buildChatMessage(ChatMessage message) {
    if (message.type == ChatMessageType.bot) {
      return ListTile(
        leading: Icon(Icons.android),
        title: Text("Bot"),
        subtitle: Text(message.text!),
      );
    } else {
      return ListTile(
        trailing: Icon(Icons.person),
        title: Text("User", textAlign: TextAlign.right),
        subtitle: Text(message.text!, textAlign: TextAlign.right),
      );
    }
  }
}
