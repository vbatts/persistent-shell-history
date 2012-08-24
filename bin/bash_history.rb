#!/usr/bin/env ruby

require 'persistent-shell-history/bash-history'
require 'optparse'

options = {}
bh_options = {}
OptionParser.new do |opts|
  opts.on('--inspect','inspect the data') do |o|
    options[:inspect] = o
  end
  opts.on('-h','--history FILE','use bash_history FILE instead of the default (~/.bash_history)') do |o|
    bh_options[:file] = o
  end
  opts.on('-d','--db FILE','use database FILE instead of the default (~/.bash_history.db)') do |o|
    bh_options[:archive_file] = o
  end
  opts.on('-l','--list','list history') do |o|
    options[:list] = o
  end
  opts.on('--fix','fix times') do |o|
    options[:fix] = o
  end
  opts.on('--format FORMAT','specify a different strftime format. (default is "%F %T")') do |o|
    bh_options[:time_format] = o
  end
  opts.on('-f','--find PAT','find a command with pattern PAT') do |o|
    options[:find] = o
  end
end.parse!(ARGV)

bh = Persistent::Shell::DataStore.new(bh_options)

if options[:inspect]
  p bh
  p "storing #{bh.keys.count} commands"
end
if options[:fix]
  count = 0
  bh.db.each_pair do |k,v|
    yv = bh._yl(v)
    if yv[:time].nil?
      yv[:time] = [Time.at(0)]
      bh.db[k] = bh._yd(yv)
      count += 1
    elsif not yv[:time].kind_of? Array
      yv[:time] = [yv[:time]]
      bh.db[k] = bh._yd(yv)
      count += 1
    end
  end
  puts "fixed [#{count}] times values"
end
if options[:find]
  bh.find(options[:find]).sort_by {|x| x[:time] }.each do |val|
    puts bh._f(val)
  end
elsif options[:list]
  bh.values_by_time.each do |val|
    puts bh._f(val)
  end
end

# vim: set sts=2 sw=2 et ai:
