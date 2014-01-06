require 'rubygems'
require 'mysql'
require 'date'
require 'csv'
require 'dotenv'

def get_trailing_avg_day
  how_many_games = {}

  names = []
  db = Mysql.new('127.0.0.1','root',ENV["SQL_PASSWORD"],'fanduel')
  name_results = db.query("SELECT name from oconnor where fanduel_pts is not null and mp > 0 order by name asc")

  name_results.each do |name_result|
    names << name_result[0]
  end
  names = names.uniq

  names.each do |name|
    master_avgs_string = "#{name}, "

    db = Mysql.new('127.0.0.1','root',ENV["SQL_PASSWORD"],'fanduel')
    results = db.query("SELECT date, name, fanduel_pts, mp from oconnor where name='#{Mysql.escape_string(name)}' and fanduel_pts is not null and date < '#{Date.today}' order by date asc")

    games = []

    results.each do |result|
      games.push(result[2].to_f/result[3].to_f)
    end

    empty = []
    averages1=[]
    averages2=[]
    averages3=[]
    averages4=[]
    averages5=[]
    averages6=[]
    averages7=[]
    averages8=[]
    averages9=[]
    averages10=[]
    averages11=[]
    averages12=[]
    averages13=[]
    averages14=[]
    averages15=[]

    differences = [[empty], [averages1], [averages2], [averages3], [averages4], [averages5], [averages6], [averages7], [averages8], [averages9], [averages10], [averages11], [averages12], [averages13], [averages14], [averages15]]

    avg_differences = []
    games.each do |game|

      game_num = games.index(game)
      if game_num!=0
        #puts "Actual Performance in game #{game_num}: #{games[game_num]}"

        if game_num > 15
          upper = 15
        else
          upper = game_num
        end

        for j in 1..upper

        trailing_number = j
        sum = 0
        i = 1

        while i <= trailing_number
          game_avg = games[game_num-i]
          sum+= game_avg
          i+=1
        end

        trailing_avg = sum/trailing_number
        difference = (games[game_num]-trailing_avg).abs
        differences[trailing_number].push(difference)
        #puts "#{trailing_number} game average: #{difference} p/m off"
        end
      end
    end
    haystack = []
    for d in 1..15
      sum=0
      num_of_avgs=0
      differences[d].each do |diff|
        if diff.class==Float
          #puts "#{d}: #{diff}"
          sum+=diff
          num_of_avgs+=1
        end
      end

      if num_of_avgs>0
        avg_avg = sum/num_of_avgs
        haystack.push(avg_avg)
        master_avgs_string << "#{avg_avg},"
      end
    end

    if haystack!=nil
      what_to_use = 0
      if haystack.index(haystack.min) != nil
        what_to_use = haystack.index(haystack.min)
      end
      #puts "#{name} - #{what_to_use+1}"
      how_many_games[name] = what_to_use+1
    end
  end
  return how_many_games
end



Dotenv.load

names = []
db = Mysql.new('127.0.0.1','root',ENV["SQL_PASSWORD"],'fanduel')

nm_results = db.query("SELECT name from oconnor where date = '#{Date.today}'")
nm_results.each do |nm_result|
  names << nm_result[0]
end

CSV.open("/Users/michael-orderup/SkyDrive/Project Mellon/lezhlie.csv", "w") do |csv|
  csv << ["name", "date", "opp", "mp", "fanduel_pts"]

what_day_to_use_hash = get_trailing_avg_day

count = 0
names.each do |name|
  sql_name = Mysql.escape_string(name)

  if what_day_to_use_hash.has_key?(name)
    #puts "#{name} - #{what_day_to_use_hash[name]}"
  end


  if what_day_to_use_hash.has_key?(name)
    count = what_day_to_use_hash[name]
  end

  if count >= 15
    sql = "SELECT name, date, opp, mp, fanduel_pts from oconnor where name ='#{sql_name}' and date < '#{Date.today}' and mp is not null order by date desc LIMIT 0,15"
    results = db.query(sql)
      results.each do |result|
        csv << ["#{result[0]}", "#{result[1]}", "#{result[2]}", "#{result[3]}", "#{result[4]}"]
      end
  end

  if (count < 15 && count > 0)
    sql = "SELECT name, date, opp, mp, fanduel_pts from oconnor where name ='#{sql_name}' and date < '#{Date.today}' and mp is not null order by date desc LIMIT 0,#{count}"
    results = db.query(sql)
      results.each do |result|
        csv << ["#{result[0]}", "#{result[1]}", "#{result[2]}", "#{result[3]}", "#{result[4]}"]
      end

    j = 15-count
    while j > 0 do
      csv << ["#{name}", "NULL", "NULL", "NULL", "NULL"]
      j-=1
    end
  end

  if count == 0
    for i in 0..14
      csv << ["#{name}", "NULL", "NULL", "NULL", "NULL"]
    end
  end
end
end
