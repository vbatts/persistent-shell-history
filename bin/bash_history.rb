#!/usr/bin/env ruby

require 'persistent-shell-history/binary-history-store'
require 'persistent-shell-history/old-history-store'
require 'optparse'

options = {}
bh_options = {:archive_file => File.expand_path("~/.bash_history.db")}
opts = OptionParser.new do |opts|
  opts.on('--inspect','inspect the data') do |o|
    options[:inspect] = o
  end
  opts.on('-h','--history FILE','use bash_history FILE instead of the default (~/.bash_history)') do |o|
    bh_options[:file] = o
  end
  opts.on('-d','--db FILE','use database FILE instead of the default (~/.bash_history.db)') do |o|
    bh_options[:archive_file] = o
  end
  opts.on('--migrate','check-for and migrate, only') do |o|
    options[:migrate] = o
  end
  opts.on('-l','--list','list history') do |o|
    options[:list] = o
  end
  opts.on('--format FORMAT','specify a different strftime format. (default is "%F %T")') do |o|
    bh_options[:time_format] = o
  end
  opts.on('-f','--find PAT','find a command with pattern PAT') do |o|
    options[:find] = o
  end
end

begin
  opts.parse!(ARGV)
rescue => ex
  puts ex
  puts opts
end

def migrate(old_bashhistorystore)
  require 'fileutils'
  # migrate
  temp_db = GDBM.new("#{old_bashhistorystore.archive}.#{$$}")
  old_bashhistorystore.keys.each {|key|
    h = old_bashhistorystore[key]
    h[:time] = h[:time].map {|t| t.to_i }
    temp_db[key] = Marshal.dump(h)
  }
  old_bashhistorystore.db.close()
  temp_db.close()
  ts = "#{Time.now.year}#{Time.now.month}#{Time.now.day}#{Time.now.hour}#{Time.now.min}"
  old_filename = "#{old_bashhistorystore.archive}.old.#{ts}"
  FileUtils.mv(old_bashhistorystore.archive, old_filename)
  puts "archived [#{old_bashhistorystore.archive}] to [#{old_filename}] ..."
  FileUtils.mv("#{old_bashhistorystore.archive}.#{$$}", old_bashhistorystore.archive)
end

# First check the database, for whether it is the old format,
# if so, convert it, and reopen it.
bh = Persistent::Shell::OldHistoryStore.new(bh_options)
migrate(bh) if bh.is_oldformat?
bh.db.close unless bh.db.closed?

exit(0) if options[:migrate]

# re-open the history storage
bh = Persistent::Shell::BinaryHistoryStore.new(bh_options)

# load the new bash_history into the database
unless (options[:inspect] or options[:find] or options[:list])
  bh.load()
  bh.db.reorganize()
end

if options[:inspect]
  p bh
  #p "storing #{bh.keys.count} commands"
end
if options[:find]
  bh.find(options[:find]).sort_by {|x| x[:time] }.each do |val|
    puts bh.fmt(val)
  end
elsif options[:list]
  bh.values_by_time.each do |val|
    puts bh.fmt(val)
  end
end

# vim: set sts=2 sw=2 et ai:
