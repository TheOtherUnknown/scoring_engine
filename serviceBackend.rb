#!/usr/bin/env ruby
# frozen_string_literal: true

require 'sinatra'
require 'sqlite3'
SCRIPTS_DIR = '/etc/scoring_engine/scripts/' # Change me!

flag = true
Thread.new do
  get '/shutdown' do
    flag = false
    exit
  end
end

Thread.new do
  db = SQLite3::Database.new 'serviceCheck.db'
  # Create the table and clear it out
  db.exec 'CREATE TABLE IF NOT EXISTS services (srvid INT PRIMARY KEY, status INT DEFAULT 2, lastcheck date)'
  db.exec 'DELETE FROM services'
  # Get all checking scripts. status 0 is up, 1 is down, 2 is error
  scripts = Dir.new SCRIPTS_DIR.children
  addcheck = db.prepare 'INSERT INTO services (srvid, status) values (?, 2)'
  setcheck = db.prepare 'UPDATE services set status=?, lastcheck=? where id=?'
  # Add a row to represent each script
  scripts.each do |file|
    addcheck.exec file.to_s[0, 1].to_i # First char of filename should be service id, must be unique
  end
  while flag
    scripts.each do |script|
      system "bash #{script.path}"
      # Ensure exit codes other than 0 or 1 get inserted into db as error code 2
      if ($CHILD_STATUS.exitstatus > 1) || $CHILD_STATUS.exitstatus.negative?
        setcheck.exec 2, Time.now, script.to_s[0, 1]
      else
        setcheck.exec $CHILD_STATUS.exitstatus, Time.now, script.to_s[0, 1]
      end
    end
    sleep 10
  end
end
