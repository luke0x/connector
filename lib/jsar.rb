=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

# so-called 'javascript activerecord'

module JSAR
  def self.included(base)
    base.class_eval <<-EOF
      helper_method :tag_to_jsar
      helper_method :tagging_to_jsar
      helper_method :user_to_jsar
      helper_method :item_to_jsar
      helper_method :permission_to_jsar
      helper_method :notification_to_jsar
      helper_method :group_to_jsar
    EOF
  end

  private
  
    def tag_to_jsar(tag)
      return '' unless tag

      "Tag.create({
        domId: '#{tag.dom_id}',
        arId:  #{tag.id},
        name:  '#{escape_javascript(URI.encode(tag.name))}'
      });".gsub(/\s+/, ' ')
    end

    def tagging_to_jsar(tagging)
      return '' unless tagging

      "Tagging.create({
        domId:     '#{tagging.dom_id}',
        tagDomId:  '#{tagging.tag.dom_id}',
        itemDomId: '#{tagging.taggable.dom_id}',
        userDomId: '#{tagging.tagger.dom_id}'
      });".gsub(/\s+/, ' ')
    end

    def user_to_jsar(user, current, selected)
      return '' unless user

      "User.create({
        domId:       '#{user.dom_id}',
        arId:        #{user.id},
        personDomId: '#{user.person.dom_id}',
        username:    '#{user.username}',
        fullName:    '#{escape_javascript(URI.encode(user.full_name))}',
        sortName:    '#{escape_javascript(URI.encode("#{user.person.last_name} #{user.person.first_name} #{user.person.middle_name}"))}',
        current:     #{current},
        selected:    #{selected}
      });".gsub(/\s+/, ' ')
    end

    def item_to_jsar(item, selected, selected_group = nil)
      return '' unless item

      "Item.create({
        domId:             '#{item.dom_id}',
        arId:              '#{item.id || 'null'}',
        #{ ("path: '" + item.relative_path + "', ") if item.class == StrongspaceFile }
        arType:            '#{item.class == StubEvent ? Event : item.class}',
        userDomId:         #{"'" + item.owner.dom_id + "'" rescue 'null'},
        selected:          #{selected},
        canEdit:           #{User.current.can_edit?(item)},
        canCopy:           #{User.current.can_copy?(item)},
        canAdd:            #{User.current.can_add?(item)},
        canMove:           #{User.current.can_move?(item)},
        canDelete:         #{User.current.can_delete?(item)},
        canRemove:         #{User.current.can_delete_from?(selected_group)},
        mustConfirmDelete: #{User.current.must_confirm_delete?(item)}
      });".gsub(/\s+/, ' ')
    end

    def permission_to_jsar(permission)
      return '' unless permission

      "Permission.create({
        domId:     '#{permission.dom_id}',
        userDomId: '#{permission.user.dom_id}',
        itemDomId: '#{permission.item.dom_id}'
      });".gsub(/\s+/, ' ')
    end

    def notification_to_jsar(notification)
      return '' unless notification

      "Notification.create({
        domId:     '#{notification.dom_id}',
        userDomId: '#{notification.notifiee.dom_id}',
        itemDomId: '#{notification.item.dom_id}'
      });".gsub(/\s+/, ' ')
    end
    
    def group_to_jsar(group)
      return '' unless group
      users = group.respond_to?(:users) ? group.users : []
      js_users_array = users.map{|u| "'#{u.user.dom_id}'"}.join(',')
      
      "Group.create({
        domId:       '#{group.dom_id}',
        userDomId:   '#{group.owner.dom_id}',
        personDomId: '#{group.owner.person.dom_id}',
        name:        '#{escape_javascript(URI.encode(group.name))}',
        users:       [#{js_users_array}]
      });".gsub(/\s+/, ' ')
      
    end

    # taken from actionview
    def escape_javascript(javascript)
      (javascript || '').gsub(/\r\n|\n|\r/, "\\n").gsub(/["']/) { |m| "\\#{m}" }
    end

end