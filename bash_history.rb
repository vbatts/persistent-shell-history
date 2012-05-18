#!/usr/bin/env ruby

require 'digest/md5'
require 'gdbm'
require 'yaml'

class BashHistory
  attr_reader :db
  OPTIONS = {
    :file          => File.expand_path("~/.bash_history"),
    :archive_file  => File.expand_path("~/.bash_history.db"),
    :time_format   => "%F %T",
  }
  def initialize(opts = {})
    @options = OPTIONS.merge(opts)
    _parse
  end
  def db
    @db ||= GDBM.new(@options[:archive_file])
  end
  def keys; db.keys; end
  def keys_to_i; keys.map {|i| i.to_i }; end
  def values; db.map {|k,v| _yl(v) }; end
  def values_by_time; db.map {|k,v| _yl(v) }.sort_by {|x| x[:time] } ; end
  def commands; values.map {|v| v[:cmd] }; end
  def _yd(data); YAML.dump(data); end
  def _yl(data); YAML.load(data); end
  def _md5(data); Digest::MD5.hexdigest(data); end
  def _f(v); " %s %s" % [v[:time].strftime(@options[:time_format]), v[:cmd]]; end

  def find(pat)
    values.select {|v| v if v[:cmd] =~ /#{pat}/ }
  end

  def _parse
    open(@options[:file]) do |f|
      f.each_line do |line|
        if line =~ /^#(.*)$/
          l = f.readline.chomp
          db[_md5(l)] = _yd({:cmd => l, :time => Time.at($1.to_i)})
        else
          db[_md5(line.chomp)] = _yd({:cmd => line.chomp, :time => Time.at(0) })
        end
      end
    end
  end
  def render(file)
    File.open(file,'w+') do |f|
      values.each do |v|
        f.write("#" + v[:time].to_i.to_s + "\n") if v[:time] and not (v[:time].to_i == 0)
        f.write(v[:cmd] + "\n")
      end
    end
  end
end

if $0 == __FILE__
  require 'optparse'
  options = {}
  OptionParser.new do |opts|
    opts.on('--inspect','inspect the data') do |o|
      options[:inspect] = o
    end
    opts.on('-l','--list','list history') do |o|
      options[:list] = o
    end
    opts.on('--fix','fix times') do |o|
      options[:fix] = o
    end
    opts.on('-f','--find PAT','find a command with pattern PAT') do |o|
      options[:find] = o
    end
  end.parse!(ARGV)

  bh = BashHistory.new
  if options[:inspect]
    p bh
    p "storing #{bh.keys.count} commands"
  end
  if options[:fix]
    count = 0
    bh.db.each_pair do |k,v|
      yv = bh._yl(v)
      if yv[:time].nil?
        yv[:time] = Time.at(0)
        bh.db[k] = bh._yd(yv)
        count += 1
      end
    end
    puts "fixed [#{count}] times values"
  end
  if options[:find]
    bh.find(options[:find]).sort_by {|x| x[:time]}.each do |val|
      puts bh._f(val)
    end
  elsif options[:list]
    bh.values_by_time.each do |val|
      puts bh._f(val)
    end
  end
end

