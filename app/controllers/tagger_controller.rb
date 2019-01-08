class TaggerController < ApplicationController
  include Analyser
  include Renderer

  skip_before_action :verify_authenticity_token

  def index
    @index = params[:index].present? ? params[:index].to_i : CodeSnippet.not_classified.first.id
    @index = [[1, @index].max, CodeSnippet.last.id].min
    @snippet = CodeSnippet.find(@index)
    content = @snippet.content
    suspects = analyse_content(content)
    @file_name = @snippet.file_name
    @marked_content = get_snippet(content, suspects)
  end

  def tag
    params.permit(tag: %w{leaked unsure normal})
    status = case params.require(:tag)
             when 'leaked'
               1
             when 'unsure'
               2
             when  'normal'
               0
             end
    snippet = CodeSnippet.find(params.require(:index))
    if params.require(:tag) != 'normal'
      indices = params[:criticals].split("\n").map do |crit|
        head = snippet.content.index(crit)
        tail = head + crit.size - 1
        [head, tail]
      end
    else
      indices = []
    end
    snippet.update!(status: status, indices: indices)
    render json: { status: 200, msg: 'ok' }
  end
end
