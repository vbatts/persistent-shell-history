
module Persistent
  module Shell

    class AbstractHistoryStore
      SCHEMA_VERSION = "1"

      def commands; end
      def db; end
      def shema_match?; db.has_key? "schema_version" and db["schema_version"] == SCHEMA_VERSION; end
      def shema_version; db["schema_version"] if db.has_key? "schema_version" ; end
    end # class AbstractHistoryStore

  end
end

# vim: set sts=2 sw=2 et ai:
