require 'csv'

start_time = Time.now

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

CSV.foreach("playerlist.csv", :headers => true) do |row|
  temp_position = row["position"]
  temp_name = row["name"]
  temp_points = row["points"]
  temp_salary = row["salary"]

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
combo_count = 0
unique_count = 0
possible_lineups = []

pf2s = pfs
sf2s = sfs
sg2s = sgs
pg2s = pgs

centers.each do |center|
  pfs.each do |pf|
    pf2s.each do |pf2|
      if pf != pf2
        sfs.each do |sf|
          sf2s.each do |sf2|
             if sf != sf2
              sgs.each do |sg|
                sg2s.each do |sg2|
                    if sg != sg2
                      pgs.each do |pg|
                        pg2s.each do |pg2|
                          if (pg != pg2)
                            temp_payroll = pg.salary+pg2.salary+sg.salary+sg2.salary+sf.salary+sf2.salary+pf.salary+pf2.salary+center.salary
                            if temp_payroll < 60000
                              temp_lineup = Lineup.new(pg, pg2, sg, sg2, sf, sf2, pf, pf2, center)
                              possible_lineups << temp_lineup
                              unique_count = unique_count + 1
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

puts "#{unique_count}"

time_finish = Time.now
diff = time_finish - start_time
puts "Script took #{diff} seconds"







