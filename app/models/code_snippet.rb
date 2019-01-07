class CodeSnippet < ApplicationRecord
    scope :not_classified,  -> { where(status: nil) }
end
