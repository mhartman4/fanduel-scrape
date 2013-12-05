require 'mysql'
require 'dotenv'

Dotenv.load

db = Mysql.new('127.0.0.1','root',ENV["SQL_PASSWORD"],'fanduel')

results = db.query("SELECT * FROM OCONNOR")
results.each do |result|
  puts result[0]
end
