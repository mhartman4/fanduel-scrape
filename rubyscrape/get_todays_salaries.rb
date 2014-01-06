require 'rubygems'
require 'open-uri'
require 'nokogiri'
require 'CSV'
require 'mechanize'
require 'mysql'
require 'dotenv'

Dotenv.load

agent = Mechanize.new
page = agent.get('http://fanduel.com/league/daily_nba_freeroll')
fanduel_url = page.uri.to_s

class Player
  attr_reader :player_id, :position, :name, :team, :opp, :salary, :fppg, :games_played, :yahoo_url

    def initialize(player_id, position, name, team, opp, salary, fppg, games_played, yahoo_url)
      @player_id = player_id
      @position = position
      @name = name
      @team = team
      @opp = opp
      @salary = salary
      @fppg = fppg
      @games_played = games_played
      @yahoo_url = yahoo_url
    end
end

#get the big block of player data at the top
doc = Nokogiri::HTML(open(fanduel_url))
s = doc.to_s

#create an array of all fanduel teamIDs and teams
team_array = []
team_array.push({:id => 708, :team => "WAS"}, {:id => 700, :team => "ORL"}, {:id => 682, :team => "CHI"}, {:id => 697, :team => "NOP"}, {:id => 705, :team => "SAS"}, {:id => 679, :team => "ATL"}, {:id => 707, :team => "UTA"}, {:id => 688, :team => "HOU"}, {:id => 703, :team => "POR"}, {:id => 689, :team => "IND"})
team_array.push({:id => 680, :team => "BOS"}, {:id => 696, :team => "BRK"}, {:id => 681, :team => "CHA"}, {:id => 683, :team => "CLE"}, {:id => 684, :team => "DAL"}, {:id => 685, :team => "DEN"}, {:id => 686, :team => "DET"}, {:id => 687, :team => "GSW"}, {:id => 692, :team => "MEM"}, {:id => 693, :team => "MIA"}, {:id => 694, :team => "MIL"}, {:id => 699, :team => "OKC"}, {:id => 701, :team => "PHI"}, {:id => 702, :team => "PHO"}, {:id => 704, :team => "SAC"}, {:id => 706, :team => "TOR"})
team_array.push({:id => 679, :team => "ATL"}, {:id => 690, :team => "LAC"}, {:id => 695, :team => "MIN"})
team_array.push({:id => 698, :team => "NYK"}, {:id => 691, :team => "LAL"})

#get the fixture info
fixture_block = s[s.index('FixtureCompactString')+24..s.index('FD.playerpicker.positions')-7]
fixture_block << ","
fixture_array = []
fixture_count = fixture_block.count('@')/2
while fixture_count > 0 do
  fixture_string = fixture_block[0..fixture_block.index(',')-1]
  fixture_block = fixture_block[fixture_block.index(',')+1..fixture_block.length]
  fixture_string << "-"
  fixture_string << fixture_block[0..fixture_block.index(',')-1]
  fixture_block = fixture_block[fixture_block.index(',')+1..fixture_block.length]

  home_id = fixture_string.scan(/\d+/).first.to_i
  away_id = fixture_string.scan(/\d+/).last.to_i
  fixture_array.push({:home_id => home_id, :away_id => away_id})

  fixture_count -=1

  #puts fixture_string
end

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
    if temp_name == "Tim Hardaway Jr."
      temp_name = "Tim Hardaway"
    end
    if temp_name == "Giannis Adetokunbo"
      temp_name = "Giannis Antetokounmpo"
    end
  player_string = player_string[player_string.index(',')+1..player_string.length-1]

  #skip
  player_string = player_string[player_string.index(',')+1..player_string.length-1]

  temp_team_id = player_string[0..player_string.index(',')-1].to_i
  temp_team_name = team_array.find { |h| h[:id] == temp_team_id }[:team]
  temp_opp_name = ""

  fixture_array.each do |fixture|
    if fixture.has_value?(temp_team_id)
      spot = fixture.key(temp_team_id)
      if spot == :away_id
        temp_opp_id = fixture[:home_id]
        temp_opp_name = team_array.find { |h| h[:id] == temp_opp_id }[:team]
      end
      if spot == :home_id
        temp_opp_id = fixture[:away_id]
        temp_opp_name = team_array.find { |h| h[:id] == temp_opp_id }[:team]
      end
    end
  end

  player_string = player_string[player_string.index(',')+1..player_string.length-1]

  #skip
  player_string = player_string[player_string.index(',')+1..player_string.length-1]

  temp_salary = player_string[0..player_string.index(',')-1].to_i
  player_string = player_string[player_string.index(',')+1..player_string.length-1]

  temp_fppg = player_string[0..player_string.index(',')-1]
  player_string = player_string[player_string.index(',')+1..player_string.length-1]

  temp_games_played = player_string[0..player_string.index(',')-1]
  player_string = player_string[player_string.index(',')+1..player_string.length-1]

  temp_yahoo_url = player_string[0..player_string.index(',')-1]
  player_string = player_string[player_string.index(',')+1..player_string.length-1]

  temp_player = Player.new(temp_id, temp_position, temp_name, temp_team_name, temp_opp_name, temp_salary, temp_fppg, temp_games_played, temp_yahoo_url)
  players << temp_player
  i +=1
end

#find when the contest is starting
countdown = s[s.index("Countdown.make")..s.index("Countdown.make")+50]
countdown = countdown.gsub(/[^0-9]/, '').to_i
days_til_start = countdown/86400

#put together sql statement
sqls = []
sql = ""
names = "("

#get todays players names, create query, and append to query array
players.each do |player|
  t_name = player.name.gsub("'", %q(\\\'))
  t_date_name = "#{Date.today+days_til_start}"
  t_date_name = t_date_name.gsub("-", "")
  t_name2 = t_name.gsub(" ", "")
  t_name2 = t_name2.downcase
  t_date_name << t_name2
  names << "'#{t_name}', "
  beginning = "REPLACE INTO `oconnor` (date_name, date, fanduel_id, salary, position, name, team, opp) VALUES ("
  beginning << "'#{t_date_name}', '#{Date.today+days_til_start}', '#{player.player_id}', '#{player.salary}', '#{player.position}', '#{player.name.gsub("'", %q(\\\'))}', '#{player.team}', '#{player.opp}');"
  #puts beginning
  sqls << beginning
end
names = names[0..names.length-3] << ")"

db = Mysql.new('127.0.0.1','root',ENV["SQL_PASSWORD"],'fanduel')
sqls.each do |sql|
  db.query sql
end


