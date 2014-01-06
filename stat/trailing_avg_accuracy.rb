require 'rubygems'
require 'mysql'
require 'date'
require 'csv'
require 'dotenv'

Dotenv.load

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

how_many_games.each do |nm, wtu|
  puts "#{nm} - #{wtu}"
end
