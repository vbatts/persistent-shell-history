
require 'digest/md5'
require 'json'

module Persistent
  module Shell
    class Command < Struct.new(:cmd, :time)
      def md5
        Digest::MD5.hexdigest(cmd)
      end
      def to_h
        { :cmd => cmd, :time => time, }
      end
      def to_json(*a)
        to_h.to_json(*a)
      end
    end
  end
end

# vim: set sts=2 sw=2 et ai:
