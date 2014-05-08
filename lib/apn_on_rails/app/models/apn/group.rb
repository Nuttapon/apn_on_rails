class Apn::Group < Apn::Base
  
  belongs_to :app, :class_name => 'Apn::App'
  has_many   :device_groupings, :class_name => "Apn::DeviceGrouping", :dependent => :destroy
  has_many   :devices, :class_name => 'Apn::Device', :through => :device_groupings
  has_many   :group_notifications, :class_name => 'Apn::GroupNotification'
  has_many   :unsent_group_notifications, -> { where sent_at: nil }, :class_name => 'Apn::GroupNotification'
  
  validates_presence_of :app_id
  validates_uniqueness_of :name, :scope => :app_id
    
end