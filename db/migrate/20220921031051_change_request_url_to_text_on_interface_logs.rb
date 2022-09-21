class ChangeRequestUrlToTextOnInterfaceLogs < ActiveRecord::Migration[6.0]
  def up
    change_column :interface_logs, :request_url, :string, limit: 2000
  end
  def down
    change_column :interface_logs, :request_url, :string, limit: 256
  end
end
