
require 'persistent-shell-history/command'

module Persistent
  module Shell
    class History
      def initialize(filename = '~/.bash_history')
        @filename = File.expand_path(filename)
      end
      def file; @filename; end
      def file=(filename); @filename = File.expand_path(filename); end
      def commands
        @cmds ||= parse
      end
      def parse(filename = @filename)
        cmds = Array.new
        open(filename) do |f|
          f.each_line do |line|
            if line =~ /^#(.*)$/
              l = f.readline.chomp
              cmds << Command.new(l, $1)
            else
              cmds << Command.new(line, "0")
            end
          end
        end
        return cmds
      end
    end
  end
end

# vim: set sts=2 sw=2 et ai:
