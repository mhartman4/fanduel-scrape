#---------INPUTS---------#

blacklist = []

c_staple = [nil]
pf_staples = [nil, nil]
sf_staples = [nil, nil]
sg_staples = [nil, nil]
pg_staples = [nil, nil]

payroll_lower_bound = 50000
output_threshold = 230

how_many_pfs_to_trim = 1
how_many_sfs_to_trim = 1
how_many_sgs_to_trim = 1
how_many_pgs_to_trim = 1

ready_to_go = true

#------------------------#


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

def are_there_staples(arrays)
  bool = false
  arrays.each do |ary|
    if (ary.first!=nil || ary.last!=nil)
      bool = true
    end
  end
  return bool
end

def only_one(ary)
  if ary.first!=nil && ary.last==nil
    return true
  else
    return false
  end
end

def num_combos(input)
  if input==1
    return 1
  else
    num_combos = 0
    i = input
    while i > 0
      num_combos+=(i-1)
      i-=1
    end
    return num_combos
  end
end

def calculate_iterations(all_players, all_staples)

  num_c = all_players[0].length
  num_pf = all_players[1].length
  num_sf = all_players[2].length
  num_sg = all_players[3].length
  num_pg = all_players[4].length

  array_of_lengths = [num_c, num_pf, num_sf, num_sg, num_pg]

  exceptions = []
  all_staples.each do |staple_set|
    if only_one(staple_set)
      exceptions << all_staples.index(staple_set)
    end
  end

  if exceptions.size==0
    num_iterations = array_of_lengths[0]
    for i in 1..4
        num_iterations*=num_combos(array_of_lengths[i])
    end
  end

  if exceptions.size==1
    exception_pos0 = exceptions[0]
    num_iterations = array_of_lengths[exception_pos0]-1
    num_iterations*=array_of_lengths[0]
    for i in 1..4
      if i!=exception_pos0
        num_iterations*=num_combos(array_of_lengths[i])
        puts "#{i} - #{array_of_lengths[i]} - #{num_combos(array_of_lengths[i])}"
      end
    end
  end

  if exceptions.size==2
    exception_pos0 = exceptions[0]
    exception_pos1 = exceptions[1]

    num_iterations = array_of_lengths[exception_pos0]-1
    num_iterations *= array_of_lengths[exception_pos1]-1
    num_iterations*=array_of_lengths[0]

    for i in 1..4
      if i!=exception_pos0 && i!=exception_pos1
        num_iterations*=num_combos(array_of_lengths[i])
      end
    end
  end

  if exceptions.size==3
    exception_pos0 = exceptions[0]
    exception_pos1 = exceptions[1]
    exception_pos2 = exceptions[2]

    num_iterations = array_of_lengths[exception_pos0]-1
    num_iterations *= array_of_lengths[exception_pos1]-1
    num_iterations *= array_of_lengths[exception_pos2]-1
    num_iterations*=array_of_lengths[0]

    for i in 1..4
      if i!=exception_pos0 && i!=exception_pos1 && i!=exception_pos2
        num_iterations*=num_combos(array_of_lengths[i])
      end
    end
  end

  if exceptions.size==4
    exception_pos0 = exceptions[0]
    exception_pos1 = exceptions[1]
    exception_pos2 = exceptions[2]
    exception_pos3 = exceptions[3]

    num_iterations = array_of_lengths[exception_pos0]-1
    num_iterations *= array_of_lengths[exception_pos1]-1
    num_iterations *= array_of_lengths[exception_pos2]-1
    num_iterations *= array_of_lengths[exception_pos3]-1
    num_iterations*=array_of_lengths[0]

    for i in 1..4
      if i!=exception_pos0 && i!=exception_pos1 && i!=exception_pos2 && i!=exception_pos3
        num_iterations*=num_combos(array_of_lengths[i])
      end
    end
  end
return num_iterations
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


