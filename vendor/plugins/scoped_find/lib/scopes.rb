=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

# remember: {} means 'no further conditions'

module Scopes
  class << self
    class EmptySet < StandardError; end

    # org

    def current_organization(ar_class)
      # limit to orgs of user's identities
      organization_id = User.current.organization_id
      
      case ar_class.to_s
      when 'User', 'Report'
        {:find =>
          {:conditions => ['organizations.id = ?', organization_id],
           :include => [:organization]}
        }
      when 'Comment'
        {:find =>
          {:conditions => ['organizations.id = ?', organization_id],
           :include => [{:user => :organization}]}
        }
      when 'Notification'
        {}
      else
        {:find =>
          {:conditions => ['organizations.id = ?', organization_id],
           :include => [{:owner => :organization}]}
        }
      end
    end

    def identity_organizations(ar_class)
      # limit to orgs of user's identities
      organization_ids = User.current.identity.users.map(&:organization).map(&:id).uniq
      
      case ar_class.to_s
      when 'User', 'Report'
        {:find =>
          {:conditions => ['organizations.id IN (?)', organization_ids],
           :include => [:organization]}
        }
      when 'Comment'
        {:find =>
          {:conditions => ['organizations.id IN (?)', organization_ids],
           :include => [{:user => :organization}]}
        }
      when 'Notification'
        {}
      else
        {:find =>
          {:conditions => ['organizations.id IN (?)', organization_ids],
           :include => [{:owner => :organization}]}
        }
      end
    end

    # user

    def user(ar_class, org_scoped)
      if User.current.guest?
        case ar_class.to_s
        when 'User'
          # self only
          {:find =>
            {:conditions => ['users.id = ?', User.current.id]}
          }
        when 'Person'
          # self only
          {:find =>
            {:conditions => ['people.id = ?', User.current.person.id]}
          }
        when 'SFTPFolder', 'SFTPFile'
          {:find =>
            {:conditions => ['permissions.user_id = ?', User.current.id],
             :include    => [:owner, :hax_permissions]} # TODO: does this blow away the :owner => :org ?
          }
        else
          # nothing
          raise EmptySet
        end
      else
        # normal users and admins
        case ar_class.to_s
        when 'User', 'SmartGroup', 'Comment', 'Notification', 'Report'
          {}
        else
          if org_scoped
            {:find =>
              {:conditions => ['permissions.user_id IS NULL OR permissions.user_id = ?', User.current.id],
               :include    => [:owner, :hax_permissions]} # TODO: does this blow away the :owner => :org ?
            }
          # limit to any of the user's identity's users
          else
            user_ids = User.current.identity.users.map(&:id)
            {:find =>
              {:conditions => ['permissions.user_id IS NULL OR permissions.user_id IN (?)', user_ids],
               :include    => [:owner, :hax_permissions]} # TODO: does this blow away the :owner => :org ?
            }
          end
        end
      end
    end

    # access

    def read(ar_class)
      {}
    end

    def edit(ar_class)
      case ar_class.to_s
      when 'Person'
        if User.current.admin?
          # contacts i own, all users
          {:find =>
            {:conditions => ['users.id = ? OR users_people.id IS NOT NULL', User.current.id],
             :include    => [:owner, :user]}
          }
        else
          # contacts i own, my user contact
          {:find =>
            {:conditions => ['users.id = ? OR users_people.id = ?', User.current.id, User.current.id],
             :include    => [:owner, :user]}
          }
        end
      when 'Comment'
        {:find =>
          {:conditions => ['users.id = ?', User.current.id],
           :include    => [:user]}
        }
      when 'Notification'
        {:find =>
          {:conditions => ['notifications.notifiee_id = ?', User.current.id]}
        }
      else
        owns
      end
    end

    def copy(ar_class)
      {} # no extra rules
    end

    def move(ar_class)
      case ar_class.to_s
      when 'Event'
        # invitation for current user + is attached to a calendar
        {:find =>
          {:conditions => ['invitations.user_id = ? AND calendars.id IS NOT NULL', User.current.id],
           :include    => [{:invitations => :calendar}]}
        }
      when 'Person', 'Bookmark'
        raise EmptySet
      else
        owns
      end
    end

    # things i can potentially delete
    def delete(ar_class)
      case ar_class.to_s
      when 'Person'
        if User.current.admin?
          # contacts i own, users that aren't me
          {:find =>
            {:conditions => ['users.id = ? OR (users_people.id IS NOT NULL AND users_people.id <> ?)', User.current.id, User.current.id],
             :include    => [:owner, :user]}
          }
        else
          owns
        end
      else
        owns
      end
    end

    # things that need a confirmation to delete
    # TODO: is this the most useful thing for this to return?
    def confirm_delete(ar_class)
      case ar_class.to_s
      when 'Person'
        # non-you users only
        {:find =>
          {:conditions => ['(users_people.id IS NOT NULL AND users_people.id <> ?)', User.current.id],
           :include    => [:user]}
        }
      else
        raise EmptySet
      end
    end

    # do these?

    def create_on(ar_class)
      owns
    end

    def copy_from(ar_class)
      {}
    end

    def move_from(ar_class)
      owns
    end

    def delete_from(ar_class)
      owns
    end

    # helpers

    def owns
      {:find =>
        {:conditions => ['users.id = ?', User.current.id],
         :include    => [:owner]}
      }
    end

  end
end