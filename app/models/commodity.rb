class Commodity < ApplicationRecord
	belongs_to :order#, optional: true
end