class Apn::App < Apn::Base

  has_many :groups, :class_name => 'Apn::Group', :dependent => :destroy
  has_many :devices, :class_name => 'Apn::Device', :dependent => :destroy
  has_many :notifications, :through => :devices, :dependent => :destroy
  has_many :unsent_notifications, :through => :devices
  has_many :group_notifications, :through => :groups
  has_many :unsent_group_notifications, :through => :groups


  def cert
    (Rails.env == 'production' ? apn_prod_cert : apn_dev_cert)
  end

  # Opens a connection to the Apple Apn server and attempts to batch deliver
  # an Array of group notifications.
  #
  #
  # As each Apn::GroupNotification is sent the <tt>sent_at</tt> column will be timestamped,
  # so as to not be sent again.
  #
  def send_notifications
    if self.cert.nil?
      raise Apn::Errors::MissingCertificateError.new
      return
    end
    Apn::App.send_notifications_for_cert(self.cert, self.id)
  end

  def self.send_notifications
    apps = Apn::App.all
    apps.each do |app|
      app.send_notifications
    end
    if !configatron.apn.cert.blank?
      global_cert = File.read(configatron.apn.cert)
      send_notifications_for_cert(global_cert, nil)
    end
  end

  def self.send_notifications_for_cert(the_cert, app_id)
    # unless self.unsent_notifications.nil? || self.unsent_notifications.empty?
      if (app_id == nil)
        conditions = nil
      else
        conditions = app_id
      end
      begin
        Apn::Connection.open_for_delivery({:cert => the_cert}) do |conn, sock|
          Apn::Device.where(app_id: conditions).find_each do |dev|
            dev.unsent_notifications.each do |noty|
              conn.write(noty.message_for_sending)
              noty.sent_at = Time.now
              noty.save
            end
          end
        end
      rescue Exception => e
        log_connection_exception(e)
      end
    # end
  end

  def send_group_notifications
    if self.cert.nil?
      raise Apn::Errors::MissingCertificateError.new
      return
    end
    unless self.unsent_group_notifications.nil? || self.unsent_group_notifications.empty?
      Apn::Connection.open_for_delivery({:cert => self.cert}) do |conn, sock|
        unsent_group_notifications.each do |gnoty|
          gnoty.devices.find_each do |device|
            conn.write(gnoty.message_for_sending(device))
          end
          gnoty.sent_at = Time.now
          gnoty.save
        end
      end
    end
  end

  def send_group_notification(gnoty)
    if self.cert.nil?
      raise Apn::Errors::MissingCertificateError.new
      return
    end
    unless gnoty.nil?
      Apn::Connection.open_for_delivery({:cert => self.cert}) do |conn, sock|
        gnoty.devices.find_each do |device|
          conn.write(gnoty.message_for_sending(device))
        end
        gnoty.sent_at = Time.now
        gnoty.save
      end
    end
  end

  def self.send_group_notifications
    apps = Apn::App.all
    apps.each do |app|
      app.send_group_notifications
    end
  end

  # Retrieves a list of Apn::Device instnces from Apple using
  # the <tt>devices</tt> method. It then checks to see if the
  # <tt>last_registered_at</tt> date of each Apn::Device is
  # before the date that Apple says the device is no longer
  # accepting notifications then the device is deleted. Otherwise
  # it is assumed that the application has been re-installed
  # and is available for notifications.
  #
  # This can be run from the following Rake task:
  #   $ rake Apn:feedback:process
  def process_devices
    if self.cert.nil?
      raise Apn::Errors::MissingCertificateError.new
      return
    end
    Apn::App.process_devices_for_cert(self.cert)
  end # process_devices

  def self.process_devices
    apps = Apn::App.all
    apps.each do |app|
      app.process_devices
    end
    if !configatron.apn.cert.blank?
      global_cert = File.read(configatron.apn.cert)
      Apn::App.process_devices_for_cert(global_cert)
    end
  end

  def self.process_devices_for_cert(the_cert)
    puts "in Apn::App.process_devices_for_cert"
    Apn::Feedback.devices(the_cert).each do |device|
      if device.last_registered_at < device.feedback_at
        puts "device #{device.id} -> #{device.last_registered_at} < #{device.feedback_at}"
        device.destroy
      else
        puts "device #{device.id} -> #{device.last_registered_at} not < #{device.feedback_at}"
      end
    end
  end

  protected

  def self.log_connection_exception(ex)
    STDERR.puts ex.message
    raise ex
  end

end
