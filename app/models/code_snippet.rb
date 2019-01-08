class CodeSnippet < ApplicationRecord
    serialize :indices, Array
    scope :not_classified,  -> { where(status: nil) }
end
