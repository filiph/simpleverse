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

  static final _word = new RegExp(r"\w+");

  List<String> _sentences = [];

  final RegExp _itsSentence =
      new RegExp(r"It('s| is| has| can) .+?[a-z]\.(\s|$)");

  final RegExp _wikiSimpleLink = new RegExp(r"\[\[(.+?)\]\]");

  final RegExp _wikiModifiedLink = new RegExp(r"\[\[(.+?)\|\|.+?\]\]");

  Random random = new Random();

  /// Feed the object with a corpus, line by line.
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
      final buf = new StringBuffer();
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
    final buf = new StringBuffer();

    final firstSentence = _getRandomSentence();
    final lastWord = _word.allMatches(firstSentence).last.group(0);
    final rhymingWords = await _getRhymesForWord(lastWord);

    buf.writeln(firstSentence);
    List<String> secondSentenceCandidates = [];
    for (final word in rhymingWords) {
      final rhymingSentences = _findSentenceByLastWord(word);
      for (final sentence in rhymingSentences) {
        if (sentence != firstSentence) {
          secondSentenceCandidates.add(sentence);
        }
      }
    }
    if (secondSentenceCandidates.isEmpty) {
      // No rhyme could be found for this, try again.
      return _createOneRhyme();
    }
    final secondSentence = secondSentenceCandidates[
        random.nextInt(secondSentenceCandidates.length)];
    return new Rhyme(firstSentence, secondSentence);
  }

  Iterable<String> _findSentenceByLastWord(String word) sync* {
    for (final sentence in _sentences) {
      if (sentence.endsWith("$word.")) {
        yield sentence;
      }
    }
  }

  String _getRandomSentence() => _sentences[random.nextInt(_sentences.length)];

  /// Takes [word] and asynchronously returns a list of words that rhyme
  /// with it.
  ///
  /// Uses https://api.datamuse.com/words.
  Future<List<String>> _getRhymesForWord(String word) async {
    final url = "https://api.datamuse.com/words?rel_rhy=$word";
    final response = await http.get(url);
    final List<Map<String, Object>> json = JSON.decode(response.body);
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
