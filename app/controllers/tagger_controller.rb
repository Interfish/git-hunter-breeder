class TaggerController < ApplicationController
  include Analyser
  include Renderer

  # 不需要标注的：
  # private key
  # secret.json

  # 试过的一些关键词
  # delete password
  # remove password
  # remove secret
  # remove token

  skip_before_action :verify_authenticity_token

  def index
    @snippet = CodeSnippet.find(params.require(:index))
    content = @snippet.content
    suspects = analyse_content(content)
    @file_name = @snippet.file_name
    @marked_content = get_snippet(content, suspects)
  end

  def query
    if params[:index].present?
      if params.require(:direction) == 'prev'
        redirect_to '/tag?index=' + (CodeSnippet.where('id < ?', params[:index]).last&.id || CodeSnippet.first.id).to_s
      elsif params.require(:direction) == 'next'
        redirect_to '/tag?index=' + (CodeSnippet.where('id > ?', params[:index]).first&.id || CodeSnippet.last.id).to_s
      end
    else
      redirect_to '/tag?index=' + (CodeSnippet.unclassified.first&.id || CodeSnippet.last.id).to_s
    end
  end

  def tag
    params.permit(tag: %w{leaked unsure normal discard})
    status = case params.require(:tag)
             when 'leaked'
               1
             when 'unsure'
               2
             when  'normal'
               0
             end
    snippet = CodeSnippet.find(params.require(:index))
    if params.require(:tag) == 'discard'
      snippet.destroy!
      render json: { status: 200, msg: 'ok' }
      return
    end
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