book = Spreadsheet.open('/Users/michael-orderup/SkyDrive/Project Mellon/Mellon.xls')
sheet1 = book.worksheet('Output - Reiger')
for i in 1..sheet1.count-1
  temp_position = sheet1[i,0].value
  temp_name = sheet1[i,1].value
  temp_points = sheet1[i,2].value.to_f
  temp_salary = sheet1[i,3].value.to_f

  if blacklist.index(temp_name)==nil
    if temp_position!="NULL" && temp_points>0.0
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
print_players([pfs])

#if both slots are stapled, make the position array just those 2
if c_staple.last!=nil
  new_centers = [centers[get_player_index(c_staple.first, all)]]
  centers = new_centers
end

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

#threshold: default is 1 (except centers = 0)

trim_worse_players(0, [centers], c_staple)
trim_worse_players(how_many_pfs_to_trim, [pfs], pf_staples)
trim_worse_players(how_many_sfs_to_trim, [sfs], sf_staples)
trim_worse_players(how_many_sgs_to_trim, [sgs], sg_staples)
trim_worse_players(how_many_pgs_to_trim, [pgs], pg_staples)


all = [centers, pfs, sfs, sgs, pgs]
all_staples = [c_staple, pf_staples, sf_staples, sg_staples, pg_staples]

print_lengths(all)
puts calculate_iterations(all, all_staples)
puts calculate_iterations(all, all_staples)/70000/60



if ready_to_go==true

#if there's only one PF
if (only_one(pf_staples)==true && only_one(sf_staples)==false && only_one(sg_staples)==false && only_one(pg_staples)==false)

  for i in 0..centers.length-1
    for j in 0..pfs.length-1
      pf_ind = get_player_index(pf_staples.first, all)
      if j!=pf_ind
        for k in pf_ind..pf_ind
          for l in 0..sfs.length-1
            for m in l+1..sfs.length-1
                for n in 0..sgs.length-1
                  for o in n+1..sgs.length-1
                    for p in 0..pgs.length-1
                      for q in p+1..pgs.length-1
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

#if there's only one SF
if (only_one(pf_staples)==false && only_one(sf_staples)==true && only_one(sg_staples)==false && only_one(pg_staples)==false)

  for i in 0..centers.length-1
    for j in 0..pfs.length-1
      for k in j+1..pfs.length-1
        for l in 0..sfs.length-1
          sf_ind = get_player_index(sf_staples.first, all)
            if l!=sf_ind
            for m in sf_ind..sf_ind
                for n in 0..sgs.length-1
                  for o in n+1..sgs.length-1
                    for p in 0..pgs.length-1
                      for q in p+1..pgs.length-1
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

#if there's only one SG
if (only_one(pf_staples)==false && only_one(sf_staples)==false && only_one(sg_staples)==true && only_one(pg_staples)==false)

  for i in 0..centers.length-1
    for j in 0..pfs.length-1
      for k in j+1..pfs.length-1
        for l in 0..sfs.length-1
          for m in l+1..sfs.length-1
            for n in 0..sgs.length-1
              sg_ind = get_player_index(sg_staples.first, all)
                if n!=sg_ind
                  for o in sg_ind..sg_ind
                    for p in 0..pgs.length-1
                      for q in p+1..pgs.length-1
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

#if there's only one PG
if (only_one(pf_staples)==false && only_one(sf_staples)==false && only_one(sg_staples)==false && only_one(pg_staples)==true)

  for i in 0..centers.length-1
    for j in 0..pfs.length-1
      for k in j+1..pfs.length-1
        for l in 0..sfs.length-1
          for m in l+1..sfs.length-1
            for n in 0..sgs.length-1
              for o in n+1..sgs.length-1
                for p in 0..pgs.length-1
                  pg_ind = get_player_index(pg_staples.first, all)
                    if p!=pg_ind
                      for q in pg_ind..pg_ind
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

#one pf && one sf
if (only_one(pf_staples)==true && only_one(sf_staples)==true && only_one(sg_staples)==false && only_one(pg_staples)==false)

  for i in 0..centers.length-1
    for j in 0..pfs.length-1
      pf_ind = get_player_index(pf_staples.first, all)
      if j!=pf_ind
        for k in pf_ind..pf_ind
          for l in 0..sfs.length-1
            sf_ind = get_player_index(sf_staples.first, all)
            if l!=sf_ind
              for m in sf_ind..sf_ind
                for n in 0..sgs.length-1
                  for o in n+1..sgs.length-1
                    for p in 0..pgs.length-1
                      for q in p+1..pgs.length-1
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

