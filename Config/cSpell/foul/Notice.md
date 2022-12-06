
# Dictionary modifications

The foul words dictionary `foul.dic` was obtained from [borealisdata.ca][link] (file version 1.1)
under the terms described in the `LICENSE` file in this directory.

As required by the license, the following modification to the original dictionary were made:

- Removed all words that are not single words
- Removed all spaces and numbers
- Removed all duplicate words
- Added `!` exclamation mark to the begining of each word in order to make them work for `cSpell`
VSCode extension to flag those words as forbidden.
- The original file was renamed to `foul.dic`

[link]: https://borealisdata.ca/dataset.xhtml?persistentId=doi:10.5683/SP/J59UUG "Visit borealisdata.ca"
