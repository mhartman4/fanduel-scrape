start_time = Time.now
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

centers = []
pfs = []
sfs = []
sgs = []
pgs = []


#read in player list and put them in the appropriate array (doesn't take long)
CSV.foreach("reiger.csv", :headers => true) do |row|
  temp_position = row["position"]
  temp_name = row["name"]
  temp_points = row["projected_points"].to_f
  temp_salary = row["salary"].to_f
  temp_value = row["value"].to_f
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

#array of possible lineups
possible_lineups = []

iteration_count = 0
unique_count = 0

=begin
#get rid of inefficient players
c_sal_thresh = centers[0].salary
c_pt_thresh = centers[0].points
pf_sal_thresh = [pfs[0].salary, pfs[1].salary].max
pf_pt_thresh = [pfs[0].points, pfs[1].points].min
sf_sal_thresh = [sfs[0].salary, sfs[1].salary].max
sf_pt_thresh = [sfs[0].points, sfs[1].points].min
sg_sal_thresh = [sgs[0].salary, sgs[1].salary].max
sg_pt_thresh = [sgs[0].points, sgs[1].points].min
pg_sal_thresh = [pgs[0].salary, pgs[1].salary].max
pg_pt_thresh = [pgs[0].points, pgs[1].points].min

centers.each do |center|
  if center.salary > c_sal_thresh
    centers.delete(center)
  end
end

pfs.each do |pf|
  if ((pf.salary >= pf_sal_thresh) && (pf.points <= pf_pt_thresh))
    pfs.delete(pf)
  end
end

sfs.each do |sf|
  if ((sf.salary >= sf_sal_thresh) && (sf.points <= sf_pt_thresh))
    sfs.delete(sf)
  end
end

sgs.each do |sg|
  if ((sg.salary >= sg_sal_thresh) && (sg.points <= sg_pt_thresh))
    sgs.delete(sg)
  end
end

pgs.each do |pg|
  if ((pg.salary >= pg_sal_thresh) && (pg.points <= pg_pt_thresh))
    pgs.delete(pg)
  end
end
=end
all = [centers, pfs, sfs, sgs, pgs]
all.each do |ary|
  puts ary.length
end


for i in 0..centers.length-1
  for j in 0..pfs.length-1
    for k in (j+1)..pfs.length-1
      for l in 0..sfs.length-1
        for m in (l+1)..sfs.length-1
          for n in 0..sgs.length-1
            for o in (n+1)..sgs.length-1
              for p in 0..pgs.length-1
                for q in (p+1)..pgs.length-1
                  temp_payroll = centers[i].salary+pfs[j].salary+pfs[k].salary+sfs[l].salary+sfs[m].salary+sgs[n].salary+sgs[o].salary+pgs[p].salary+pgs[q].salary

                  iteration_count+=1
                  puts iteration_count
                  #filter for teams under 60k in payroll
                  if (temp_payroll < 60001 && temp_payroll > 53500)
                      temp_output = centers[i].points+pfs[j].points+pfs[k].points+sfs[l].points+sfs[m].points+sgs[n].points+sgs[o].points+pgs[p].points+pgs[q].points
                      #puts "C: #{centers[i].name}, PF: #{pfs[j].name}, PF: #{pfs[k].name}, SF: #{sfs[l].name}, SF: #{sfs[m].name}, SG: #{sgs[n].name}, SG: #{sgs[o].name}, PG: #{pgs[p].name}, PG: #{pgs[q].name} - #{temp_output} points, $#{temp_payroll}"
                      temp_lineup = Lineup.new(pgs[q], pgs[p], sgs[o], sgs[n], sfs[m], sfs[l], pfs[k], pfs[j], centers[i])
                      possible_lineups << temp_lineup
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
