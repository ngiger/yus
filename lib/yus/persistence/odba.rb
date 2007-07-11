#!/usr/bin/env ruby
# Persistence::ODBA -- yus -- 31.05.2006 -- hwyss@ywesee.com

require 'odba'
require 'odba/drbwrapper'
require 'yus/entity'
require 'yus/server'
require 'yus/session'

module Yus
  module Persistence
    class Odba
      def initialize
        @entities = ODBA.cache.fetch_named('entities', self) { Hash.new }
      end
      def add_entity(entity)
        @entities.store(Entity.sanitize(entity.name), entity)
        entity.odba_store
        @entities.odba_store
        entity
      end
      def entities
        @entities.values
      end
      def find_entity(name)
        @entities[Entity.sanitize(name)]
      end
      def save_entity(entity)
        if(@entities[entity.name])
          entity.odba_store
        else
          @entities.delete_if { |name, ent| ent.name == entity.name }
          add_entity(entity)
        end
      end
    end
  end
  class Entity
    include ODBA::Persistable
    ODBA_SERIALIZABLE = ['@last_logins', '@privileges', '@preferences']
    alias :odba_join :join
    alias :odba_leave :leave
    def join(entity)
      res = odba_join(entity)
      @affiliations.odba_store
      res
    end
    def leave(entity)
      res = odba_leave(entity)
      @affiliations.odba_store
      res
    end
  end
end
