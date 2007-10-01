=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class Calendar < ActiveRecord::Base
  include JoyentGroup

  validates_presence_of :name
  validates_uniqueness_of :name, :if => :name_used_at_tree_level
   
  # This is not a dependent association because many calendars can have the 
  # same event on it...remove_events deals with this
  has_many :events, :through => :invitations
  has_many :invitations

  acts_as_tree :order => 'LOWER(calendars.name)'

  before_destroy :remove_events

  # XXX WRONG
  def events_between(start_time, end_time)
    raise ArgumentError, "Start time is nil" if start_time.blank?
    raise ArgumentError, "End time is nil"   if end_time.blank?    

    events = self.events.find(:all, :include => [{:owner => :person}, :permissions, :notifications, :taggings], :scope => :read)
    events.collect{|e| e.occurrences_between(start_time, end_time)}.flatten.sort
  end

  # for the initial person, not subsequent invitations, they should be all through the invitation api
  def add_event(event)
    Invitation.create(:event_id=>event.id, :calendar_id=>self.id, :user_id=>owner.id, :pending => false, :accepted=>true)
  end

  # only for use with importing stuff.
  def add_and_save_events(events)
    Event.transaction do
      events.each do |event|   
        event.owner = owner
        event.organization = owner.organization
        event.save!
        add_event(event)  
      end
    end
  end

  # here because :through is lame^H readonly - TODO: is this still an issue?
  def event_find(id)
    return nil if invitations.empty?
    Event.find(:first, :include => [:invitations], :conditions => [ 'events.id = ? and invitations.id IN (?)', id, invitations.collect(&:id) ], :scope => :read)
  end

  def rename!(name)  
    update_attribute(:name, name)
  end

  # is this calendar a descendent of me?
  def descendent?(calendar)
    return false if calendar.blank?
    return false if children.blank?
    return true if children.include?(calendar)
    children.each do |child|
      return child.descendent?(calendar)
    end
  end

  def reparent!(new_parent)
    return if new_parent == self
    return if descendent?(new_parent)

    self.parent = new_parent
    self.save
  end

  def cascade_permissions
    users = permissions.collect(&:user)
    children.each {|c| c.restrict_to!(users)}
    events.each {|e| e.restrict_to!(users)}
  end
  
  private

    def remove_events
      events.each do |event|
        if event.owner == self.owner
          event.destroy
        else
          # If I have already accepted and removed the calendar...then what?
          # I am choosing to decline at this point, but this can be adjusted if we want
          invite = event.invitation_for(self.owner)
          invite.decline!    
        end    
      end
    end     

    def name_used_at_tree_level
      siblings = parent ? parent.children : owner.calendar_root_calendars rescue []
      siblings.reject{|c| c == self}.any?{|s| s.name == self.name}
    end
end