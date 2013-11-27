require 'rubygems'
require 'open-uri'
require 'nokogiri'
require 'CSV'
require 'mechanize'

#get the right url
agent = Mechanize.new
page = agent.get('http://fanduel.com/league/daily_nba_freeroll')
fanduel_url = page.uri.to_s

class Player
  attr_reader :player_id, :position, :name, :salary, :fppg, :games_played, :yahoo_url

    def initialize(player_id, position, name, salary, fppg, games_played, yahoo_url)
      @player_id = player_id
      @position = position
      @name = name
      @salary = salary
      @fppg = fppg
      @games_played = games_played
      @yahoo_url = yahoo_url
    end
end

#get the big block of player data at the top
doc = Nokogiri::HTML(open(fanduel_url))
s = doc.to_s
a = s.index('FD.playerpicker.allPlayersFullData')+37
b =  s.index('FD.playerpicker.teamIdToFixtureCompactString')-6
excerpt = s[a..b]
players = []

#get player info
num = excerpt.count('[')
i = 0
while i < num do
  c = excerpt.index('[')
  d = excerpt.index(']')
  player_string = excerpt[1..d]
  excerpt = excerpt[d+1..excerpt.length-1]
  player_string = player_string.delete('"')
  player_string = player_string.delete('[')
  player_string = player_string.delete(']')

  temp_id = player_string[0..player_string.index(':')-1].to_i
  player_string = player_string[player_string.index(':')+1..player_string.length-1]

  temp_position = player_string[0..player_string.index(',')-1]
  player_string = player_string[player_string.index(',')+1..player_string.length-1]

  temp_name = player_string[0..player_string.index(',')-1]
    if temp_name == "Phil (Flip) Pressey"
      temp_name = "Phil Pressey"
    end
    if temp_name == "Brad Beal"
      temp_name = "Bradley Beal"
    end
    if temp_name == "Glen Rice Jr."
      temp_name = "Glen Rice"
    end
    if temp_name == "Jose Juan Barea"
      temp_name = "Jose Barea"
    end
    if temp_name == "Jeffery Taylor"
      temp_name = "Jeff Taylor"
    end
  player_string = player_string[player_string.index(',')+1..player_string.length-1]

  player_string = player_string[player_string.index(',')+1..player_string.length-1]
  player_string = player_string[player_string.index(',')+1..player_string.length-1]
  player_string = player_string[player_string.index(',')+1..player_string.length-1]

  temp_salary = player_string[0..player_string.index(',')-1].to_i
  player_string = player_string[player_string.index(',')+1..player_string.length-1]

  temp_fppg = player_string[0..player_string.index(',')-1]
  player_string = player_string[player_string.index(',')+1..player_string.length-1]

  temp_games_played = player_string[0..player_string.index(',')-1]
  player_string = player_string[player_string.index(',')+1..player_string.length-1]

  temp_yahoo_url = player_string[0..player_string.index(',')-1]
  player_string = player_string[player_string.index(',')+1..player_string.length-1]

  temp_player = Player.new(temp_id, temp_position, temp_name, temp_salary, temp_fppg, temp_games_played, temp_yahoo_url)
  players << temp_player
  i +=1
end

#find when the contest is starting
countdown = s[s.index("Countdown.make")..s.index("Countdown.make")+50]
countdown = countdown.gsub(/[^0-9]/, '').to_i
days_til_start = countdown/86400

#put together sql statement
beginning = "REPLACE INTO `oconnor` (date_name, date, fanduel_id, salary, position, name) VALUES ("
sql = ""
players.each do |player|
  t_name = player.name.gsub("'", %q(\\\'))
  t_date_name = "#{Date.today+days_til_start}"
  t_date_name = t_date_name.gsub("-", "")
  t_name2 = t_name.gsub(" ", "")
  t_name2 = t_name2.downcase
  t_date_name << t_name2
  beginning << "'#{t_date_name}', '#{Date.today+days_til_start}', '#{player.player_id}', '#{player.salary}', '#{player.position}', '#{player.name.gsub("'", %q(\\\'))}');"
  sql << beginning
  sql << "\n"
  beginning = "REPLACE INTO `oconnor` (date_name, date, fanduel_id, salary, position, name) VALUES ("
end
puts sql



