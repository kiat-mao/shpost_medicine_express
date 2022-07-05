class InterfaceLog < ApplicationRecord
  belongs_to :unit
  # belongs_to :business
  # belongs_to :parent, polymorphic: true
  enum status: {success: 'success', failed: 'failed'}
  
  def self.log(controller_name, action_name, status, *args)
    interface_log = new(controller_name: controller_name, action_name: action_name, status: status)

    if ! args.first.blank? && args.first.is_a?(Hash)
      args.first.each_key do |key|
        if interface_log.respond_to? "#{key}="
          interface_log.send "#{key}=", args.first[key.to_sym]
        end
      end
    end
    # binding.pry
    interface_log.save!
  end
end
