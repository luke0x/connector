class UpdateMessageDatesOnDisk < ActiveRecord::Migration
  def self.up
    max_id     = Message.maximum(:id)
    group_size = 100
    
    ((max_id / group_size) + 1).times do |iteration|
      start_id = iteration * group_size
      end_id   = start_id  + group_size
                                                                           
      messages = Message.find(:all, :conditions => ["id >= ? AND id < ?", start_id, end_id])

      messages.each{|message| message.update_time! rescue nil}
    end
  end

  def self.down
  end
end
