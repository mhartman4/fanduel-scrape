require 'rubygems'
require 'open-uri'
require 'nokogiri'
require 'CSV'
require 'mechanize'
require 'mysql'
require 'dotenv'
require 'date'
require 'tiny_tds'
require 'active_support/all'

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

puts "Salaries added from fanduel"
#END OF FANDUEL, START ROTOWIRE

def manscape(input, a, b, a_plus_minus, b_plus_minus)
  trimmings = input[input.index(a)+a_plus_minus..input.index(b)+b_plus_minus]
  the_rest = input[input.index(b)+b_plus_minus..input.length]
  return [trimmings, the_rest]
end

agent = Mechanize.new
page = agent.get('http://www.rotowire.com/basketball/daily_projections.htm')
#login_form =

login_form = page.forms.first
#login_form.fields[:value] = 'jettaubrey'

login_form.fields[0].value = ENV["ROTOWIRE_UN"]
login_form.fields[1].value = ENV["ROTOWIRE_PW"]

page = agent.submit(login_form, login_form.buttons.first)
s = page.body

s = manscape(s, '<body>', 'firstleft', 0, 9)[1]
s = manscape(s, 'a', 'firstleft', 0, 9)[1]
s = manscape(s, 'a', '<td class="firstleft"', 0, 0)[1]
s = manscape(s, '<td class="firstleft"', '</tbody>', 0, 0)[0]
player_count = s.scan(/class/).length

db = Mysql.new('127.0.0.1','root',ENV["SQL_PASSWORD"],'fanduel')

while player_count > 0 do
  player_string = manscape(s, 'firstleft', '</tr>', 11, 0)[0]
  namestring = manscape(player_string, '">', '</a>', 2,-1)[0]
  player_string = manscape(player_string, '">', '</a>', 2,10)[1]
  s = manscape(s, 'firstleft', '</tr>', 10, 7)[1]

  first_name =namestring[namestring.index(';')+1..namestring.length]
  last_name = namestring[0..namestring.index(',')-1]
  temp_name = "#{first_name} #{last_name}"
    if temp_name =="J.J. Barea"
      temp_name = "Jose Barea"
    end
    if temp_name == "Jeffery Taylor"
      temp_name = "Jeff Taylor"
    end

  temp_team = manscape(player_string, '>', '</td>', 1, -1)[0]
    player_string = manscape(player_string, '>', '</td>', 1, 6)[1]
  temp_opp = manscape(player_string, '>', '</td>', 1, -1)[0]
    player_string = manscape(player_string, '>', '</td>', 1, 6)[1]
  temp_mp = manscape(player_string, '>', '</td>', 1, -1)[0].to_f
    player_string = manscape(player_string, '>', '</td>', 1, 6)[1]
  temp_pts = manscape(player_string, '>', '</td>', 1, -1)[0].to_f
    player_string = manscape(player_string, '>', '</td>', 1, 6)[1]
  temp_trb = manscape(player_string, '>', '</td>', 1, -1)[0].to_f
    player_string = manscape(player_string, '>', '</td>', 1, 6)[1]
  temp_ast = manscape(player_string, '>', '</td>', 1, -1)[0].to_f
    player_string = manscape(player_string, '>', '</td>', 1, 6)[1]
  temp_stl = manscape(player_string, '>', '</td>', 1, -1)[0].to_f
    player_string = manscape(player_string, '>', '</td>', 1, 6)[1]
  temp_blk = manscape(player_string, '>', '</td>', 1, -1)[0].to_f
    player_string = manscape(player_string, '>', '</td>', 1, 6)[1]
  temp_threep = manscape(player_string, '>', '</td>', 1, -1)[0].to_f
    player_string = manscape(player_string, '>', '</td>', 1, 6)[1]
  temp_fg_perc = manscape(player_string, '>', '</td>', 1, -1)[0].to_f
    player_string = manscape(player_string, '>', '</td>', 1, 6)[1]
  temp_ft_perc = manscape(player_string, '>', '</td>', 1, -1)[0].to_f
    player_string = manscape(player_string, '>', '</td>', 1, 6)[1]
  temp_tov = manscape(player_string, '>', '</td>', 1, -1)[0].to_f
    player_string = manscape(player_string, '>', '</td>', 1, 6)[1]

  temp_fdp = (temp_pts+(temp_trb*1.2)+(temp_ast*1.5)+(temp_blk*2)+(temp_stl*2)-temp_tov)

  player_count=player_count-1

  sql = "UPDATE `oconnor` SET `rotowire_fdp`='#{temp_fdp}', `rotowire_mp`='#{temp_mp}' WHERE `date` = '#{Date.today}' AND `name` = '#{temp_name.gsub("'", %q(\\\'))}';"

  db.query sql
