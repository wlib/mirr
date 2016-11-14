# Mirr - Because you like synchronization

## What's this?

Mirr synchronizes directories of things for you, so you can 
work on the same thing, on different computers in your home.

## Installation

Almost as simple as mirr itself:

+ `sudo gem install mirr` Download & install via RubyGems

## Usage

mirr add myfolder      :   Add 'myfolder' to sync list

mirr del somefile      :   Remove 'somefile' from sync list

mirr set time 10am     :   Set mirr to sync at 10 am everyday

mirr set every 02:45   :   Set mirr to sync every 2 hours, 45 minutes

mirr pull              :   Pull everything right now

mirr push work.rb      :   Push only 'work.rb', nothing else changes

## Contribute

New features are hard to think up by myself:

1. [Fork the project](https://github.com/wlib/mirr/fork)
2. Create your feature branch `git checkout -b my-new-feature`
3. Commit your changes `git commit -am 'I added an awesome feature'`
4. Push to the branch `git push origin my-new-feature`
5. Create a new Pull Request on github

+ [Daniel Ethridge](https://wlib.github.io) - author
+ [You](https://yourwebsite.com) - helped add...