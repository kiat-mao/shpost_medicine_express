class ChangeRequestUrlToTextOnInterfaceLogs < ActiveRecord::Migration[6.0]
  def change
    change_column :interface_logs, :request_url, :text
  end
end
