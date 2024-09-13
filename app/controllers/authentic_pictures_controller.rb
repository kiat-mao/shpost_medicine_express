class AuthenticPicturesController < ApplicationController
  load_and_authorize_resource :authentic_picture

  def authentic_pictures_report
  	@results = AuthenticPicture.where("posting_date >= ? and posting_date < ?", Date.today-29.days, Date.tomorrow).group("Date(posting_date)").group(:status).count
  	@results_hj = AuthenticPicture.where("posting_date >= ? and posting_date < ?", Date.today-29.days, Date.tomorrow).group(:status).count
  end
end