require 'csv'
require 'mysql'

class Player
  attr_reader :position, :name, :points, :salary

  def initialize(position, name, points, salary)
    @position = position
    @name = name
    @points = points.to_f
    @salary = salary.to_i
  end
end

def get_player_index(plyr_name, ary)
  ary.each do |a|
    if a.name == plyr_name
      plyr_index = ary.index(a)
      return plyr_index
    end
  end
end

centers = []
pfs = []
sfs = []
sgs = []
pgs = []


#read in player list and put them in the appropriate array (doesn't take long)
CSV.foreach("mellon.csv", :headers => true) do |row|
  temp_position = row["position"]
  temp_name = row["name"]
  temp_points = row["projected_points"].to_f
  temp_salary = row["salary"].to_f
  temp_value = temp_points/temp_salary*1000
  temp_player = Player.new(temp_position, temp_name, temp_points, temp_salary)

  if temp_position=="C"
    #if temp_value > 4.3
      centers << temp_player
    #end
  elsif temp_position=="PF"
    #if temp_value > 4.6
      pfs << temp_player
    #end
  elsif temp_position=="SF"
    #if temp_value > 4.3
      sfs << temp_player
    #end
  elsif temp_position=="SG"
    #if temp_value > 4.2
      sgs << temp_player
    #end
  elsif temp_position=="PG"
    #if temp_value > 4.3
    pgs << temp_player
    #end
  end
end

all = [centers, pfs, sfs, sgs, pgs]

db = Mysql.new('127.0.0.1','root','7nv5r3pr','fanduel')

all.each do |ary|
  ary.each do |plyr|
    sql = "UPDATE oconnor SET mellon='#{plyr.points}' where name='#{plyr.name}' and date='#{Date.today}';"
    puts sql
  end
end

