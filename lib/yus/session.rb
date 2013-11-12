#!/usr/bin/env ruby
# Session -- yus -- 02.06.2006 -- hwyss@ywesee.com

require 'drb'
require 'thread'
require 'yus/entity'
require 'pp'
begin 
  require 'encoding/character/utf-8'
rescue LoadError
end


module Yus
  class Session
    include DRb::DRbUndumped
    attr_accessor :persistence
    Config = Struct.new("Config", :session_timeout, :digest, :token_lifetime, :root_name)    #=> Struct::Config
    def initialize(needle)
      @needle = needle
      if needle and needle.config
        @config =  needle.config
        @timeout = needle.config.session_timeout
        @persistence = needle.persistence
      else
        @config  = Config.new(60, 1, 3, 'dummy_root_name')
        @timeout = 0.1
        @persistence = nil
      end
      @mutex = Mutex.new
      @logger = nil
      touch!
    end
    
    def affiliate(name, groupname)
      info("affiliate(name=#{name}, group=#{groupname})")
      @mutex.synchronize { 
        allow_or_fail('edit', 'yus.entities')
        user = find_or_fail(name)
        group = find_or_fail(groupname)
        user.join(group)
        save(user, group)
      }
      touch!
    end
    def create_entity(name, valid_until=nil, valid_from=Time.now)
      info("create_entity(name=#{name}, valid_until=#{valid_until}, valid_from=#{valid_from})")
      entity = nil
      @mutex.synchronize { 
        allow_or_fail('edit', 'yus.entities')
        if(@persistence.find_entity(name))
          debug("create_entity: Duplicate Name: '#{name}'")
          raise DuplicateNameError, "Duplicate name: #{name}"
        end
        entity = Entity.new(name, valid_until, valid_from)
        entity.grant('set_password', name)
        @persistence.add_entity(entity)
      }
      touch!
      entity
    end
    def delete_entity(name)
      info("delete_entity(name=#{name})")
      allow_or_fail 'edit', 'yus.entities'
      find_or_fail name
      @persistence.delete_entity name
      touch!
    end
    def destroy!
      @persistence = @needle = @user = nil
      @timeout = -1
    end
    def disaffiliate(name, groupname)
      info("disaffiliate(name=#{name}, group=#{groupname})")
      @mutex.synchronize { 
        allow_or_fail('edit', 'yus.entities')
        user = find_or_fail(name)
        group = find_or_fail(groupname)
        save(user, group)
      }
      touch!
    end
    def expired?
      Time.now > (@last_access + @timeout)
    end
    def entities
      allow_or_fail('edit', 'yus.entities')
      touch!
      @persistence.entities
    end
    def find_entity(name)
      allow_or_fail('edit', 'yus.entities')
      touch!
      @persistence.find_entity(name)
    end
    def grant(name, action, item=nil, expires=nil)
      info("grant(name=#{name}, action=#{action}, item=#{item}, expires=#{expires})")
      @mutex.synchronize { 
        allow_or_fail('grant', action)
        user = find_or_fail(name)
        user.grant(action, item || :everything, expires || :never)
        save(user)
      }
      touch!
    end
    def last_login(name, domain=@domain)
      if(user = find_entity(name))
        user.last_login(domain)
      end
    end
    def remove_token(token)
      @user.remove_token token
      save @user
      nil
    end
    def rename(oldname, newname)
      info("rename(#{oldname}, #{newname})")
      @mutex.synchronize { 
        allow_or_fail('edit', 'yus.entities')
        user = find_or_fail(oldname)
        if((other = @persistence.find_entity(newname)) && other != user)
          raise DuplicateNameError, "Duplicate name: #{newname}"
        end
        user.revoke('set_password', oldname)
        user.rename(newname)
        user.grant('set_password', newname)
        save(user)
      }
    end
    def revoke(name, action, item=nil, time=nil)
      info("revoke(name=#{name}, action=#{action}, item=#{item}, time=#{time})")
      @mutex.synchronize {
        allow_or_fail('grant', action)
        user = find_or_fail(name)
        user.revoke(action, item || :everything, time)
        save(user)
      }
      touch!
    end
    def set_password(name, pass)
      @mutex.synchronize {
        allow_or_fail('set_password', name)
        user = find_or_fail(name)
        user.passhash = @config.digest.hexdigest(pass) if @config
        save(user)
      }
      touch!
    end
    def set_entity_preference(name, key, value, domain=@domain)
      debug("set_entity_preference(name=#{name}, key=#{key}, value=#{value}, domain=#{domain})")
      @mutex.synchronize {
        allow_or_fail('edit', 'yus.entities')
        user = find_or_fail(name)
        user.set_preference(key, value, domain)
        save(user)
      }
      touch!
    end
    private
    def allow_or_fail(action, item)
      unless(allowed?(action, item))
        raise NotPrivilegedError, "You are not privileged to #{action} #{item}"
      end
    end
    def debug(message)
      @logger.debug(self.class) { message } if @logger
    end
    def find_or_fail(name='none')
      raise UnknownEntityError, "Unknown Entity '#{name}'" unless @persistence
      @persistence.find_entity(name) or raise UnknownEntityError, "Unknown Entity '#{name}'"
    end
    def info(message)
      @logger.info(self.class) { message } if @logger
    end
    def save(*args)
      args.each { |entity|
        @persistence.save_entity(entity)
      }
    end
    def touch!
      @last_access = Time.now
    end
  end
  
  class AutoSession < Session
    def initialize(needle, domain)
      @domain = domain
      super(needle)
    end
    def allowed?(*args)
      false
    end
    def create_entity(name, pass=nil, valid_until=nil, valid_from=Time.now)
      info("create_entity(name=#{name}, valid_until=#{valid_until}, valid_from=#{valid_from})")
      entity = nil
      @mutex.synchronize { 
        if(@persistence.find_entity(name))
          debug("create_entity: Duplicate Name: '#{name}'")
          raise DuplicateNameError, "Duplicate name: #{name}"
        end
        entity = Entity.new(name, valid_until, valid_from)
        entity.grant('set_password', name)
        if(pass and @config)
          entity.passhash = @config.digest.hexdigest(pass)
        end
        @persistence.add_entity(entity)
      }
      touch!
    end
    def entity_allowed?(name, *args)
      find_or_fail(name).allowed?(*args)
    end
    def get_entity_preference(name, key, domain=@domain)
      debug("get_entity_preference(name=#{name}, key=#{key}, domain=#{domain})")
      @mutex.synchronize { 
        user = find_or_fail(name)
        user.get_preference(key, domain)
      }
    end
    def get_entity_preferences(name, keys, domain=@domain)
      debug("get_entity_preferences(name=#{name}, keys=#{keys}, domain=#{domain})")
      @mutex.synchronize { 
        user = find_or_fail(name)
        keys.inject({}) { |memo, key|
          memo.store(key, user.get_preference(key, domain))
          memo
        }
      }
    end
    def rename(oldname, newname)
      info("rename(#{oldname}, #{newname})")
      @mutex.synchronize { 
        user = find_or_fail(oldname)
        if((other = @persistence.find_entity(newname)) && other != user)
          raise DuplicateNameError, "Duplicate name: #{newname}"
        end
        user.revoke('set_password', oldname)
        user.rename(newname)
        user.grant('set_password', newname)
        save(user)
      }
    end
    def reset_entity_password(name, token, password)
      info("reset_entity_password(name=#{name}, token=#{token})")
      @mutex.synchronize {
        user = find_or_fail(name)
        unless(user.allowed?('reset_password', token))
          raise NotPrivilegedError, "You are not privileged to reset #{name}'s password"
        end
        user.passhash = @config.digest.hexdigest(password) if @config
        user.revoke('reset_password', token)
        save(user)
      }
      touch!
    end
    def set_entity_preference(name, key, value, domain=@domain)
      debug("set_entity_preference(name=#{name}, key=#{key}, value=#{value}, domain=#{domain})")
      @mutex.synchronize {
        user = find_or_fail(name)
        unless(user.get_preference(key, domain))
          user.set_preference(key, value, domain)
          save(user)
        end
      }
      touch!
    end
    def grant(name, action, item=nil, expires=nil)
      info("grant(name=#{name}, action=#{action}, item=#{item}, expires=#{expires})")
      @mutex.synchronize { 
        user = find_or_fail(name)
        user.grant(action, item || :everything, expires || :never)
        save(user)
      }
      touch!
    end
  end
  class EntitySession < Session
    def initialize(needle, user, domain)
      @user = user
      @domain = domain
      super(needle)
    end
    def allowed?(*args)
      debug("allowed?(#{args.join(', ')})")
      @user.allowed?(*args)
    end
    def name
      @user.name
    end
    def generate_token
      token = @config.digest.hexdigest(rand(2**128).to_s)
      expires = Time.now + @config.token_lifetime.to_i * 24*60*60
      @user.set_token token, expires
      save @user
      token
    end
    def get_preference(key)
      @user.get_preference(key, @domain)
    end
    def ping
      true
    end
    def set_preference(key, value)
      debug("set_preference(#{key}, #{value})")
      @user.set_preference(key, value, @domain)
      save(@user)
      touch!
    end
    def set_preferences(hash)
      debug("set_preferences(#{hash.inspect}")
      hash.each { |key, value|
        @user.set_preference(key, value, @domain)
      }
      save(@user)
      touch!
    end
    def valid?
      @user.valid?
    end
  end
  class TokenSession < EntitySession
    def allowed?(*args)
      key, arg, = args
      if key == 'set_password' || ( key == 'edit' && arg == 'yus.entities' )
        false
      else
        super
      end
    end
  end
  class RootSession < Session
    def allowed?(*args)
      true
    end
    def name
      @config.root_name if @config
    end
    def show(name, recursive=false)
      find_or_fail(name).info(recursive).pretty_inspect
    end
    def valid?
      true
    end    
  end
end
