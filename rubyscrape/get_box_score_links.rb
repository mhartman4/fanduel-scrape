require 'rubygems'
require 'open-uri'
require 'nokogiri'
require 'CSV'
require 'tiny_tds'
require 'active_support/all'

class Player
  attr_reader :name, :mp, :stats

  def initialize(name, mp, stats)
    @name = name
    @mp = mp
    @stats = stats
  end
end

def manscape(input, a, b, a_plus_minus, b_plus_minus)
  trimmings = input[input.index(a)+a_plus_minus..input.index(b)+b_plus_minus]
  the_rest = input[input.index(b)+b_plus_minus..input.length]
  return [trimmings, the_rest]
end

def remove_categories(input)
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
    mp = mp.to_f

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

    plyr_obj = Player.new(name, mp, stats)
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

    plyr_obj = Player.new(name, mp, stats)
    adv_players << plyr_obj
  end
  return adv_players
end

initial_url = "http://www.basketball-reference.com/leagues/NBA_2014_games.html"


doc = Nokogiri::HTML(open(initial_url))
s = doc.to_s
num = s.scan(/>Box Score</).count

urls = []
while num > 0 do
 needle = manscape(s, '">Box Score', '">Box Score', -17, -1)[0]
  s = manscape(s, '">Box Score', '">Box Score', 0, 20)[1]
  s = manscape(s, '</tr>', '</tr>', 0, 20)[1]
  needle = "http://www.basketball-reference.com/boxscores/" << needle
  if (needle.scan(/1122/).count==0)
    urls << needle
    puts needle
  end
  num-=1
end

