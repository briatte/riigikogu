This repository contains code to build cosponsorship networks from bills passed in the [Estonian parliament](http://www.riigikogu.ee/).

- [interactive demo](http://f.briatte.org/parlviz/riigikogu)
- [static plots](http://f.briatte.org/parlviz/riigikogu/plots.html)
- [more countries](https://github.com/briatte/parlnet)

# HOWTO

Replicate by running `make.r` in R.

The `data.r` script downloads information on bills and sponsors. Information on sponsors from past legislatures are downloaded as single-page summaries, whereas sponsors from the current legislature have more detailed individual biographies.

The `build.r` script then assembles the edge lists and plots the networks, with the help of a few routines coded into `functions.r`. Adjust the `plot`, `gexf` and `mode` parameters to skip the plots or to change the node placement algorithm.

The networks are very sparse (0.01 < _d_ < 0.02), basically because there are very few nominally cosponsored bills per legislature. It is much more common for bills to be introduced by the executive or by 1+ parliamentary committee than by 1+ nominal sponsors.

# DATA

## Bills

- `legislature` -- legislature number (numeric)
- `session` -- legislature id (text)
- `number` -- legislature number
- `date` -- date of introduction of the bill (dd.mm.yyyy)
- `title` -- bill title
- `url` -- bill URL
- `authors` -- bill sponsors, using their full names
- `links` -- bill sponsors, using their URLs (when available)
- `n_a` -- number of sponsors (from full names)
- `n_l` -- number of sponsors (from URLs)

Note -- given that only sponsors present in legislature 13 (the current one) have a URL, the sponsor information should be derived from their full names rather than from their URLs, except if one is working on legislature 13 alone.

## Sponsors

- `legislature` -- legislature of activity
- `name` -- full name
- `born` -- year of birth (stored as character)
- `party` -- political party (abbreviated)
- `constituency` -- constituency (as number or text; stored as character)
- `nyears` -- seniority (multiple of term length, 4 years)
- `committees` -- semicolon-separated committee memberships
- `photo` -- photo URL (legislature 123 only)
- `sex` -- gender (F/M), imputed from first names

Note -- committees are stored either as full text or as acronyms.
