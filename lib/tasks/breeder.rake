require 'net/http'
require 'pp'

namespace :breeder do
  desc 'breedeing data from github'
  task :breed, [:search_word, :number] => [:environment] do |task, args|
    PER_PAGE = 10
    ACCESS_TOKEN = Rails.application.credentials[:github_access_token].freeze
    search_word, number = args[:search_word], args[:number].to_i
    (number.to_f / PER_PAGE).ceil.times do |page|
      puts "================ Analysing page #{page + 1} word: #{search_word}  ===================="
      url = "https://api.github.com/search/commits?q=#{search_word}&per_page=#{PER_PAGE}&page=#{page + 1}&acess_token=#{ACCESS_TOKEN}"
      uri = URI(url)
      req = Net::HTTP::Get.new(uri)
      req['Accept'] = 'application/vnd.github.cloak-preview'
      http = Net::HTTP.new(uri.hostname, uri.port)
      http.use_ssl = (uri.scheme == "https")
      res = http.request(req)
      raise res.code + ' ' + res.body if res.code != '200'
      body = JSON.parse(res.body)
      analyse_page(body)
    rescue  => e
      puts e.message
      puts e.backtrace.slice(0..5).join("\n")
      sleep 30
      retry
    ensure
      sleep 5
    end
  end

  def analyse_page(res)
    res['items'].each do |info|
      this_url = info['url'] + "?access_token=#{ACCESS_TOKEN}"
      res = Net::HTTP.get_response(URI(this_url))
      raise res.code + ' ' + res.body if res.code != '200'
      body = JSON.parse(res.body)
      #puts body['html_url']
      next if body['files'].size > 20
      sha = body['sha']
      body['files']&.each do |file|
        next if file['patch'].nil?
        puts file['filename']
        content = file['patch'].force_encoding('UTF-8').lines
        head = 0
        tail = 0
        while tail < content.size
          if tail == content.size - 1
            analyse_block(content, head, tail + 1, file['filename'], sha)
          elsif content[tail].match?(/@@.*?@@/)
            analyse_block(content, head, tail, file['filename'], sha)
            content[tail].gsub!(/@@.*?@@/, '')
            head = tail
          end
          tail += 1
        end
      end
    rescue  => e
      puts e.message
      puts e.backtrace.slice(0..5).join("\n")
      sleep 30
    end
  end

  def analyse_block(lines, head, tail, file_name, sha)
    if tail - 1 >= head && tail - head < 21
      addition = ''
      deletion = ''
      block = lines[head..tail-1]
      block.each_with_index do |line, i|
        if line[0] == '+'
          addition << line[1..-1]
        elsif line[0] == '-'
          deletion << line[1..-1]
        else
          addition << line[0..-1]
          deletion << line[0..-1]
        end
      end
      addition_key = sha + '/' + file_name + "#{head}/#{tail}/addition"
      deletion_key = sha + '/' + file_name + "#{head}/#{tail}/deletion"
      CodeSnippet.where(key: addition_key).first_or_create(
        path: file_name,
        content: addition,
      )
      CodeSnippet.where(key: deletion_key).first_or_create(
        path: file_name,
        content: deletion,
      )
    end
  end
end