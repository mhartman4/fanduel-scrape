start_time = Time.now
require 'csv'
require 'mysql'
require 'spreadsheet'

class Player
  attr_reader :position, :name, :points, :salary

  def initialize(position, name, points, salary)
    @position = position
    @name = name
    @points = points.to_f
    @salary = salary.to_i
  end
end

def print_players(all)
  all.each do |ary|
    ary.each do |plyr|
      puts "#{plyr.name} - #{plyr.points}, #{plyr.salary}"
    end
  end
end

def get_player_index(plyr_name, all_arrays)
  all_arrays.each do |ary|
    ary.each do |plyr|
      plyr_index = nil
      if plyr.name == plyr_name
        plyr_index = ary.index(plyr)
        return plyr_index
      end
    end
  end
end

class Lineup
  attr_reader :pg1, :pg2, :sg1, :sg2, :sf1, :sf2, :pf1, :pf2, :c, :payroll, :output, :roster

  def initialize (pg1, pg2, sg1, sg2, sf1, sf2, pf1, pf2, c)
    @pg1 = Player.new(pg1.position, pg1.name, pg1.points, pg1.salary)
    @pg2 = Player.new(pg2.position, pg2.name, pg2.points, pg2.salary)
    @sg1 = Player.new(sg1.position, sg1.name, sg1.points, sg1.salary)
    @sg2 = Player.new(sg2.position, sg2.name, sg2.points, sg2.salary)
    @sf1 = Player.new(sf1.position, sf1.name, sf1.points, sf1.salary)
    @sf2 = Player.new(sf2.position, sf2.name, sf2.points, sf2.salary)
    @pf1 = Player.new(pf1.position, pf1.name, pf1.points, pf1.salary)
    @pf2 = Player.new(pf2.position, pf2.name, pf2.points, pf2.salary)
    @c = Player.new(c.position, c.name, c.points, c.salary)
    @payroll = pg1.salary+pg2.salary+sg1.salary+sg2.salary+sf1.salary+sf2.salary+pf1.salary+pf2.salary+c.salary
    @output = pg1.points+pg2.points+sg1.points+sg2.points+sf1.points+sf2.points+pf1.points+pf2.points+c.points
    @roster = [pg1.name, pg2.name, sg1.name, sg2.name, sf1.name, sf2.name, pf1.name, pf2.name, c.name].sort
  end
end

blacklist = ["Andre Drummond"]

centers = []
pfs = []
sfs = []
sgs = []
pgs = []

book = Spreadsheet.open('/Users/michael-orderup/SkyDrive/Project Mellon/Mellon.xls')
sheet1 = book.worksheet('Output - Reiger')

for i in 1..sheet1.count-1
  temp_position = sheet1[i,0].value
  temp_name = sheet1[i,1].value
  temp_points = sheet1[i,2].value.to_f
  temp_salary = sheet1[i,3].value.to_f

  if blacklist.index(temp_name)==nil
    if temp_position!="NULL"
      temp_player = Player.new(temp_position, temp_name, temp_points, temp_salary)
      if temp_position=="C"
          centers << temp_player
      elsif temp_position=="PF"
          pfs << temp_player
      elsif temp_position=="SF"
          sfs << temp_player
      elsif temp_position=="SG"
          sgs << temp_player
      elsif temp_position=="PG"
        pgs << temp_player
      end
    end
  end
end
all = [centers, pfs, sfs, sgs, pgs]

print_players(all)
=begin
#get rid of anyone with projected 0
all.each do |ary|
  ary.each do |plyr|
    ary.delete_if {|x| x.points == 0.0 }
  end
  ary.sort! {|a,b| b.points <=> a.points}
end

#keep only the top $3500 center
min_players = []
centers.each do |center|
  if center.salary == 3500
    min_players << center
  end
end
min_players.sort! {|a,b| b.points <=> a.points}
min_players.each do |min_plyr|
  if min_players.index(min_plyr)!=0
    centers.delete(min_plyr)
  end
end

#get rid of useless players
centers.sort! {|a,b| b.salary <=> a.salary}
centers2 = []
centers.each do |center|
  centers2 << center
end
centers2.each do |c2|
  num_who_are_better_and_make_the_same_or_less = 0
  centers.each do |c1|
    #puts "#{c2.name} - #{c1.name}"
    if ((c1.points > c2.points) && (c1.salary <= c2.salary))
      num_who_are_better_and_make_the_same_or_less+=1
      #puts "**yep, get rid of #{c2.name}"
    end
  end

  if num_who_are_better_and_make_the_same_or_less>0
      centers.delete(c2)
  end
end

