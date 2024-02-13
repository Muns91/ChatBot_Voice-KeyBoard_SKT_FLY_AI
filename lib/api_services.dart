import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';

class ApiServices {
  final _openAI = OpenAI.instance.build(
    token: 'Your Key',
    baseOption: HttpSetup(
      receiveTimeout: const Duration(seconds: 5),
    ),
    enableLog: true,
  );

  List<Map<String, dynamic>> _messagesHistory = [];

  Future<String?> sendMessage(String? message) async {
    _messagesHistory.insert(0, {"role": "user", "content": message});
    final request = ChatCompleteText(
      model: GptTurbo0301ChatModel(),
      messages: _messagesHistory,
      maxToken: 200
    );
    final response = await _openAI.onChatCompletion(request: request);
    for (var element in response!.choices) {
      if (element.message != null) {
        _messagesHistory.insert(0, {"role": "assistant", "content": element.message!.content});
        return element.message!.content;
      }
    }
    return null;
  }
}
