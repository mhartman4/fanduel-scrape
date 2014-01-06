require 'rubygems'
require 'open-uri'
require 'nokogiri'
require 'mechanize'
require 'mysql'
require 'dotenv'

Dotenv.load

def manscape(input, a, b, a_plus_minus, b_plus_minus)
  trimmings = input[input.index(a)+a_plus_minus..input.index(b)+b_plus_minus]
  the_rest = input[input.index(b)+b_plus_minus..input.length]
  return [trimmings, the_rest]
end

doc = Nokogiri::HTML(open('https://www.numberfire.com/nba/fantasy/fantasy-basketball-projections'))
s = doc.to_s

puts s

s = manscape(s, 'daily_projections', '}}}; ', 20, 3)[0]
daily_proj = s[0..s.index('"teams"')]
players = s[s.index('"players"')..s.length]
players = players[11..players.length]


player_array = []

player_count = players.scan(/sports_reference_id/).length


while player_count > 0 do
  player_string = players[0..players.index('}')]
    players = players[players.index('}')+2..players.length]
  nf_id = manscape(player_string, '"id":"', '","name', 6, -1)[0].to_i
  temp_name = manscape(player_string, '"name":"', '","slug"', 8, -1)[0]

  if temp_name=="Juan Jose Barea"
    temp_name = "Jose Barea"
  end
  if temp_name=="Jeffery Taylor"
    temp_name = "Jeff Taylor"
  end
  if temp_name=="Glen Rice Jr."
    temp_name = "Glen Rice"
  end
  if temp_name=="Tim Hardaway Jr."
    temp_name = "Tim Hardaway"
  end

  player = {:id => nf_id, :name => temp_name}
  player_array.push(player)
  player_count = player_count-1
end

daily_proj = daily_proj[0..daily_proj.length-4]

db = Mysql.new('127.0.0.1','root',ENV["SQL_PASSWORD"],'fanduel')

proj_count = daily_proj.scan(/nba_player_id/).length
puts proj_count
while proj_count > 0 do
  proj_string = daily_proj[daily_proj.index('{')..daily_proj.index('}')]
  temp_id = manscape(proj_string, 'nba_player_id', '","nba_game_id', 16, -1)[0].to_i
  temp_mp = manscape(proj_string, 'minutes', ',"fgm', 9, -1)[0].to_f
  temp_fdp = manscape(proj_string, 'fanduel_fp', ',"fanduel_salary"', 12, -1)[0].to_f
  plyr_name = player_array.find { |h| h[:id] == temp_id }[:name]
  daily_proj = manscape(daily_proj, '{', '}', 0, 2)[1]
  proj_count = proj_count-1
  sql = "UPDATE oconnor SET numberfire_fdp='#{temp_fdp}', numberfire_mp='#{temp_mp}' WHERE name ='#{plyr_name.gsub("'", %q(\\\'))}' and date='#{Date.today}';"
  db.query sql
end
