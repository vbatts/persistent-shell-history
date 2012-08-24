
require 'digest/md5'
module Persistent
  module Shell
    class Command < Struct.new(:cmd, :time)
      def md5
        Digest::MD5.hexdigest(cmd)
      end
      def to_h
        { :cmd => cmd, :time => time, }
      end
    end
  end
end

# vim: set sts=2 sw=2 et ai:
