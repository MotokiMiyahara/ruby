# vim:set fileencoding=utf-8 ts=2 sw=2 sts=2 et:

require "active_record"

# DB接続設定
ActiveRecord::Base.establish_connection(
  adapter:  "mysql2",
  host:     "localhost",
  username: "root",
  password: "admin99",
  database: "crawlers_development",
)


if $0 == __FILE__
end

