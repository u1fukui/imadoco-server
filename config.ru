# coding:utf-8
require 'active_record'
require 'mysql2'
require 'sinatra'
require 'houston'
require './imadoco.rb'

enable :logging, :dump_errors

# データベース
ActiveRecord::Base.configurations = YAML.load_file('database.yml')
ActiveRecord::Base.establish_connection('development')
Time.zone = 'Tokyo'
ActiveRecord::Base.time_zone_aware_attributes = true
ActiveRecord::Base.default_timezone = :local

class User < ActiveRecord::Base
  has_many :maps
end

class Map < ActiveRecord::Base
  belongs_to :user
  has_many :notifications
end

class Notification < ActiveRecord::Base
  belongs_to :map
  belongs_to :user
end

# 実行
run ImadocoApp