end

puts "Projections added from Rotowire"

#END ROTOWIRE, START OF NUMBERFIRE

doc = Nokogiri::HTML(open('https://www.numberfire.com/nba/fantasy/fantasy-basketball-projections'))
s = doc.to_s


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
#puts proj_count
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

puts "Projections added from Numberfire"
#END OF NUMBER FIRE, START OF BBALL MONSTER
=begin
def remove_categories(input)
  category_length = 515
  input = manscape(input, "<tr class='gridHeaderTR", '<tr onmouseover', 0, 0)[1]
  first_part = input[0..input.index("<tr class='gridHeaderTR")-1]
  second_part = input[input.index("<tr class='gridHeaderTR")+category_length..input.length]
  first_part << second_part
  return first_part
end

agent = Mechanize.new
page = agent.get('https://basketballmonster.com/login.aspx')

login_form = page.forms.first
login_form.field_with(:name => "ctl00$ContentPlaceHolder1$UsernameTextBox").value = ENV["BBALLMONSTER_UN"]
login_form.field_with(:name => "ctl00$ContentPlaceHolder1$PasswordTextBox").value = ENV["BBALLMONSTER_PW"]

page = agent.submit(login_form, login_form.button_with(:name => "ctl00$ContentPlaceHolder1$LoginButton"))

page = agent.page.link_with(:text => "Daily Projections").click

page = agent.submit(page.forms.first, page.forms.first.button_with(:name => "ctl00$ContentPlaceHolder1$RefreshButton"))

s = page.body
s = manscape(s, "<p class='medP'>", '<div class="copyright">', 0, 0)[0]
s = manscape(s, '<p', '<tr', 0, 0)[1]

s = manscape(s, "<tr class='gridHeaderTR", '<tr onmouseover', 0, 0)[1]

while s.scan(/gridHeaderTR/).count>0 do
  s = remove_categories(s)
end

num_players = s.scan(/onmouseover/).count

player_strings = []

#puts num_players
while num_players > 0 do
  temp_p_string = manscape(s, '<tr onmouseover', '</td></tr>', 0, 9)[0]
  s = manscape(s, '<tr onmouseover', '</td></tr>', 0, 10)[1]
  player_strings.push(temp_p_string)
  num_players-=1
end

db = Mysql.new('127.0.0.1','root',ENV["SQL_PASSWORD"],'fanduel')