#one pf && one sg
if (only_one(pf_staples)==true && only_one(sf_staples)==false && only_one(sg_staples)==true && only_one(pg_staples)==false)

  for i in 0..centers.length-1
    for j in 0..pfs.length-1
      pf_ind = get_player_index(pf_staples.first, all)
      if j!=pf_ind
        for k in pf_ind..pf_ind
          for l in 0..sfs.length-1
            for m in l+1..sfs.length-1
              for n in 0..sgs.length-1
                sg_ind = get_player_index(sg_staples.first, all)
                if n!=sg_ind
                  for o in sg_ind..sg_ind
                    for p in 0..pgs.length-1
                      for q in p+1..pgs.length-1
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

#one pf && one pg
if (only_one(pf_staples)==true && only_one(sf_staples)==false && only_one(sg_staples)==false && only_one(pg_staples)==true)

  for i in 0..centers.length-1
    for j in 0..pfs.length-1
      pf_ind = get_player_index(pf_staples.first, all)
      if j!=pf_ind
        for k in pf_ind..pf_ind
          for l in 0..sfs.length-1
            for m in l+1..sfs.length-1
              for n in 0..sgs.length-1
                for o in n+1..sgs.length-1
                  for p in 0..pgs.length-1
                    pg_ind = get_player_index(pg_staples.first, all)
                    if p!=pg_ind
                      for q in pg_ind..pg_ind
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

#one pf, one sf, one sg
if (only_one(pf_staples)==true && only_one(sf_staples)==true && only_one(sg_staples)==true && only_one(pg_staples)==false)

  for i in 0..centers.length-1
    for j in 0..pfs.length-1
      pf_ind = get_player_index(pf_staples.first, all)
      if j!=pf_ind
        for k in pf_ind..pf_ind
          for l in 0..sfs.length-1
            sf_ind = get_player_index(sf_staples.first, all)
            if l!=sf_ind
            for m in sf_ind..sf_ind
              for n in 0..sgs.length-1
                sg_ind = get_player_index(sg_staples.first, all)
                if n!=sg_ind
                  for o in sg_ind..sg_ind
                    for p in 0..pgs.length-1
                      for q in p+1..pgs.length-1
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

#one pf, one sf, one pg
if (only_one(pf_staples)==true && only_one(sf_staples)==true && only_one(sg_staples)==false && only_one(pg_staples)==true)

  for i in 0..centers.length-1
    for j in 0..pfs.length-1
      pf_ind = get_player_index(pf_staples.first, all)
      if j!=pf_ind
        for k in pf_ind..pf_ind
          for l in 0..sfs.length-1
            sf_ind = get_player_index(sf_staples.first, all)
            if l!=sf_ind
            for m in sf_ind..sf_ind
              for n in 0..sgs.length-1
                  for o in 0..sgs.length-1
                    for p in 0..pgs.length-1
                      pg_ind = get_player_index(pg_staples.first, all)
                      if p!=pg_ind
                      for q in pg_ind..pg_ind
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

#one pf, one sg, one pg
if (only_one(pf_staples)==true && only_one(sf_staples)==false && only_one(sg_staples)==true && only_one(pg_staples)==true)

  for i in 0..centers.length-1
    for j in 0..pfs.length-1
      pf_ind = get_player_index(pf_staples.first, all)
      if j!=pf_ind
        for k in pf_ind..pf_ind
          for l in 0..sfs.length-1
            for m in l+1..sfs.length-1
              for n in 0..sgs.length-1
                sg_ind = get_player_index(sg_staples.first, all)
                if n!=sg_ind
                  for o in sg_ind..sg_ind
                    for p in 0..pgs.length-1
                      pg_ind = get_player_index(pg_staples.first, all)
                      if p!=pg_ind
                      for q in pg_ind..pg_ind
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

