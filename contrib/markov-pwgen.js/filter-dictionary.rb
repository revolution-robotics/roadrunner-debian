#!/usr/bin/env ruby
#
# @(#) filter-dictionary
#
# This script randomly selects words matching a regular expression in
# a dictionary.
#
require 'set'
require 'tempfile'

# For lowercase words of 3 to 8 chars, word_max <= 76025
# For words of 3 to 8 chars, word_max <= 87585
# For lowercase words of 3 to 9 chars, word_max <= 104857
# For words of 3 to 9 chars, word_max <= 119965
dict = ARGV[0] || '/usr/share/dict/web2'

regex = /^[A-Za-z]{3,9}$/
words_max = 119965

lines = IO.foreach(dict).select { |line| line[regex] }.map(&:chomp)
# puts "lines.length: #{lines.length}"

words = Set[]
if lines.length <= words_max
  words = lines
else
  Random.srand
  while words.length <= words_max
      words << lines[Random.rand(lines.length)]
  end
end

File.open('dictionary.js', 'w') do |f|
  f.write <<EOF
const dict = {
    "words": [
EOF
  words.sort.each { |w| f.write "        \"#{w}\",\n" }
  f.write <<EOF
    ]
};

export { dict };
EOF
end