all.each do |ary|
  ary.each do |plyr|
    #keep only the top $3500 center
    min_players = []
    ary.each do |plyr|
      if plyr.salary == 3500
        min_players << plyr
      end
    end
    min_players.sort! {|a,b| b.points <=> a.points}
    min_players.each do |min_plyr|
      if min_players.index(min_plyr)>1
        ary.delete(min_plyr)
      end
    end

    #get rid of useless players
    ary.sort! {|a,b| b.salary <=> a.salary}
    ary2 = []
    ary.each do |plyr|
      ary2 << plyr
    end
    ary2.each do |c2|
      num_who_are_better_and_make_the_same_or_less = 0
      ary.each do |c1|
        #puts "#{c2.name} - #{c1.name}"
        if ((c1.points > c2.points) && (c1.salary <= c2.salary))
          num_who_are_better_and_make_the_same_or_less+=1
        end
      end

      if num_who_are_better_and_make_the_same_or_less>1
        ary.delete(c2)
      end
    end

  end
end



all.each do |ary|
  puts ary.length
  ary.each do |plyr|
    #puts "#{plyr.position}, #{plyr.name}, #{plyr.points}, #{plyr.salary}"
  end
end


#array of possible lineups
possible_lineups = []

iteration_count = 0
unique_count = 0
all = [centers, pfs, sfs, sgs, pgs]

=begin
for i in 0..centers.length-1
  for j in 0..pfs.length-1
    for k in (j+1)..pfs.length-1
      for l in 0..sfs.length-1
        for m in (l+1)..sfs.length-1
          for n in 0..sgs.length-1
            for o in (n+1)..sgs.length-1
              for p in 0..pgs.length-1
                for q in (p+1)..pgs.length-1
                  iteration_count+=1
                  puts "#{iteration_count} - #{i}:#{j}:#{k}:#{l}:#{m}:#{n}:#{o}:#{p}:#{q}"
                  temp_payroll = centers[i].salary+pfs[j].salary+pfs[k].salary+sfs[l].salary+sfs[m].salary+sgs[n].salary+sgs[o].salary+pgs[p].salary+pgs[q].salary

                  #filter for teams under 60k in payroll
                  if (temp_payroll < 60001 && temp_payroll > 57500)
                      temp_output = centers[i].points+pfs[j].points+pfs[k].points+sfs[l].points+sfs[m].points+sgs[n].points+sgs[o].points+pgs[p].points+pgs[q].points
                      if temp_output > 268
                        temp_lineup = Lineup.new(pgs[q], pgs[p], sgs[o], sgs[n], sfs[m], sfs[l], pfs[k], pfs[j], centers[i])
                        puts temp_output
                        possible_lineups << temp_lineup
                      end
                      #unique_count+=1
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
sorted_lineups = possible_lineups.sort_by { |ul| [ul.output] }
sorted_count = 0
sorted_lineups.each do |lineup|
    puts "Lineup #{sorted_count+1}"
    puts "Output: #{lineup.output}"
    puts "Payroll: #{lineup.payroll}"
    puts "PG1: #{lineup.pg1.name} - #{lineup.pg1.points}, #{lineup.pg1.salary}"
    puts "PG2: #{lineup.pg2.name} - #{lineup.pg2.points}, #{lineup.pg2.salary}"
    puts "SG1: #{lineup.sg1.name} - #{lineup.sg1.points}, #{lineup.sg1.salary}"
    puts "SG2: #{lineup.sg2.name} - #{lineup.sg2.points}, #{lineup.sg2.salary}"
    puts "SF1: #{lineup.sf1.name} - #{lineup.sf1.points}, #{lineup.sf1.salary}"
    puts "SF2: #{lineup.sf2.name} - #{lineup.sf2.points}, #{lineup.sf2.salary}"
    puts "PF1: #{lineup.pf1.name} - #{lineup.pf1.points}, #{lineup.pf1.salary}"
    puts "PF2: #{lineup.pf2.name} - #{lineup.pf2.points}, #{lineup.pf2.salary}"
    puts "C: #{lineup.c.name} - #{lineup.c.points}, #{lineup.c.salary}"
    puts ""
    sorted_count = sorted_count +1
end

puts unique_count
puts iteration_count
puts Time.now-start_time



=begin
#gets rid of duplicate lineups (e.g. SG1: Jordan SG2: Bird vs. SG1: Bird SG2: Jordan)
unique_lineups = possible_lineups.uniq { |possline| possline.roster }

#sorts all possible lineups by their output (i.e. how many points they're projected to have)
sorted_lineups = unique_lineups.sort_by { |ul| [ul.output] }
sorted_count = 0
sorted_lineups.each do |lineup|
    puts "Lineup #{sorted_count+1}"
    puts "Output: #{lineup.output}"
    puts "Payroll: #{lineup.payroll}"
    puts "PG1: #{lineup.pg1.name}"
    puts "PG2: #{lineup.pg2.name}"
    puts "SG1: #{lineup.sg1.name}"
    puts "SG2: #{lineup.sg2.name}"
    puts "SF1: #{lineup.sf1.name}"
    puts "SF2: #{lineup.sf2.name}"
    puts "PF1: #{lineup.pf1.name}"
    puts "PF2: #{lineup.pf2.name}"
    puts "C: #{lineup.c.name}"
    puts ""
    sorted_count = sorted_count +1
end



puts "#{iteration_count} iterations"
puts "#{sorted_lineups.length} possible lineups returned"

puts "Script took #{Time.now - start_time} seconds"
=end
