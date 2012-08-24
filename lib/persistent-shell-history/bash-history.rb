
require 'digest/md5'
require 'gdbm'
require 'yaml'

require 'persistent-shell-history/abstract-history-store'

module Persistent
  module Shell
    class HistoryStore < AbstractHistoryStore
      SCHEMA_VERSION = "1"
      OPTIONS = {
        :file          => File.expand_path("~/.bash_history"),
        :archive_file  => File.expand_path("~/.bash_history.db"),
        :time_format   => "%F %T",
      }
      def initialize(opts = {})
        @options = OPTIONS.merge(opts)
        _load if schema_match?
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
    
      def find(pat)
        return values.select {|v|
          v if v[:cmd] =~ /#{pat}/
        }.map {|v|
          v[:time].map {|t|
            v.merge(:time => t)
          }
        }.flatten
      end
    
      def _load(filename = @options[:file])
        #History.new(file).parse
        open(filename) do |f|
          f.each_line do |line|
            if line =~ /^#(.*)$/
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
    end # class DataStore
  end # module Shell
end # module Persistent

# vim: set sts=2 sw=2 et ai:
