require 'hashie'
require 'tiny_tds'
require 'active_support/all'

class MsSQLClient
  def self.connection
    uri = ENV["MSSQL_DB_URL"]
    raise "MSSQL_DB_URL not set" if uri.blank?
    uri = URI(uri)

    @connection ||= TinyTds::Client.new(
      :username => uri.user,
      :password => uri.password,
      :host =>     uri.host,
      :database => uri.path[1..-1]
    )

  end

  def self.execute(sql)
    connection.execute(sql).map do |row|
      row.inject(Hashie::Mash.new) { |mash, (k, v)| mash[k.underscore] = v; mash }
    end
  end
end
