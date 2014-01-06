require 'rubygems'
require 'mysql'
require 'date'
require 'csv'
require 'dotenv'
require 'spreadsheet'

Dotenv.load

#what column is the mellon projection in?
column_num = 12

book = Spreadsheet.open('/Users/michael-orderup/SkyDrive/Project Mellon/Mellon.xls')

names = []
playerpool = book.worksheet("Today's Player Pool")
projections = book.worksheet("Projections")

for i in 1..playerpool.count-1
  if playerpool[i,1].value!="NULL"
    names << playerpool[i,1].value
  end
end

db = Mysql.new('127.0.0.1','root',ENV["SQL_PASSWORD"],'fanduel')

for j in 1..projections.count-1
  if names.index(projections[j,1])!=nil
    temp_name = projections[j,1]
    mellon_proj = projections[j,column_num].value
    sql_name = Mysql.escape_string(temp_name)
    sql = "UPDATE oconnor SET mellon='#{mellon_proj}' WHERE name='#{sql_name}' and date='#{Date.today}';"
    #puts "#{projections[j,1]} - #{projections[j,12].value}"
    if mellon_proj!="NULL"
      #puts sql
      db.query(sql)
    end
  end
end








=begin
sheet1 = book.worksheet('Mellon') # can use an index or worksheet name

db = Mysql.new('127.0.0.1','root',ENV["SQL_PASSWORD"],'fanduel')

for i in 1..sheet1.count-1
  if (sheet1[i,0].value!="NULL") && (sheet1[i,1].value!="NULL")
    name = sheet1[i,0].value
    mellon_proj = sheet1[i,1].value
    sql_name = Mysql.escape_string(name)

    #sql = "UPDATE oconnor SET mellon='#{mellon_proj}' WHERE name='#{sql_name}' and date='#{Date.today}';"
    #puts sql
    #db.query(sql)
  end
end
=end
