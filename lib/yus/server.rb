#!/usr/bin/env ruby
# Server -- yus -- 31.05.2006 -- hwyss@ywesee.com

require 'drb'
require 'yus/entity'
require 'yus/session'
require 'logger'

VERSION = '1.0.1'

module Yus
  class Server
    attr_accessor :persistence, :config, :logger
    def initialize(persistence, config, logger= Logger.new)
      @persistence = persistence
      @config = config
      @logger = logger
      @sessions = []
      @needle = nil
      run_cleaner
    end
    def autosession(domain, &block)
      session = AutoSession.new(@needle, domain)
      block.call(session)
    end
    def login(name, password, domain)
      @logger.info(self.class) { 
        sprintf('Login attempt for %s from %s', name, domain)
      }
      hash = @config.digest.hexdigest(password.to_s)
      session = login_root(name, hash, domain) \
        || login_entity(name, hash, domain) # raises YusError
      @sessions.push(session)
      session
    end
    def login_token(name, token, domain)
      entity = authenticate_token(name, token)
      entity.login(domain)
      @persistence.save_entity(entity)
      entity.get_preference("session_timeout", domain) \
        || @config.session_timeout
      TokenSession.new(@needle, entity, domain)
    end
    def logout(session)
      @logger.info(self.class) { 
        sprintf('Logout for %s', session)
      }
      @sessions.delete(session)
      if(session.respond_to?(:destroy!))
        session.destroy! 
      end
    end
    def ping
      true
    end
    private
    def authenticate(name, passhash)
      user = @persistence.find_entity(name) \
        or raise UnknownEntityError, "Unknown Entity '#{name}'"
      user.authenticate(passhash) \
        or raise AuthenticationError, "Wrong password"
      @logger.info(self.class) { 
        sprintf('Authentication succeeded for %s', name)
      }
      user
    rescue YusError
      @logger.warn(self.class) { 
        sprintf('Authentication failed for %s', name)
      }
      raise
    end
    def authenticate_token(name, token)
      user = @persistence.find_entity(name) \
        or raise UnknownEntityError, "Unknown Entity '#{name}'"
      user.authenticate_token(token) \
        or raise AuthenticationError, "Wrong token or token expired"
      @logger.info(self.class) { 
        sprintf('Token-Authentication succeeded for %s', name)
      }
      user
    rescue YusError
      @persistence.save_entity(user) if user
      @logger.warn(self.class) { 
        sprintf('Token-Authentication failed for %s', name)
      }
      raise
    end
    def clean
      @sessions.delete_if { |session| session.expired? }
    end
    def login_entity(name, passhash, domain)
      entity = authenticate(name, passhash)
      entity.login(domain)
      @persistence.save_entity(entity)
      entity.get_preference("session_timeout", domain) \
        || @config.session_timeout
      EntitySession.new(@needle, entity, domain)
    end
    def login_root(name, passhash, domain)
      if(name == @config.root_name \
         && passhash == @config.root_pass)
        @logger.info(self.class) { 
          sprintf('Authentication succeeded for root: %s', name)
        }
        RootSession.new(@needle)
      end
    end
    def run_cleaner
      @cleaner = Thread.new {
        loop {
          sleep(@config.cleaner_interval)          
          clean 
        }
      }
    end
  end
end
