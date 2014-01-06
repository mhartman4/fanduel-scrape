start_time = Time.now
require 'csv'
require 'mysql'

blacklist = ["Michael Beasley", "Kenyon Martin", "Gary Neal", "Kelly Olynyk", "Luol Deng", "Thabo Sefolosha", "Tiago Splitter", "Greivis Vasquez", "Rodney Stuckey", "Paul Pierce"]

c_staple = [nil]
pf_staples = ["Kris Humphries", "Taj Gibson"]
sf_staples = [nil, nil]
sg_staples = [nil, nil]
pg_staples = [nil, nil]

all_staples << c_staple

payroll_lower_bound = 55500
output_threshold = 265

class Player
  attr_reader :position, :name, :points, :salary

  def initialize(position, name, points, salary)
    @position = position
    @name = name
    @points = points.to_f
    @salary = salary.to_i
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

possible_lineups = []
iteration_count = 0
unique_count = 0

centers = []
pfs = []
sfs = []
sgs = []
pgs = []

=begin
#read in player list and put them in the appropriate array
CSV.foreach("reiger.csv", :headers => true) do |row|
  temp_position = row["position"]
  temp_name = row["name"]
  temp_points = row["projected_points"].to_f
  temp_salary = row["salary"].to_f
  temp_value = temp_points/temp_salary*1000
  temp_player = Player.new(temp_position, temp_name, temp_points, temp_salary)

  if blacklist.index(temp_name)==nil
    if temp_position=="C"
      if c_staple.first==nil
        centers << temp_player
      elsif temp_name == c_staple.first
        centers << temp_player
      end
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
=end

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

#gets rid player if there are x players who make less and produce more
def trim_worse_players(threshold, all, exceptions)
  all.each do |ary|
    ary.each do |plyr|
      ary.sort! {|a,b| b.salary <=> a.salary}
      ary2 = []
      ary.each do |plyr|
        ary2 << plyr
      end
      ary2.each do |c2|
        num_who_are_better_and_make_the_same_or_less = 0
        ary.each do |c1|
          if ((c1.points > c2.points) && (c1.salary <= c2.salary))
            num_who_are_better_and_make_the_same_or_less+=1
          end
        end

        if num_who_are_better_and_make_the_same_or_less>threshold
          if exceptions == nil
            ary.delete(c2)
          elsif c2.name != exceptions.first && c2.name != exceptions.last
            ary.delete(c2)
          end
        end
      end
    end
  end
end

def print_lengths(all)
  all.each do |ary|
    puts ary.length
  end
end

def print_players(all)
  all.each do |ary|
    ary.each do |plyr|
      puts "#{plyr.name} - #{plyr.points}, #{plyr.salary}"
    end
  end
end

all = [centers, pfs, sfs, sgs, pgs]

#threshold: default is 1 (except centers = 0)
trim_worse_players(0, [centers], c_staple)
trim_worse_players(0, [pfs], pf_staples)
trim_worse_players(0, [sfs], sf_staples)
trim_worse_players(0, [sgs], sg_staples)
trim_worse_players(0, [pgs], pg_staples)

if pf_staples.last!=nil
  new_pfs = [pfs[get_player_index(pf_staples.first, all)], pfs[get_player_index(pf_staples.last, all)]]
  pfs = new_pfs
end

if sf_staples.last!=nil
  new_sfs = [sfs[get_player_index(sf_staples.first, all)], sfs[get_player_index(sf_staples.last, all)]]
  sfs = new_sfs
end

if sg_staples.last!=nil
  new_sgs = [sgs[get_player_index(sg_staples.first, all)], sgs[get_player_index(sg_staples.last, all)]]
  sgs = new_sgs
end

if pg_staples.last!=nil
  new_pgs = [pgs[get_player_index(pg_staples.first, all)], pgs[get_player_index(pg_staples.last, all)]]
  pgs = new_pgs
end

all = [centers, pfs, sfs, sgs, pgs]
print_lengths(all)
=begin
#standard reiger
if
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

                    if (temp_payroll < 60001 && temp_payroll > payroll_lower_bound)
                      temp_output = centers[i].points+pfs[j].points+pfs[k].points+sfs[l].points+sfs[m].points+sgs[n].points+sgs[o].points+pgs[p].points+pgs[q].points
                        if temp_output > output_threshold
                          temp_lineup = Lineup.new(pgs[q], pgs[p], sgs[o], sgs[n], sfs[m], sfs[l], pfs[k], pfs[j], centers[i])
                          puts temp_output
                          possible_lineups << temp_lineup
                          unique_count+=1
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
  end
for i in 0..centers.length-1

  for j in 0..pfs.length-1
    if pf_staples.first!=nil && pf_staples.last==nil
      pf_lower = get_player_index(pf_staples.first, all)
      pf_upper = get_player_index(pf_staples.first, all)
    else
      pf_lower = j+1
      pf_upper = pfs.length-1
    end

    for k in pf_lower..pf_upper
    if j!=k

        for l in 0..sfs.length-1
          if sf_staples.first!=nil && sf_staples.last==nil
            sf_lower = get_player_index(sf_staples.first, all)
            sf_upper = get_player_index(sf_staples.first, all)
          else
            sf_lower = 0
            sf_upper = sfs.length-1
          end

          for m in sf_lower..sf_upper
          if l!=m

              for n in 0..sgs.length-1
                if sg_staples.first!=nil && sg_staples.last==nil
                sg_lower = get_player_index(sg_staples.first, all)
                sg_upper = get_player_index(sg_staples.first, all)
                else
                sg_lower = 0
                sg_upper = sgs.length-1
                end
                if n!=o
                for o in sg_lower..sg_upper


                    for p in 0..pgs.length-1
                      if pg_staples.first!=nil && pg_staples.last==nil
                      pg_lower = get_player_index(pg_staples.first, all)
                      pg_upper = get_player_index(pg_staples.first, all)
                      else
                      pg_lower = 0
                      pg_upper = pgs.length-1
                      end

                      for q in pg_lower..pg_upper
                      if p!=q
                        iteration_count+=1
                        puts "#{iteration_count} - #{i}:#{j}:#{k}:#{l}:#{m}:#{n}:#{o}:#{p}:#{q}"
                          temp_payroll = centers[i].salary+pfs[j].salary+pfs[k].salary+sfs[l].salary+sfs[m].salary+sgs[n].salary+sgs[o].salary+pgs[p].salary+pgs[q].salary

                          #filter for teams under 60k in payroll
                          if (temp_payroll < 60001 && temp_payroll > payroll_lower_bound)
                              temp_output = centers[i].points+pfs[j].points+pfs[k].points+sfs[l].points+sfs[m].points+sgs[n].points+sgs[o].points+pgs[p].points+pgs[q].points
                              if temp_output > output_threshold
                                temp_lineup = Lineup.new(pgs[q], pgs[p], sgs[o], sgs[n], sfs[m], sfs[l], pfs[k], pfs[j], centers[i])
                                puts temp_output
                                possible_lineups << temp_lineup
                                unique_count+=1
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
        end
      end
    end
  end
end

unique_lineups = possible_lineups.uniq { |possline| possline.roster }

sorted_lineups = unique_lineups.sort_by { |ul| [ul.output] }
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

puts "#{unique_count} unique lineups"
puts "#{iteration_count} iterations"
puts "#{Time.now-start_time} seconds"
puts "#{iteration_count/(Time.now-start_time)} iterations per second"
