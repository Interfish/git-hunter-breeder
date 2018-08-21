class TaggerController < ApplicationController
  include Analyser
  include Renderer

  def index
    mark = Mark.first || Mark.create
    index = params[:index].present? ? params[:index].to_i : mark.pointer
    index = [[0, index].max, mark.pointer].min
    file, name = open_file(index)
    content = file.read.force_encoding('UTF-8')
    suspects = analyse_content(content)
    @index = index
    @file_name = name
    @marked_content = get_snippet(content, suspects)
  end

  def tag
    params.permit(tag: %w{leaked ignore normal})
    mark = Mark.first || Mark.create!
    move(params.require(:index).to_i, params.require(:tag), mark)
    render json: { status: 200, msg: 'ok' }
  end

  private

  def open_file(index)
    return File.open(Rails.root.join('..', 'raw_data', RAW_DATA[index])),  RAW_DATA[index]
  end

  def move(index, category, mark)
    if category == 'ignore'
      if index == mark.pointer
        mark.update!(pointer: mark.pointer + 1)
      elsif index < mark.pointer
        rollback(index)
      end
      return
    end
    if index == mark.pointer
      FileUtils.cp(
        Rails.root.join('..', 'raw_data', RAW_DATA[index]),
        Rails.root.join('..', 'tag_result', category)
      )
      mark.update!(pointer: mark.pointer + 1)
    elsif index < mark.pointer
      rollback(index)
      FileUtils.cp(
        Rails.root.join('..', 'raw_data', RAW_DATA[index]),
        Rails.root.join('..', 'tag_result', category)
      )
    else
      throw StandardError.new('index is larger than pointer!')
    end
  end

  def rollback(index)
    if Dir.entries(LEAKED_DIR).include?(RAW_DATA[index])
      FileUtils.rm([LEAKED_DIR, RAW_DATA[index]].join('/'))
    elsif Dir.entries(NORMAL_DIR).include?(RAW_DATA[index])
      FileUtils.rm([NORMAL_DIR, RAW_DATA[index]].join('/'))
    end
  end

end