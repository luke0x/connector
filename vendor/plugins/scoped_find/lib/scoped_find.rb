=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

module ScopedFind
  class EmptySet < StandardError; end

  def self.included(base)
    super
    base.extend(ClassMethods)
    base.class_eval do
      class << self
        alias_method_chain :find, :scope
        alias_method_chain :calculate, :scope
        def validate_find_options(options)
          options.assert_valid_keys(VALID_FIND_OPTIONS + [:scope])
        end
        def validate_calculation_options(operation, options = {})
          options.assert_valid_keys(ActiveRecord::Calculations::CALCULATIONS_OPTIONS + [:scope])
        end
      end
    end
  end

  module ClassMethods
    # org, access, rules
    def find_with_scope(*args)
      if a = args.detect{|a| a.is_a?(Hash)} and a.has_key?(:scope)
        org_scope = case a[:scope]
        when :org_read then Scopes.current_organization(self)
        else
          Scopes.identity_organizations(self)
        end

        user_scope = case a[:scope]
        when :org_read then Scopes.user(self, true)
        else
          Scopes.user(self, false)
        end

        access_scope = case a[:scope]
        when :read, :org_read then Scopes.read(self)
        when :edit            then Scopes.edit(self)
        when :copy            then Scopes.copy(self)
        when :move            then Scopes.move(self)
        when :delete          then Scopes.delete(self)
        when :confirm_delete  then Scopes.confirm_delete(self)
        when :create_on       then Scopes.create_on(self)   # needed?
        when :copy_from       then Scopes.copy_from(self)   # needed?
        when :move_from       then Scopes.move_from(self)   # needed?
        when :delete_from     then Scopes.delete_from(self) # needed?
        else
          raise 'unknown access scope'
        end

        self.with_scope(org_scope) do
          self.with_scope(user_scope) do
            self.with_scope(access_scope) do
              find_without_scope(*args)
            end
          end
        end
      else
        find_without_scope(*args)
      end
    rescue EmptySet
      []
    end
  
    def calculate_with_scope(*args)
      if a = args.detect{|a| a.is_a?(Hash)} and a.has_key?(:scope)
        org_scope    = Scopes.organization(self)
        user_scope   = Scopes.user(self, User.current)
        access_scope = case a[:scope]
        when :read           then Scopes.read(self)
        when :edit           then Scopes.edit(self)
        when :copy           then Scopes.copy(self)
        when :move           then Scopes.move(self)
        when :delete         then Scopes.delete(self)
        when :confirm_delete then Scopes.confirm_delete(self)
        when :create_on      then Scopes.create_on(self)   # needed?
        when :copy_from      then Scopes.copy_from(self)   # needed?
        when :move_from      then Scopes.move_from(self)   # needed?
        when :delete_from    then Scopes.delete_from(self) # needed?
        else
          raise 'unknown access scope'
        end

        self.with_scope(org_scope) do
          self.with_scope(user_scope) do
            self.with_scope(access_scope) do
              calculate_without_scope(*args)
            end
          end
        end
      else
        calculate_without_scope(*args)
      end
    rescue EmptySet
      0
    end
  end
end