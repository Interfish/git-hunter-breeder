module Renderer
  def get_snippet(content, marks)
    return content if marks.nil?
    result = get_marked_snippet(content, marks)
    result = CGI.escapeHTML(result)
    format_snippet(result)
  end

  def get_marked_snippet(content, marks)
    inserted = 0
    marks.each do |mark|
      content = content.insert(mark.first + inserted * 13, '=mARk~')
      content = content.insert(mark.second + 6 + inserted * 13, '=!mARk~')
      inserted += 1
    end
    content
  end

  def format_snippet(content)
    # Comment below to use pre tag instead
    # content = content.gsub(/\n|\r|\r\n/, '<br>')
    content = content.gsub(/=mARk~/, '<mark>')
    content = content.gsub(/=!mARk~/, '</mark>')
  end
end