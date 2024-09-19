class AuthenticPicturesController < ApplicationController
  load_and_authorize_resource :authentic_picture

  def authentic_pictures_report
  	if RailsEnv.is_oracle?
	  	@results = AuthenticPicture.where("posting_date >= ? and posting_date < ?", Date.today-29.days, Date.tomorrow).order("to_char(posting_date, 'YYYY-MM-DD')").group("to_char(posting_date, 'YYYY-MM-DD')").group(:status).count
	  else
	  	@results = AuthenticPicture.where("posting_date >= ? and posting_date < ?", Date.today-29.days, Date.tomorrow).order("Date(posting_date)").group("Date(posting_date)").group(:status).count
	  end
  	@results_hj = AuthenticPicture.where("posting_date >= ? and posting_date < ?", Date.today-29.days, Date.tomorrow).group(:status).count
  end
end