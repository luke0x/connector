class ChangePeopleCacheSortSettings < ActiveRecord::Migration
  def self.up
    UserOption.find(:all, :conditions => ["user_options.key = 'People Sort Field' AND value = 'primary_email'"]).each do |user_option|
      user_option.update_attribute(:value, 'primary_email_cache')
    end
    UserOption.find(:all, :conditions => ["user_options.key = 'People Sort Field' AND value = 'primary_phone'"]).each do |user_option|
      user_option.update_attribute(:value, 'primary_email_cache')
    end
  end

  def self.down
    UserOption.find(:all, :conditions => ["user_options.key = 'People Sort Field' AND value = 'primary_email_cache'"]).each do |user_option|
      user_option.update_attribute(:value, 'primary_email')
    end
    UserOption.find(:all, :conditions => ["user_options.key = 'People Sort Field' AND value = 'primary_phone_cache'"]).each do |user_option|
      user_option.update_attribute(:value, 'primary_email')
    end
  end
end
