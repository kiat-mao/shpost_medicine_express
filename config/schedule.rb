# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
set :output, "./log/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

every 2.minutes do
  runner "InterfaceSender.schedule_send"
end

every 2.minutes do
  runner "XydInterfaceSender.address_parsing_schedule"
end

every 5.minutes do
  runner "TmsInterfaceSender.order_trace_schedule"
end

# every 5.minutes do
#   runner "WaybillSender.waybill_schedule"
# end

every 2.minutes do
  runner "WaybillSender.waybill_schedule_offline"
end

every 1.day, :at => '8:00 pm' do
  runner "AuthenticPicture.init_authentic_pictures_15days_ago"
end

every 1.hours do
  runner "AuthenticPicture.init_obtain_authentic_pictures_and_send"
end  

every 30.minutes do
  runner "AuthenticPicture.clean_interface_sends"
end