require 'net/http'
require 'pp'

namespace :breeder do
  desc 'breedeing data from github'
  task :breed, [:search_word, :number] => [:environment] do |task, args|
    ACCESS_TOKEN = Rails.application.credentials[:github_access_token].freeze
    PER_PAGE = 10
    search_word, target_fetch = args[:search_word], args[:number].to_i
    $actual_fetch = 0 
    page = 1
    while $actual_fetch < target_fetch do
      begin
        puts "================ Analysing page #{page} word: #{search_word}  ===================="
        url = "https://api.github.com/search/commits?q=#{search_word}&per_page=#{PER_PAGE}&page=#{page}&acess_token=#{ACCESS_TOKEN}"
        uri = URI(url)
        req = Net::HTTP::Get.new(uri)
        req['Accept'] = 'application/vnd.github.cloak-preview'
        http = Net::HTTP.new(uri.hostname, uri.port)
        http.use_ssl = (uri.scheme == "https")
        res = http.request(req)
        raise res.code + ' ' + res.body if res.code != '200'
        body = JSON.parse(res.body)
        analyse_page(body)
        page += 1
        puts "Actual fetch: #{$actual_fetch}"
      rescue  StandardError => e
        puts e.message
        puts e.backtrace.slice(0..5).join("\n")
        sleep 30
        retry
      ensure
        sleep 5
      end
    end
  end

  task :change_index, [:index, :indices] => [:environment] do |task, args|
    snippet = CodeSnippet.find(args[:index])
    indices = []

    if args[:indices].nil?
      puts 'Indices ...'
    else
      args[:indices].split(';').each do |indice|
        indices << [indice.split(' ').first.to_i, indice.split(' ').last.to_i]
      end
      snippet.update!(indices: indices)
      puts 'New indices ...'
    end
    snippet.indices.each do |indice|
      puts "#{indice} : #{snippet.content.slice(indice.first..indice.last)}"
    end
  end

  def analyse_page(res)
    res['items'].each do |info|
      this_url = info['url'] + "?access_token=#{ACCESS_TOKEN}"
      res = Net::HTTP.get_response(URI(this_url))
      raise res.code + ' ' + res.body if res.code != '200'
      body = JSON.parse(res.body)
      #puts body['html_url']
      next if body['files'].size > 10
      sha = body['sha']
      body['files']&.each do |file|
        next if file['patch'].nil?
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
    rescue StandardError => e
      puts e.message
      puts e.backtrace.slice(0..5).join("\n")
      sleep 30
      retry
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
      unless CodeSnippet.find_by(key: addition_key)
        CodeSnippet.create(
          key: addition_key,
          file_name: file_name,
          content: addition
        )
        $actual_fetch += 1
      end
      unless CodeSnippet.find_by(key: deletion_key)
        CodeSnippet.create(
          key: deletion_key,
          file_name: file_name,
          content: deletion
        )
        $actual_fetch += 1
        puts file_name
      end
    end
  end
end