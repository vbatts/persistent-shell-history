#!/usr/bin/env ruby
# Encoding: UTF-8

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
  def time_format; @options[:time_format]; end
  def time_format=(tf); @options[:time_format] = tf; end
  def db
    @db ||= GDBM.new(@options[:archive_file])
  end
  def keys; db.keys; end
  def keys_to_i; keys.map {|i| i.to_i }; end
  def values; db.map {|k,v| _yl(v) }; end
  def values_by_time
    return db.map {|k,v|
      data = _yl(v)
      data[:time].map {|t|
        data.merge(:time => t)
      }
    }.flatten.sort_by {|x|
      x[:time]
    }
  end
  def commands; values.map {|v| v[:cmd] }; end
  def _yd(data); YAML.dump(data); end
  def _yl(data); YAML.load(data); end
  def _md5(data); Digest::MD5.hexdigest(data); end
  def _f(v); " %s %s" % [v[:time].strftime(@options[:time_format]), v[:cmd]]; end

  def _e(str, enc = "UTF-8"); str.respond_to?(:force_encoding) ? str.force_encoding(enc) : str; end

  def find(pat)
    return values.select {|v|
      v if _e(v[:cmd]) =~ /#{pat}/
    }.map {|v|
      v[:time].map {|t|
        v.merge(:time => t)
      }
    }.flatten
  end

  def _parse
    open(@options[:file]) do |f|
      f.each_line do |line|
        if _e(line) =~ /^#(.*)$/
          l = f.readline.chomp
          key = _md5(l)
          if db.has_key?(key)
            times = _yl(db[key])[:time]
            if times.kind_of? Array
              times.push(Time.at($1.to_i))
            else
              times = [times]
            end
            db[key] = _yd({:cmd => l, :time => times.uniq })
          else
            db[key] = _yd({:cmd => l, :time => [Time.at($1.to_i)] })
          end
        else
          key = _md5(line.chomp)
          if db.has_key?(key)
            times = _yl(db[key])[:time]
            if times.kind_of? Array
              times.push(Time.at($1.to_i))
            else
              times = [times]
            end
            db[key] = _yd({:cmd => l, :time => times.uniq })
          else
            db[key] = _yd({:cmd => line.chomp, :time => [Time.at(0)] })
          end
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

  bh = BashHistory.new(bh_options)

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
end

