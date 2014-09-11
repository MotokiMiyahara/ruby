# vim:set fileencoding=utf-8 ts=2 sw=2 sts=2 et:

require 'active_record'
require 'yaml'

require_relative '../config'

# DB接続設定
#ActiveRecord::Base.establish_connection(
#  adapter:  "mysql2",
#  host:     "localhost",
#  username: "root",
#  password: "xxxxxx",
#  database: "crawlers_development",
#)

config = YAML.load_file(Crawlers::Config.database_yml)
ActiveRecord::Base.establish_connection(config["development"])

if $0 == __FILE__
end

