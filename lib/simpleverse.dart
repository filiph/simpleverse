import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:english_words/english_words.dart';
import 'package:http/http.dart' as http;

class Rhyme {
  final String first;
  final String second;

  const Rhyme(this.first, this.second);
}

class SimpleVerse {
  static const _shortestSyllables = 3;

  static const _longestSyllables = 24;

  static final _word = RegExp(r"\w+");

  final _sentences = <String>[];

  final _itsSentence = RegExp(r"It('s| is| has| can) .+?[a-z]\.(\s|$)");

  final _wikiSimpleLink = RegExp(r"\[\[(.+?)\]\]");

  final _wikiModifiedLink = RegExp(r"\[\[(.+?)\|\|.+?\]\]");

  final _random = Random();

  /// Feed the object with a corpus, line by line.
  Future<Null> feed(Stream<String> lines) async {
    await for (final line in lines) {
      final matches = _itsSentence.allMatches(line);
      _sentences.addAll(matches.map((m) => m.group(0)));
    }
    for (int i = 0; i < _sentences.length; i++) {
      var s = _sentences[i];
      s = s.replaceAllMapped(_wikiSimpleLink, (m) => m.group(1));
      s = s.replaceAllMapped(_wikiModifiedLink, (m) => m.group(1));
      _sentences[i] = s;
    }

    // Filter ugly and unwanted sentences.
    _sentences.removeWhere((sentence) {
      if (sentence.contains("[")) return true;
      if (sentence.contains("]")) return true;
      if (sentence.contains("{")) return true;
      if (sentence.contains("}")) return true;
      if (sentence.contains("|")) return true;
      if (sentence.contains(";")) return true;
      if (".".allMatches(sentence).length > 1) return true;
      final length = _syllablesInSentence(sentence);
      if (length < _shortestSyllables) return true;
      if (length > _longestSyllables) return true;
      return false;
    });
  }

  /// Generates one little poem.
  Stream<String> generate() async* {
    while (true) {
      final a = await _createOneRhyme();
      final b = await _createOneRhyme();
      final buf = StringBuffer();
      // AABB verse
      buf.writeln(a.first);
      buf.writeln(a.second);
      buf.writeln(b.first);
      buf.writeln(b.second);
      yield buf.toString();
    }
  }

  /// Creates a random rhyme.
  ///
  /// Beware that with a small-enough corpus, this could take too much time
  /// or forever. There is no bail-out.
  Future<Rhyme> _createOneRhyme() async {
    final buf = StringBuffer();

    final firstSentence = _getRandomSentence();
    final lastWord = _word.allMatches(firstSentence).last.group(0);
    final rhymingWords = await _getRhymesForWord(lastWord);

    buf.writeln(firstSentence);
    List<String> candidates = [];
    for (final word in rhymingWords) {
      final rhymingSentences = _findSentenceByLastWord(word);
      for (final sentence in rhymingSentences) {
        if (sentence != firstSentence) {
          candidates.add(sentence);
        }
      }
    }
    if (candidates.isEmpty) {
      // No rhyme could be found for this, try again.
      return _createOneRhyme();
    }
    final secondSentence = candidates[_random.nextInt(candidates.length)];
    return Rhyme(firstSentence, secondSentence);
  }

  Iterable<String> _findSentenceByLastWord(String word) sync* {
    for (final sentence in _sentences) {
      if (sentence.endsWith("$word.")) {
        yield sentence;
      }
    }
  }

  String _getRandomSentence() => _sentences[_random.nextInt(_sentences.length)];

  /// Takes [word] and asynchronously returns a list of words that rhyme
  /// with it.
  ///
  /// Uses https://api.datamuse.com/words.
  Future<List<String>> _getRhymesForWord(String word) async {
    final url = "https://api.datamuse.com/words?rel_rhy=$word";
    final response = await http.get(url);
    final jsonList =
        (json.decode(response.body) as List).cast<Map<String, Object>>();
    final List<String> words = jsonList
        .map((wordJson) => wordJson["word"])
        .cast<String>()
        // No absolute verses, please.
        .where((w) => w != word)
        .toList(growable: false);
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
