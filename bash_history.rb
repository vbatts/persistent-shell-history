#!/usr/bin/env ruby

require 'digest/md5'
require 'gdbm'
require 'yaml'

class BashHistory
  attr_reader :db
  OPTIONS = {
    :file => File.expand_path("~/.bash_history"),
    :archive_file => File.expand_path("~/.bash_history.db"),
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
  def commands; values.map {|v| v[:cmd] }; end
  def _yd(data); YAML.dump(data); end
  def _yl(data); YAML.load(data); end
  def _md5(data); Digest::MD5.hexdigest(data); end

  def find(pat)
    values.select {|v| v if v =~ /#{pat}/ }
  end

  def _parse
    open(@options[:file]) do |f|
      f.each_line do |line|
        if line =~ /^#(.*)$/
          l = f.readline.chomp
          db[_md5(l)] = _yd({:cmd => l, :time => Time.at($1.to_i)})
        else
          db[_md5(line.chomp)] = _yd({:cmd => line.chomp})
        end
      end
    end
  end
  def render(file)
    File.open(file,'w+') do |f|
      values.each do |v|
        f.write("#" + v[:time].to_i.to_s + "\n") if v[:time]
        f.write(v[:cmd] + "\n")
      end
    end
  end
end

if $0 == __FILE__
  bh = BashHistory.new
  p bh
  p "storing #{bh.keys.count} commands"
end

