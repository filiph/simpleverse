# simpleverse

A simple program that is procedurally generating short poems. Example output:

> It is made up of old volcanic mountains with many nationally recognized streams.
> It's okay, really, everything's fine as it seems.
> It is a station where passenger trains stop on the First ScotRail railway line.
> It has some of the Boeing 707's design.

Similarly:

> It's the reason why I retired.
> It can cause cramps, vomiting, diarrhea, feeling dizzy, nausea, and feeling tired.
> It has 31 days.
> It has many gardens, and also has a maze.

There are two inspirations for this program:

1. Nick Montfort's brilliant submission to NaNoGenMo 2017 called [Hard West Turn](https://github.com/NaNoGenMo/2017/issues/119), a novel partly generated from Wikipedia articles.
2. Joe Brainard's cult 1970 book [I remember](https://www.goodreads.com/book/show/1058074.I_Remember).

The goal is to elicit emotion and meaning by randomly combining unrelated but phonetically similar statements.

The design of the program is itself very simple and straightforward. Take a corpus of text (by default, all articles of the Simple English Wikipedia), search for sentences with a regular expression, filter out unwanted ones (too short, too long, etc.), then find random ones that rhyme (using the excellent [datamuse API](https://www.datamuse.com/api/)) and put four of them in an AABB verse.

## Installation

1. Clone this project.
2. [Install Dart](https://www.dartlang.org/install).
3. Download a large corpus of text.

   Simple English Wikipedia is recommended. You can see all its database dumps [here](https://dumps.wikimedia.org/simplewiki/). You probably want the `*-pages-meta-current.xml.bz2` file, which you can then extract.

## How to run

4. In the project's directory, run `dart bin/main.dart path/to/corpus/file.txt`.

By default, the program outputs 50 short poems to standard output before exiting. This will take at least a minute.

You can play around with the settings in `lib/simpleverse.dart` to get very different results.
