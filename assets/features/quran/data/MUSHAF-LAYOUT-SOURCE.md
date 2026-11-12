# Madinah Mushaf line layout

The bundled `madinah-v2-line-layout.json` contains page, line, and word-location
metadata for the 604-page KFGQPC Madinah Mushaf V2 (1421H). It does not contain
Quran verse text. The reader obtains every displayed Quran character from the
existing `quran-uthmani-hafs.txt` file.

Layout source: [KFGQPC Madinah Mushaf rendering kit](https://github.com/manaf/KFGQPC-Madinah-Mushaf),
which attributes the layout and word-location data to the Quranic Universal
Library (QUL): <https://qul.tarteel.ai/>. The upstream project identifies the
edition as Hafs `an Asim, 15 lines per page, and attributes its Mushaf data to
the King Fahd Glorious Quran Printing Complex (KFGQPC).

The layout JSON is a compact derivative containing only line type, centering,
surah headers, and word locations (`surah:ayah:word`). Its upstream data terms
and attribution apply. The QPC glyph fonts and Quran text from that upstream
project are not bundled or used by this app.
