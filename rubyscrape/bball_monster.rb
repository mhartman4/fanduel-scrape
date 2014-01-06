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

puts num_players
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

