class Question < ActiveRecord::Base
  # Validation
	validates_presence_of :short_question, :message => ERROR_EMPTY
end
