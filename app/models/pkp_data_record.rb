class PkpDataRecord < ActiveRecord::Base
  self.abstract_class = true
  establish_connection("pkp_data_source_#{Rails.env}".to_sym)
end