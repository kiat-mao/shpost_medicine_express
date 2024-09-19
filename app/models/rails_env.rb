class RailsEnv
  def self.is_development?
    return Rails.env.development?
  end

  def self.is_test?
    return Rails.env.test?
  end

  def self.is_production?
    return Rails.env.production?
  end

  def self.is_sqlite3?
    return ActiveRecord::Base.configurations[Rails.env]['adapter'].eql? 'sqlite3'
  end

  def self.is_oracle?
    return ActiveRecord::Base.configurations[Rails.env]['adapter'].eql? 'oracle_enhanced'
  end

end