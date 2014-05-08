class AlterApnNotifications < ActiveRecord::Migration # :nodoc:
  
  module Apn # :nodoc:
    class Notification < ActiveRecord::Base # :nodoc:
      self.table_name = "apn_notifications"
    end
  end
  
  def self.up
    unless Apn::Notification.column_names.include?("custom_properties")
      add_column :apn_notifications, :custom_properties, :text
    end
  end

  def self.down
    if Apn::Notification.column_names.include?("custom_properties")
      remove_column :apn_notifications, :custom_properties
    end
  end
  
end