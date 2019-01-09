class CodeSnippet < ApplicationRecord
    serialize :indices, Array
    scope :not_classified,  -> { where(status: nil) }
    scope :unsure, -> { where(status: 2) }
    scope :leaked, -> { where(status: 1) }
    scope :normal, -> { where(status: 0) }
    scope :critical_content, -> { map { |snippet| snippet.indices.map { |indice| snippet.content.slice(indice.first..indice.last) } }.flatten }
end
