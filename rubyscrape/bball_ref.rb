require 'rubygems'
require 'open-uri'
require 'nokogiri'

def clean_string(input)
input = input.gsub('"', "")
input = input.gsub('<td align=right', "")
input = input.gsub('<td align=left', "")
input = input.gsub('csk=', "")
#input = input.gsub('</a>', "")
#input = input.gsub('</td>', "")
input = input.gsub('"', "")
input = input.gsub('</tr>', "")
#input = input.gsub(' >', "")
input = input.gsub('><', "")

#input = input.gsub('<tr class=>', "")
  return input
end

class Player
  attr_reader :player_url, :name, :mp, :stats

  def initialize(player_url, name, mp, stats)
    @player_url = player_url
    @name = name
    @mp = mp
    @stats = []
  end
end

def parse_to_player_strings(teamblock)
  player_strings = ["hello", "Hi"]
  i = 0
  num = teamblock.count(",")
  puts num
  while i < num do
      a = teamblock.index("html>")+5
      b = teamblock.index("<tr class=")
      if (i = (num-1))
        b = teamblock.index("</tbody>")
      end
      player_string = teamblock[a..b]
      teamblock = teamblock[b+10..teamblock.length]
      player_strings << player_string
      i +=1
  end
  return player_strings
  #end
  #puts player_string
  #puts teamblock
  #return teamblock
end


bballref_url = "http://www.basketball-reference.com/boxscores/201311210DEN.html"

doc = Nokogiri::HTML(open(bballref_url))
s = doc.to_s

team1_basic = s[s.index('Basic Box Score')..s.index('<tfoot>')]
team1_basic = team1_basic[team1_basic.index('csk="')..team1_basic.length]

s = s[s.index(team1_basic)+team1_basic.length..s.length]

team1_advanced = s[s.index('Advanced Box Score')..s.index('<tfoot>')]
team1_advanced = team1_advanced[team1_advanced.index('csk="')..team1_advanced.length]

s = s[s.index(team1_advanced)+team1_advanced.length..s.length]

team2_basic = s[s.index('Basic Box Score')..s.index('<tfoot>')]
team2_basic = team2_basic[team2_basic.index('csk="')..team2_basic.length]

s = s[s.index(team2_basic)+team2_basic.length..s.length]

team2_advanced = s[s.index('Advanced Box Score')..s.index('<tfoot>')]
team2_advanced = team2_advanced[team2_advanced.index('csk="')..team2_advanced.length]

#team1_basic = clean_string(team1_basic)
team2_basic = clean_string(team2_basic)
#team1_advanced = clean_string(team1_advanced)
team2_advanced = clean_string(team2_advanced)

puts parse_to_player_strings(team2_basic).last


