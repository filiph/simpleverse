import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:english_words/english_words.dart';
import 'package:http/http.dart' as http;

class SimpleHaiku {
  static const _shortestSyllables = 3;

  static const _longestSyllables = 24;

  static final _word = new RegExp(r"\w+");

  List<String> _sentences = [];

  final RegExp _itsSentence =
      new RegExp(r"It('s| is| has| can) .+?[a-z]\.(\s|$)");

  final RegExp _wikiSimpleLink = new RegExp(r"\[\[(.+?)\]\]");

  final RegExp _wikiModifiedLink = new RegExp(r"\[\[(.+?)\|\|.+?\]\]");

  Random random = new Random();

  Future<Null> feed(Stream<String> lines) async {
    await for (final line in lines) {
      final matches = _itsSentence.allMatches(line);
      _sentences.addAll(matches.map((m) => m.group(0)));
    }
    for (int i = 0; i < _sentences.length; i++) {
      var sentence = _sentences[i];
      sentence = sentence.replaceAllMapped(_wikiSimpleLink, (m) => m.group(1));
      sentence =
          sentence.replaceAllMapped(_wikiModifiedLink, (m) => m.group(1));
      _sentences[i] = sentence;
    }

    _sentences.removeWhere((sentence) {
      if (sentence.contains("[")) return true;
      if (sentence.contains("]")) return true;
      if (sentence.contains("{")) return true;
      if (sentence.contains("}")) return true;
      if (sentence.contains("|")) return true;
      if (sentence.contains(";")) return true;
      final length = _syllablesInSentence(sentence);
      if (length < _shortestSyllables) return true;
      if (length > _longestSyllables) return true;
      return false;
    });
  }

  Stream<String> generate() async* {
    while (true) {
      final a = await _createOneRhyme();
      final b = await _createOneRhyme();
      final buf = new StringBuffer();
      buf.writeln(a.first);
      buf.writeln(b.first);
      buf.writeln(a.second);
      buf.writeln(b.second);
      yield buf.toString();
    }
  }

  Future<Rhyme> _createOneRhyme() async {
    final count = _sentences.length;
    final buf = new StringBuffer();

    final firstSentence = _sentences[random.nextInt(count)];
    final lastWord = _word.allMatches(firstSentence).last.group(0);
    final rhymingWords = await _getRhymesForWord(lastWord);

    buf.writeln(firstSentence);
    String secondSentence;
    for (final word in rhymingWords) {
      final rhymingSentence = _findSentenceByLastWord(word);
      if (rhymingSentence != null) {
        secondSentence = rhymingSentence;
        break;
      }
    }
    if (secondSentence == null) {
      // No rhyme could be found for this, try again.
      return _createOneRhyme();
    }
    return new Rhyme(firstSentence, secondSentence);
  }

  String _findSentenceByLastWord(String word) {
    for (final sentence in _sentences) {
      if (sentence.endsWith("$word.")) {
        return sentence;
      }
    }

    return null;
  }

  /// Get from https://api.datamuse.com/words?rel_rhy=forgetful.
  Future<List<String>> _getRhymesForWord(String lastWord) async {
    final url = "https://api.datamuse.com/words?rel_rhy=$lastWord";
    final response = await http.get(url);
    final List<Map<String,Object>> json = JSON.decode(response.body);
    final List<String> words = json.map((wordJson) => wordJson["word"]);
    return words;
  }

  int _syllablesInSentence(String sentence) {
    int result = 0;
    for (final match in _word.allMatches(sentence)) {
      final word = match.group(0);
      result += syllables(word);
    }
    return result;
  }
}

class Rhyme {
  final String first;
  final String second;

  const Rhyme(this.first, this.second);
}
