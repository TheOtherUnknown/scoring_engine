#!/usr/bin/env ruby
# frozen_string_literal: true

require 'sinatra'
require 'sqlite3'
Thread.new do
  get '/' do
    'Admin command response'
  end
end

Thread.new do
  db = SQLite3::Database.new 'serviceCheck.db'
end
