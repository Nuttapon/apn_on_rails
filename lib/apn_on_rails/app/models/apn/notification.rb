# Represents the message you wish to send. 
# An Apn::Notification belongs to an Apn::Device.
# 
# Example:
#   Apn = Apn::Notification.new
#   Apn.badge = 5
#   Apn.sound = 'my_sound.aiff'
#   Apn.alert = 'Hello!'
#   Apn.device = Apn::Device.find(1)
#   Apn.save
# 
# To deliver call the following method:
#   Apn::Notification.send_notifications
# 
# As each Apn::Notification is sent the <tt>sent_at</tt> column will be timestamped,
# so as to not be sent again.
class Apn::Notification < Apn::Base
  include ::ActionView::Helpers::TextHelper
  extend ::ActionView::Helpers::TextHelper
  serialize :custom_properties
  
  belongs_to :device, :class_name => 'Apn::Device'
  has_one    :app,    :class_name => 'Apn::App', :through => :device
  
  # Stores the text alert message you want to send to the device.
  # 
  # If the message is over 150 characters long it will get truncated
  # to 150 characters with a <tt>...</tt>
  def alert=(message)
    if !message.blank? && message.size > 150
      message = truncate(message, :length => 150)
    end
    write_attribute('alert', message)
  end
  
  # Creates a Hash that will be the payload of an Apn.
  # 
  # Example:
  #   Apn = Apn::Notification.new
  #   Apn.badge = 5
  #   Apn.sound = 'my_sound.aiff'
  #   Apn.alert = 'Hello!'
  #   Apn.apple_hash # => {"aps" => {"badge" => 5, "sound" => "my_sound.aiff", "alert" => "Hello!"}}
  #
  # Example 2: 
  #   Apn = Apn::Notification.new
  #   Apn.badge = 0
  #   Apn.sound = true
  #   Apn.custom_properties = {"typ" => 1}
  #   Apn.apple_hash # => {"aps" => {"badge" => 0, "sound" => "1.aiff"}, "typ" => "1"}
  def apple_hash
    result = {}
    result['aps'] = {}
    result['aps']['alert'] = self.alert if self.alert
    result['aps']['badge'] = self.badge.to_i if self.badge
    if self.sound
      result['aps']['sound'] = self.sound if self.sound.is_a? String
      result['aps']['sound'] = "1.aiff" if self.sound.is_a?(TrueClass)
    end
    if self.custom_properties
      self.custom_properties.each do |key,value|
        result["#{key}"] = "#{value}"
      end
    end
    result
  end
  
  # Creates the JSON string required for an Apn message.
  # 
  # Example:
  #   Apn = Apn::Notification.new
  #   Apn.badge = 5
  #   Apn.sound = 'my_sound.aiff'
  #   Apn.alert = 'Hello!'
  #   Apn.to_apple_json # => '{"aps":{"badge":5,"sound":"my_sound.aiff","alert":"Hello!"}}'
  def to_apple_json
    self.apple_hash.to_json
  end
  
  # Creates the binary message needed to send to Apple.
  def message_for_sending
    json = self.to_apple_json
    device_token = [self.device.token.gsub(/[<\s>]/, '')].pack('H*')
    message = [0, 0, 32, device_token, 0, json.bytes.count, json].pack('ccca*cca*')
    raise Apn::Errors::ExceededMessageSizeError.new(json) if json.bytes.count > 256
    message
  end
  
  def self.send_notifications
    ActiveSupport::Deprecation.warn("The method Apn::Notification.send_notifications is deprecated.  Use Apn::App.send_notifications instead.")
    Apn::App.send_notifications
  end
  
end # Apn::Notification