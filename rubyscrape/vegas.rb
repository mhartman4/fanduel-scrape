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