player_strings.each do |player_string|
  #player_string = player_strings[77]
  player_string = manscape(player_string, '<td', '</td>', 0, 5)[1]
  player_string = manscape(player_string, '<td', '</td>', 0, 5)[1]
  t_fdp = manscape(player_string, '>', '</td', 1, -1)[0].to_f
  player_string = manscape(player_string, '<', '<td  nowrap', 7, 38)[1]

  t_name = manscape(player_string, "'>", '</a>', 2, -1)[0]
  last_name = t_name[0..t_name.index(',')-1]
  first_name = t_name[t_name.index(',')+2..t_name.length]

  if first_name.length==2
    first_letter = first_name[0..0]
    second_letter = first_name[1..1]
    first_name = "#{first_letter}.#{second_letter}."
  end

  t_name = "#{first_name} #{last_name}"

  if t_name == "J.J. Barea"
    t_name = "Jose Barea"
  end
  if t_name == "Jeffery Taylor"
    t_name = "Jeff Taylor"
  end
  if t_name == "Glen Rice Jr"
    t_name = "Glen Rice"
  end
  if t_name == "Tim Hardaway Jr"
    t_name = "Tim Hardaway"
  end
  if t_name == "Otto Porter Jr"
    t_name = "Otto Porter"
  end
  if t_name == "Amare Stoudemire"
    t_name = "Amar'e Stoudemire"
  end
  if t_name == "Toure Murry"
    t_name = "Toure' Murry"
  end
  if t_name == "Jermaine O'neal"
    t_name = "Jermaine O'Neal"
  end
  if t_name == "Hamady N'diaye"
    t_name = "Hamady N'Diaye"
  end
  if t_name == "Luc Mbah a Moute"
    t_name = "Luc Richard Mbah a Moute"
  end

  #skip over these table columns
  player_string = manscape(player_string, "'>", '</td>', 9, 5)[1]
  player_string = manscape(player_string, '<td', '</td>', 0, 5)[1]
  player_string = manscape(player_string, '<td', '</td>', 0, 5)[1]
  player_string = manscape(player_string, '<td', '</td>', 0, 5)[1]
  player_string = manscape(player_string, '<td', '</td>', 0, 5)[1]
  player_string = manscape(player_string, '<td', '</td>', 0, 5)[1]
  player_string = manscape(player_string, '<td', '</td>', 0, 5)[1]
  player_string = manscape(player_string, '<td', '</td>', 0, 5)[1]

  t_ease = manscape(player_string, ">", '</td>', 1, -1)[0].to_f

  sql = "UPDATE `oconnor` SET `monster_fdp`='#{t_fdp}', `monster_ease`='#{t_ease}' WHERE `date` = '#{Date.today}' AND `name` = '#{Mysql.escape_string(t_name)}';"

  db.query(sql)
end

puts "Projections added from Basketball Monster"

#END OF MONSTER, START OF VEGAS
=end

db = Mysql.new('127.0.0.1','root',ENV["SQL_PASSWORD"],'fanduel')

doc = Nokogiri::HTML(open('http://www.vegasinsider.com/nba/scoreboard/'))
s = doc.to_s

s = manscape(s, '<div class="SLTables4">', '<span class="a1"', 0, 0)[0]
num_fixtures = s.scan(/a> @/).count

fixture_block = s

while num_fixtures > 0 do

  fixture = manscape(fixture_block, '<b><a class="black"', 'url(/graphics/component_shadow2.gif)', 0, 0)[0]
  fixture = manscape(fixture, 'width="100%" nowrap>', '<td align="center" nowrap class="sportPicksBorderL">', 0, 0)[0]

  away_slug = manscape(fixture, '">', '</a>', 2, -1)[0]
        if away_slug == "NOR"
          away_slug = "NOP"
        end
        if away_slug == "UTH"
          away_slug = "UTA"
        end
        if away_slug == "BKN"
          away_slug = "BRK"
        end

  top_element = manscape(fixture, '"middle" nowrap>', '<td align="center"', 17, -8)[0]
  if top_element == "PK"
    top_element = 0.0
  end

  top_element = top_element.to_f


  fixture = manscape(fixture, '">', '</a>', 2, 0)[1]
  fixture = manscape(fixture, '">', '.cfm', 2, 0)[1]


  home_slug = manscape(fixture, '">', '</td>', 2, -11)[0]
        if home_slug == "NOR"
          home_slug = "NOP"
        end
        if home_slug == "UTH"
          home_slug = "UTA"
        end
        if home_slug == "BKN"
          home_slug = "BRK"
        end


  fixture = manscape(fixture, '">', '</td>', 2, 6)[1]

  bottom_element = manscape(fixture, 'align="middle">', '</td>', 16, -2)[0]

  if bottom_element == "PK"
    bottom_element = 0.0
    #puts "hello"
  end

  bottom_element = bottom_element.to_f

  elements = [top_element, bottom_element]
  elements.sort! {|a,b| a <=> b}


  spread = elements.first.abs
  o_u = elements.last

    if num_fixtures > 1
      fixture_block = manscape(fixture_block, '<b><a class="black"', 'url(/graphics/component_shadow2.gif)', 0, 0)[1]
      fixture_block = manscape(fixture_block, '/', '<b><a class="black"', 0, 0)[1]
    end
  sql = "UPDATE oconnor SET over_under = '#{o_u}', spread='#{spread}' where date = '#{Date.today}' and (team = '#{home_slug}' OR team = '#{away_slug}');"
  db.query(sql)
  num_fixtures-=1
