=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class OnlyOneInvitation < ActiveRecord::Migration
  def self.up
    Event.find(:all).each do |event|
      # If we have duplicates, we want to remove the one that has not been responded to if there is one
      invites_per_person = {}
      event.invitations.each do |invite|
        invites_per_person[invite.user.id] = [] unless invites_per_person[invite.user.id]
        invites_per_person[invite.user.id] << invite
      end                                           
      
      invites_per_person.each_pair do |user_id, invites|                               
        if invites.size > 1                                                            
          # Just easier to deal with if the one we keep is sorted to the front
          invites.sort do |a, b| 
            if !a.pending?
              -1
            elsif !b.pending?
              1
            else
              0
            end
          end
          # Delete all after the first one
          (1...invites.size).each do |i|
            invites[i].destroy  
          end  
        end    
      end
    end
  end

  def self.down
  end
end
