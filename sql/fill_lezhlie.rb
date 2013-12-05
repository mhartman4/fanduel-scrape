require 'rubygems'
require 'mysql'
require 'date'
require 'csv'
require 'dotenv'

Dotenv.load


names = []
db = Mysql.new('127.0.0.1','root',ENV["SQL_PASSWORD"],'fanduel')

nm_results = db.query("SELECT name from oconnor where date = '#{Date.today}'")
nm_results.each do |nm_result|
  names << nm_result[0]
end

CSV.open("lezhlie.csv", "w") do |csv|
  csv << ["name", "date", "opp", "mp", "fanduel_pts"]


names.each do |name|
  sql_name = Mysql.escape_string(name)
  count = nil
  count_results = db.query("SELECT count(*) from oconnor where name = '#{sql_name}' and date < '#{Date.today}' and mp is not null")
  count_results.each do |count_result|
    count = count_result[0].to_i
  end
  i = 1
  k = 1
  if count < 15
    sql = "SELECT name, date, opp, mp, fanduel_pts from oconnor where name ='#{sql_name}' and date < '#{Date.today}' and mp is not null order by date desc"
    results = db.query(sql)
      results.each do |result|
        #worksheet.write(, result[1])
        csv << ["#{result[0]}", "#{result[1]}", "#{result[2]}", "#{result[3]}", "#{result[4]}"]
        i+=1
      end
    j = 15-count
    while j > 0 do
      csv << ["#{name}", "NULL", "NULL", "NULL", "NULL"]
      j-=1
      i+=1
    end
  end

  if count >= 15
    sql = "SELECT name, date, opp, mp, fanduel_pts from oconnor where name ='#{sql_name}' and date < '#{Date.today}' and mp is not null order by date desc LIMIT 15"
    results = db.query(sql)
      results.each do |result|
        csv << ["#{result[0]}", "#{result[1]}", "#{result[2]}", "#{result[3]}", "#{result[4]}"]
        i+=1
      end
  end
end
  #end
=begin    j = count
    while j > 0 do
      sql = "SELECT date, name, opp, mp, fanduel_pts from oconnor where name ='John Wall' and date < '#{Date.today}' and mp is not null order by name"
      results = db.query(sql)
      results.each do |result|
        puts result[0]
      end
    end
=end

  #sql = "SELECT date, name, opp, mp, fanduel_pts from oconnor where name ='John Wall' and date < '#{Date.today}' and mp is not null order by name"

    #j+=1
  #end


#end csv
end




