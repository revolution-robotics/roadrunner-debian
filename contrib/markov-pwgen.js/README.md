# Markov Chain Password Generator

`markov-pwgen` is a JavaScript command-line utility that leverages
the [Foswig.js](https://github.com/mrsharpoblunto/foswig.js/) library
to generate memorable passwords.

## Synopsis

```
Usage: markov-pwgen OPTIONS
OPTIONS (defaults are random within the given range):
  --count=N         Generate N hyphen-delimited passwords (default: 2)
  --order=N         Specify Markov chain order (default: 3 or 4)
  --minLength=N     Minimum password length (default: 3 or 4)
  --maxLength=N     Maximum password length (default: 6 or 7)
  --maxAttempts=N   Fail after N attempts to generate chain (default: 100)
  --allowDuplicates Allow dictionary passwords (default: false)
```

## Installation

Select a plain-text dictionary of words - one per line, say
_/usr/share/dict/web2_, and run:


```
make DICT=/usr/share/dict/web2
sudo make install
```