end
puts "O/Us and spreads added from Vegas Insider"
#END OF VEGAS

class Player2
  attr_reader :name, :mp, :stats

  def initialize(name, mp, stats)
    @name = name
    @mp = mp
    @stats = stats
  end
end



def remove_categories2(input)
  input = input[input.index('<tbody>')..input.index('</tbody>')]
  a = input.index('<tr class="no_ranker thead">')
  b = input.index('</th>
</tr>')
  input = input[0..a] << input[b+7..input.length]
  fuckyou = input.index('</tr>
</tr>')
  input = input[0..fuckyou] << input[fuckyou+7..input.length]
  return input
  end

def extract_info_basic(input)
  num = input.count(',')
  player_strings = []
  #puts num
  while num>0 do
    player_string = manscape(input, '<tr class="">', '</tr>', 0, 4)[0]
    input = manscape(input, '<tr class="">', '</tr>', 0, 6)[1]
    player_strings << player_string

    num-=1
  end

  basic_players = []

  player_strings.each do |plyr|
    #inside the playerstring loop!

    stats = {}

    name = manscape(plyr, '.html">', '</a>', 7, -1)[0]
    plyr = manscape(plyr, '.html">', '</td>', 7, 6)[1]
    plyr = manscape(plyr, '<td', 'csk="', 0, 5)[1]

    mp = plyr[0..plyr.index('"')-1]
    plyr = manscape(plyr, mp, '</td>',0, 7)[1]
    mp = mp.to_f/60

    fg = manscape(plyr, '"right">', '</td>', 8, -1)[0].to_f
    stats.merge! :fg => fg
    plyr = manscape(plyr, '"right">', '</td>', 8, 6)[1]

    fga = manscape(plyr, '"right">', '</td>', 8, -1)[0].to_f
    stats.merge! :fga => fga
    plyr = manscape(plyr, '"right">', '</td>', 8, 6)[1]

    fg_perc = manscape(plyr, '"right">', '</td>', 8, -1)[0].to_f
    stats.merge! :fg_perc => fg_perc
    plyr = manscape(plyr, '"right">', '</td>', 8, 6)[1]

    threep = manscape(plyr, '"right">', '</td>', 8, -1)[0].to_f
    stats.merge! :threep => threep
    plyr = manscape(plyr, '"right">', '</td>', 8, 6)[1]

    threepa = manscape(plyr, '"right">', '</td>', 8, -1)[0].to_f
    stats.merge! :threepa => threepa
    plyr = manscape(plyr, '"right">', '</td>', 8, 6)[1]

    threep_perc = manscape(plyr, '"right">', '</td>', 8, -1)[0].to_f
    stats.merge! :threep_perc => threep_perc
    plyr = manscape(plyr, '"right">', '</td>', 8, 6)[1]

    ft = manscape(plyr, '"right">', '</td>', 8, -1)[0].to_f
    stats.merge! :ft => ft
    plyr = manscape(plyr, '"right">', '</td>', 8, 6)[1]

    fta = manscape(plyr, '"right">', '</td>', 8, -1)[0].to_f
    stats.merge! :fta => fta
    plyr = manscape(plyr, '"right">', '</td>', 8, 6)[1]

    ft_perc = manscape(plyr, '"right">', '</td>', 8, -1)[0].to_f
    stats.merge! :ft_perc => ft_perc
    plyr = manscape(plyr, '"right">', '</td>', 8, 6)[1]

    orb = manscape(plyr, '"right">', '</td>', 8, -1)[0].to_f
    stats.merge! :orb => orb
    plyr = manscape(plyr, '"right">', '</td>', 8, 6)[1]

    drb = manscape(plyr, '"right">', '</td>', 8, -1)[0].to_f
    stats.merge! :drb => drb
    plyr = manscape(plyr, '"right">', '</td>', 8, 6)[1]

    trb = manscape(plyr, '"right">', '</td>', 8, -1)[0].to_f
    stats.merge! :trb => trb
    plyr = manscape(plyr, '"right">', '</td>', 8, 6)[1]

    ast = manscape(plyr, '"right">', '</td>', 8, -1)[0].to_f
    stats.merge! :ast => ast
    plyr = manscape(plyr, '"right">', '</td>', 8, 6)[1]

    stl = manscape(plyr, '"right">', '</td>', 8, -1)[0].to_f
    stats.merge! :stl => stl
    plyr = manscape(plyr, '"right">', '</td>', 8, 6)[1]

    blk = manscape(plyr, '"right">', '</td>', 8, -1)[0].to_f
    stats.merge! :blk => blk
    plyr = manscape(plyr, '"right">', '</td>', 8, 6)[1]

    tov = manscape(plyr, '"right">', '</td>', 8, -1)[0].to_f
    stats.merge! :tov => tov
    plyr = manscape(plyr, '"right">', '</td>', 8, 6)[1]

    pf = manscape(plyr, '"right">', '</td>', 8, -1)[0].to_f
    stats.merge! :pf => pf
    plyr = manscape(plyr, '"right">', '</td>', 8, 6)[1]

    pts = manscape(plyr, '"right">', '</td>', 8, -1)[0].to_f
    stats.merge! :pts => pts
    plyr = manscape(plyr, '"right">', '</td>', 8, 6)[1]

    plyr_obj = Player2.new(name, mp, stats)
    basic_players << plyr_obj
  end
  return basic_players
end

def extract_info_advanced(input)
  num = input.count(',')
  player_strings = []
  #puts num
  while num>0 do
    player_string = manscape(input, '<tr class="">', '</tr>', 0, 4)[0]
    input = manscape(input, '<tr class="">', '</tr>', 0, 6)[1]
    player_strings << player_string
    num-=1
  end

  adv_players = []

  player_strings.each do |plyr|
    #inside the playerstring loop!

    stats = {}

    name = manscape(plyr, '.html">', '</a>', 7, -1)[0]
    plyr = manscape(plyr, '.html">', '</td>', 7, 6)[1]
    plyr = manscape(plyr, '<td', 'csk="', 0, 5)[1]

    mp = plyr[0..plyr.index('"')-1]
    plyr = manscape(plyr, mp, '</td>',0, 7)[1]
    mp = mp.to_f

    ts_perc = manscape(plyr, '"right">', '</td>', 8, -1)[0].to_f
    stats.merge! :ts_perc => ts_perc
    plyr = manscape(plyr, '"right">', '</td>', 8, 6)[1]

    efg_perc = manscape(plyr, '"right">', '</td>', 8, -1)[0].to_f
    stats.merge! :efg_perc => efg_perc
    plyr = manscape(plyr, '"right">', '</td>', 8, 6)[1]

    orb_perc = manscape(plyr, '"right">', '</td>', 8, -1)[0].to_f
    stats.merge! :orb_perc => orb_perc
    plyr = manscape(plyr, '"right">', '</td>', 8, 6)[1]

    drb_perc = manscape(plyr, '"right">', '</td>', 8, -1)[0].to_f
    stats.merge! :drb_perc => drb_perc
    plyr = manscape(plyr, '"right">', '</td>', 8, 6)[1]

    trb_perc = manscape(plyr, '"right">', '</td>', 8, -1)[0].to_f
    stats.merge! :trb_perc => trb_perc
    plyr = manscape(plyr, '"right">', '</td>', 8, 6)[1]

    ast_perc = manscape(plyr, '"right">', '</td>', 8, -1)[0].to_f
    stats.merge! :ast_perc => ast_perc
    plyr = manscape(plyr, '"right">', '</td>', 8, 6)[1]

    stl_perc = manscape(plyr, '"right">', '</td>', 8, -1)[0].to_f
    stats.merge! :stl_perc => stl_perc
    plyr = manscape(plyr, '"right">', '</td>', 8, 6)[1]

    blk_perc = manscape(plyr, '"right">', '</td>', 8, -1)[0].to_f
    stats.merge! :blk_perc => blk_perc
    plyr = manscape(plyr, '"right">', '</td>', 8, 6)[1]

    tov_perc = manscape(plyr, '"right">', '</td>', 8, -1)[0].to_f
    stats.merge! :tov_perc => tov_perc
    plyr = manscape(plyr, '"right">', '</td>', 8, 6)[1]

    usg_perc = manscape(plyr, '"right">', '</td>', 8, -1)[0].to_f
    stats.merge! :usg_perc => usg_perc
    plyr = manscape(plyr, '"right">', '</td>', 8, 6)[1]

    o_rtg = manscape(plyr, '"right">', '</td>', 8, -1)[0].to_f
    stats.merge! :o_rtg => o_rtg
    plyr = manscape(plyr, '"right">', '</td>', 8, 6)[1]

    d_rtg = manscape(plyr, '"right">', '</td>', 8, -1)[0].to_f
    stats.merge! :d_rtg => d_rtg
    plyr = manscape(plyr, '"right">', '</td>', 8, 6)[1]

    plyr_obj = Player2.new(name, mp, stats)
    adv_players << plyr_obj
  end
  return adv_players
end

initial_url = "http://www.basketball-reference.com/leagues/NBA_2014_games.html"
doc = Nokogiri::HTML(open(initial_url))
s = doc.to_s

#get all of yesterday's box score urls
num = s.scan(/>Box Score</).count
urls = []

while num > 0 do
 needle = manscape(s, '">Box Score', '">Box Score', -17, -1)[0]
  s = manscape(s, '">Box Score', '">Box Score', 0, 20)[1]
  s = manscape(s, '</tr>', '</tr>', 0, 20)[1]
  needle = "http://www.basketball-reference.com/boxscores/" << needle
  d = (Date.today-1).to_s
  yr = d[0..3]
  mo = d[5..6]
  dy = d[8..9]
  if (needle.scan(/#{yr}#{mo}#{dy}/).count==1)
    needle_year = needle[46..49]
    needle_month = needle[50..51]
    needle_day = needle[52..53]
    needle_date = "#{needle_year}-#{needle_month}-#{needle_day}"
    urls << needle
  end
  #puts needle
  num-=1
end
 #urls << "http://www.basketball-reference.com/boxscores/201312050BRK.html"

#read each box score and return sql
urls.each do |url|
  doc = Nokogiri::HTML(open(url))
  s = doc.to_s

  away_slug = s[s.index('2014.html')-4..s.index('2014.html')-2]
  home_slug = url[url.length-8..url.length-6]

  team1_basic = manscape(s, 'Basic Box Score', '_advanced', 0, 0)[0]
  s = manscape(s, 'Basic Box Score', '_advanced', 0, 0)[1]

  team1_advanced = manscape(s, 'Advanced Box Score', '_basic', 0, 0)[0]
  s = manscape(s, 'Advanced Box Score', '_basic', 0, 0)[1]

  team2_basic = manscape(s, 'Basic Box Score', '_advanced', 0, 0)[0]
  s = manscape(s, 'Basic Box Score', '_advanced', 0, 0)[1]

  team2_advanced = manscape(s, 'Advanced Box Score', '</tr></tfoot>',0, 0)[0]

  #remove the categories
  team1_basic = remove_categories2(team1_basic)
  team1_advanced = remove_categories2(team1_advanced)
  team2_basic = remove_categories2(team2_basic)
  team2_advanced = remove_categories2(team2_advanced)

  team1_basic = extract_info_basic(team1_basic)
  team2_basic = extract_info_basic(team2_basic)
  team1_advanced = extract_info_advanced(team1_advanced)
  team2_advanced = extract_info_advanced(team2_advanced)

  team1_basic.each do |basic_plyr|
    team1_advanced.each do |adv_plyr|
      if basic_plyr.name==adv_plyr.name
        basic_plyr.stats.merge!(adv_plyr.stats) {|key, aval, bval| aval.merge b_val}
      end
    end
  end

  team2_basic.each do |basic_plyr|
    team2_advanced.each do |adv_plyr|
      if basic_plyr.name==adv_plyr.name
        basic_plyr.stats.merge!(adv_plyr.stats) {|key, aval, bval| aval.merge b_val}
      end
    end
  end


  #start doin shit
  away_team = team1_basic
  home_team = team2_basic

  sql = ""
  queries = []

   starter_count = 0
   away_team.each do |player|
    sql = "UPDATE `oconnor` SET `mp`='#{player.mp}', `team`='#{away_slug}', `opp`='#{home_slug}', "
    player.stats.each_pair {|key,value| sql << "`#{key}`='#{value}', "}
    temp_fdp = (player.stats[:pts]+(player.stats[:trb]*1.2)+(player.stats[:ast]*1.5)+(player.stats[:blk]*2)+player.stats[:stl]*2-player.stats[:tov])
    sql << "`fanduel_pts`='#{temp_fdp}',"
    if starter_count < 5
      sql << "`starter_bench`='starter'"
    else
      sql << "`starter_bench`='bench'"
    end
    t_name = player.name.gsub("'", %q(\\\'))
    sql << " WHERE `date` = '#{Date.today-1}' AND `name` = '#{t_name}';"
    queries << sql
    starter_count+=1
  end

  starter_count = 0
  home_team.each do |player|
    sql = "UPDATE `oconnor` SET `mp`='#{player.mp}', `team`='#{home_slug}', `opp`='#{away_slug}', "
    player.stats.each_pair {|key,value| sql << "`#{key}`='#{value}', "}
    temp_fdp = (player.stats[:pts]+(player.stats[:trb]*1.2)+(player.stats[:ast]*1.5)+(player.stats[:blk]*2)+player.stats[:stl]*2-player.stats[:tov])
    sql << "`fanduel_pts`='#{temp_fdp}',"
    if starter_count < 5
      sql << "`starter_bench`='starter'"
    else
      sql << "`starter_bench`='bench'"
    end
    t_name = player.name.gsub("'", %q(\\\'))
    sql << " WHERE `date` = '#{Date.today-1}' AND `name` = '#{t_name}';"
    queries << sql
    starter_count+=1
  end
db = Mysql.new('127.0.0.1','root',ENV["SQL_PASSWORD"],'fanduel')
queries.each do |que|
  db.query que
  #puts que
  end
end

puts "Yesterday's box scores added from Basketball Reference"

#Still need to add in fill Lezhlie and fill todays pool
#START FILL LEZHLIE

def get_trailing_avg_day
  how_many_games = {}

  names = []
  db = Mysql.new('127.0.0.1','root',ENV["SQL_PASSWORD"],'fanduel')
  name_results = db.query("SELECT name from oconnor where fanduel_pts is not null and mp > 0 order by name asc")

  name_results.each do |name_result|
    names << name_result[0]
  end
  names = names.uniq

  names.each do |name|
    master_avgs_string = "#{name}, "

    db = Mysql.new('127.0.0.1','root',ENV["SQL_PASSWORD"],'fanduel')
    results = db.query("SELECT date, name, fanduel_pts, mp from oconnor where name='#{Mysql.escape_string(name)}' and fanduel_pts is not null and date < '#{Date.today}' order by date asc")

    games = []

    results.each do |result|
      games.push(result[2].to_f/result[3].to_f)
    end

    empty = []
    averages1=[]
    averages2=[]
    averages3=[]
    averages4=[]
    averages5=[]
    averages6=[]
    averages7=[]
    averages8=[]
    averages9=[]
    averages10=[]
    averages11=[]
    averages12=[]
    averages13=[]
    averages14=[]
    averages15=[]

    differences = [[empty], [averages1], [averages2], [averages3], [averages4], [averages5], [averages6], [averages7], [averages8], [averages9], [averages10], [averages11], [averages12], [averages13], [averages14], [averages15]]

    avg_differences = []
    games.each do |game|

      game_num = games.index(game)
      if game_num!=0
        #puts "Actual Performance in game #{game_num}: #{games[game_num]}"

        if game_num > 15
          upper = 15
        else
          upper = game_num
        end

        for j in 1..upper

        trailing_number = j
        sum = 0
        i = 1

        while i <= trailing_number
          game_avg = games[game_num-i]
          sum+= game_avg
          i+=1
        end

        trailing_avg = sum/trailing_number
        difference = (games[game_num]-trailing_avg).abs
        differences[trailing_number].push(difference)
        #puts "#{trailing_number} game average: #{difference} p/m off"
        end
      end
    end
    haystack = []
    for d in 1..15
      sum=0
      num_of_avgs=0
      differences[d].each do |diff|
        if diff.class==Float
          #puts "#{d}: #{diff}"
          sum+=diff
          num_of_avgs+=1
        end
      end

      if num_of_avgs>0
        avg_avg = sum/num_of_avgs
        haystack.push(avg_avg)
        master_avgs_string << "#{avg_avg},"
      end
    end

    if haystack!=nil
      what_to_use = 0
      if haystack.index(haystack.min) != nil
        what_to_use = haystack.index(haystack.min)
      end
      #puts "#{name} - #{what_to_use+1}"
      how_many_games[name] = what_to_use+1
    end
  end
  return how_many_games
end


names = []
nm_results = db.query("SELECT name from oconnor where date = '#{Date.today}'")
nm_results.each do |nm_result|
  names << nm_result[0]
end

CSV.open("/Users/michael-orderup/SkyDrive/Project Mellon/lezhlie.csv", "w") do |csv|
  csv << ["name", "date", "opp", "mp", "fanduel_pts"]

what_day_to_use_hash = get_trailing_avg_day

count = 0
names.each do |name|
  sql_name = Mysql.escape_string(name)

  if what_day_to_use_hash.has_key?(name)
    #puts "#{name} - #{what_day_to_use_hash[name]}"
  end


  if what_day_to_use_hash.has_key?(name)
    count = what_day_to_use_hash[name]
  end

  if count >= 15
    sql = "SELECT name, date, opp, mp, fanduel_pts from oconnor where name ='#{sql_name}' and date < '#{Date.today}' and mp is not null order by date desc LIMIT 0,15"
    results = db.query(sql)
      results.each do |result|
        csv << ["#{result[0]}", "#{result[1]}", "#{result[2]}", "#{result[3]}", "#{result[4]}"]
      end
  end

  if (count < 15 && count > 0)
    sql = "SELECT name, date, opp, mp, fanduel_pts from oconnor where name ='#{sql_name}' and date < '#{Date.today}' and mp is not null order by date desc LIMIT 0,#{count}"
    results = db.query(sql)
      results.each do |result|
        csv << ["#{result[0]}", "#{result[1]}", "#{result[2]}", "#{result[3]}", "#{result[4]}"]
      end

    j = 15-count
    while j > 0 do
      csv << ["#{name}", "NULL", "NULL", "NULL", "NULL"]
      j-=1
    end
  end

  if count == 0
    for i in 0..14
      csv << ["#{name}", "NULL", "NULL", "NULL", "NULL"]
    end
  end
end
end

puts "Lezhlie filled"


#START FILL TODAYS POOL
names = []
results = db.query("SELECT position, name, salary, rotowire_mp, numberfire_mp, rotowire_fdp, numberfire_fdp, monster_fdp, opp, monster_ease, over_under, spread from oconnor where date = '#{Date.today}'")

CSV.open("/Users/michael-orderup/SkyDrive/Project Mellon/todayspool.csv", "w") do |csv|
  csv << ["position", "name", "salary", "rotowire_mp", "numberfire_mp", "rotowire_fdp", "numberfire_fdp", "monster_fdp", "opp", "monster_ease", "over_under", "spread"]

  results.each do |result|
    csv << ["#{result[0]}", "#{result[1]}", "#{result[2]}", "#{result[3]}", "#{result[4]}", "#{result[5]}", "#{result[6]}", "#{result[7]}", "#{result[8]}", "#{result[9]}", "#{result[10]}", "#{result[11]}"]
  end
end

puts "Today's pool filled"
