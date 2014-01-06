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

  #puts temp_fdp
  #sql_formatted_name =temp_name.gsub("'", %q(\\\'))
  player_count=player_count-1

  sql = "UPDATE `oconnor` SET `rotowire_fdp`='#{temp_fdp}', `rotowire_mp`='#{temp_mp}' WHERE `date` = '#{Date.today}' AND `name` = '#{temp_name.gsub("'", %q(\\\'))}';"

  db.query sql
  #puts sql
  #puts player_string
end

#puts s

#s = manscape(s, 'td class="firstleft"', '')
