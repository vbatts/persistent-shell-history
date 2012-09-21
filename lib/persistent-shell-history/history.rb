
require 'persistent-shell-history/command'
require 'json'

module Persistent
  module Shell
    # Abstract storage for command history
    class History
      def initialize()
        @cmds = Array.new
      end
      def commands; @cmds; end
      def commands=(cmds); @cmds = cmds; end
      def <<(arg); @cmds << arg; end
      def to_a; commands.map {|c| c.to_h }; end
      def to_json(*a); commands.to_json(*a); end
    end
    class BashHistory < History
      def initialize(filename = '~/.bash_history')
        @filename = File.expand_path(filename)
      end
      def commands; (@cmds.nil? or @cmds.empty?) ? (@cmds = parse) : @cmds; end
      def file; @filename; end
      def file=(filename); @filename = File.expand_path(filename); end
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