#one pf, one sf, one sg, one pg
if (only_one(pf_staples)==true && only_one(sf_staples)==true && only_one(sg_staples)==true && only_one(pg_staples)==true)

  for i in 0..centers.length-1
    for j in 0..pfs.length-1
      pf_ind = get_player_index(pf_staples.first, all)
      if j!=pf_ind
        for k in pf_ind..pf_ind
          for l in 0..sfs.length-1
            sf_ind = get_player_index(sf_staples.first, all)
            if l!=sf_ind
            for m in sf_ind..sf_ind
              for n in 0..sgs.length-1
                sg_ind = get_player_index(sg_staples.first, all)
                if n!=sg_ind
                  for o in sg_ind..sg_ind
                    for p in 0..pgs.length-1
                      pg_ind = get_player_index(pg_staples.first, all)
                      if p!=pg_ind
                      for q in pg_ind..pg_ind
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
end

#one sf && one sg
if (only_one(pf_staples)==false && only_one(sf_staples)==true && only_one(sg_staples)==true && only_one(pg_staples)==false)

  for i in 0..centers.length-1
    for j in 0..pfs.length-1
      for k in j+1..pfs.length-1
        for l in 0..sfs.length-1
          sf_ind = get_player_index(sf_staples.first, all)
            if l!=sf_ind
              for m in sf_ind..sf_ind
                for n in 0..sgs.length-1
                sg_ind = get_player_index(sg_staples.first, all)
                if n!=sg_ind
                  for o in sg_ind..sg_ind
                    for p in 0..pgs.length-1
                      for q in p+1..pgs.length-1
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

#one sf && one pg
if (only_one(pf_staples)==false && only_one(sf_staples)==true && only_one(sg_staples)==false && only_one(pg_staples)==true)

  for i in 0..centers.length-1
    for j in 0..pfs.length-1
      for k in j+1..pfs.length-1
        for l in 0..sfs.length-1
          sf_ind = get_player_index(sf_staples.first, all)
            if l!=sf_ind
              for m in sf_ind..sf_ind
                for n in 0..sgs.length-1
                  for o in n+1..sgs.length-1
                    for p in 0..pgs.length-1
                      pg_ind = get_player_index(pg_staples.first, all)
                      if p!=pg_ind
                      for q in pg_ind..pg_ind
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

#one sf, one sg, one pg
if (only_one(pf_staples)==false && only_one(sf_staples)==true && only_one(sg_staples)==true && only_one(pg_staples)==true)

  for i in 0..centers.length-1
    for j in 0..pfs.length-1
        for k in j+1..pfs.length-1
          for l in 0..sfs.length-1
            sf_ind = get_player_index(sf_staples.first, all)
            if l!=sf_ind
            for m in sf_ind..sf_ind
              for n in 0..sgs.length-1
                sg_ind = get_player_index(sg_staples.first, all)
                if n!=sg_ind
                  for o in sg_ind..sg_ind
                    for p in 0..pgs.length-1
                      pg_ind = get_player_index(pg_staples.first, all)
                      if p!=pg_ind
                      for q in pg_ind..pg_ind
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

#one sg && one pg
if (only_one(pf_staples)==false && only_one(sf_staples)==false && only_one(sg_staples)==true && only_one(pg_staples)==true)

  for i in 0..centers.length-1
    for j in 0..pfs.length-1
      for k in j+1..pfs.length-1
        for l in 0..sfs.length-1
          for m in l+1..sfs.length-1
            for n in 0..sgs.length-1
              sg_ind = get_player_index(sg_staples.first, all)
                if n!=sg_ind
                  for o in sg_ind..sg_ind
                    for p in 0..pgs.length-1
                      pg_ind = get_player_index(pg_staples.first, all)
                      if p!=pg_ind
                      for q in pg_ind..pg_ind
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

#standard Reiger
if (only_one(pf_staples)==false && only_one(sf_staples)==false && only_one(sg_staples)==false && only_one(pg_staples)==false)

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

puts "#{unique_count} unique lineups"
puts "#{iteration_count} iterations"
puts "#{Time.now-start_time} seconds"
puts "#{iteration_count/(Time.now-start_time)} iterations per second"
end
