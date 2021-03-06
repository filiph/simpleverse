# simpleverse

#### This program won the 2018 LyriX Competition, part of the [Creative Turing Test](http://bregman.dartmouth.edu/turingtests/competition2018) organized at Dartmouth College.

A simple program that is procedurally generating short poems. Example output:

> It's the reason why I retired.<br>
> It can cause cramps, vomiting, diarrhea, feeling dizzy, nausea, and feeling tired.<br>
> It has 31 days.<br>
> It has many gardens, and also has a maze.<br>

See also `example_output.txt` in this repository for 50 more such poems, unfiltered.

There are two inspirations for this program:

1. Nick Montfort's brilliant submission to NaNoGenMo 2017 called [Hard West Turn](https://github.com/NaNoGenMo/2017/issues/119), a novel partly generated from Wikipedia articles.
2. Joe Brainard's cult 1970 book [I remember](https://www.goodreads.com/book/show/1058074.I_Remember).

The goal is to elicit emotion and meaning by randomly combining unrelated but phonetically similar statements.

The design of the program is itself very simple and straightforward. Take a corpus of text (by default, all articles of the Simple English Wikipedia), search for sentences with a regular expression, filter out unwanted ones (too short, too long, etc.), then find random ones that rhyme (using the excellent [datamuse API](https://www.datamuse.com/api/)) and put four of them in an AABB verse.

## Installation

1. Clone this project.
2. [Install Dart](https://www.dartlang.org/install).
3. In this project's directory, run `pub get`.
4. Download a large corpus of text.

   Simple English Wikipedia is recommended. You can see all its database dumps [here](https://dumps.wikimedia.org/simplewiki/). You probably want the `*-pages-meta-current.xml.bz2` file, which you can then extract.

## How to run

5. In the project's directory, run `dart bin/main.dart path/to/corpus/file.txt`.

By default, the program outputs 50 short poems to standard output before exiting. This will take at least a minute.

You can play around with the settings in `lib/simpleverse.dart` to get very different results.
