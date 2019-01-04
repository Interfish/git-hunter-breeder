require 'json'
require 'net/http'
require 'base64'
require_relative './config.rb'
require_relative './analyser.rb'

namespace :breeder do
  desc 'breedeing data from github'
  task :breed, [:key_words, :number] => [:environment] do |task, args|
    
  
  end
end

PROJECT_ROOT = File.expand_path(__dir__).freeze
RESULT_DIR = 'result'.freeze
PER_PAGE = 10.freeze
GITHUB_MAX_RESULT = 1000.freeze

class CustomError < StandardError;end

def prepare_dir
  $dir = RESULT_DIR + '_' + Time.now.strftime('%y%m%d%H%M%S')
  `cd #{PROJECT_ROOT} && mkdir -p #{$dir}`
end

def save_file(addition, deletion)
  file_name = "#{$file_count.to_s + '_addition'}.txt"
  File.open([PROJECT_ROOT, $dir, file_name].join('/'), 'w') do |f|
    f.write(addition)
  end
  file_name = "#{$file_count.to_s + '_deletion'}.txt"
  File.open([PROJECT_ROOT, $dir, file_name].join('/'), 'w') do |f|
    f.write(deletion)
  end
  $file_count += 1
end

def analyse_block(lines, head, tail, file_name)
  if tail - 1 >= head && tail - head < 51
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
    addition += ("\n=== File Path ===\n" + file_name)
    deletion += ("\n=== File Path ===\n" + file_name)
    #puts '=================='
    #puts addition
    #puts '=================='
    #puts deletion
    save_file(addition, deletion)
  end
end

def run(search_word)
  (GITHUB_MAX_RESULT / PER_PAGE).times do |page|
    begin
      puts "================ Analysing page #{page + 1} word: #{search_word}  ===================="
      url = "https://api.github.com/search/commits?q=#{search_word}&per_page=#{PER_PAGE}&page=#{page + 1}&acess_token=#{config[:access_token]}"
      uri = URI(url)
      req = Net::HTTP::Get.new(uri)
      req['Accept'] = 'application/vnd.github.cloak-preview'
      http = Net::HTTP.new(uri.hostname, uri.port)
      http.use_ssl = (uri.scheme == "https")
      res = http.request(req)
      res = JSON.parse(res.body)
      raise CustomError, 'Reached search rate limit! Try again later' if res['message']
      analyse_page(res)
    rescue CustomError => e
      puts e.message
      sleep 30
      retry
    ensure
      sleep 5
    end
  end
end

def analyse_page(res)
  res['items'].each do |info|
    this_url = info['url']
    parents_urls = info['parents'].map {|parent| parent['url']}
    ([this_url] + parents_urls).each do |commit_url|
      begin
        commit_url += "?access_token=#{config[:access_token]}"
        commit_res = Net::HTTP.get_response(URI(commit_url))
        if commit_res.code == '403'
          puts 'Probably reached Github API request rate limit.'
        elsif commit_res.code == '404'
          puts '404 Not Found'
        else
          commit_res = JSON.parse(commit_res.body)
          puts commit_res['html_url']
          ##jj commit_res
          next if commit_res['files'].size > 20
          commit_res['files']&.each do |file|
            next if file['patch'].nil?
            puts file['filename']
            content = file['patch'].force_encoding('UTF-8').lines
            head = 0
            tail = 0
            while tail < content.size
              if tail == content.size - 1
                analyse_block(content, head, tail + 1, file['filename'])
              elsif content[tail].match?(/@@.*?@@/)
                analyse_block(content, head, tail, file['filename'])
                content[tail].gsub!(/@@.*?@@/, '')
                head = tail
              end
              tail += 1
            end
          end
        end
      rescue StandardError => e
        puts e.message
        puts e.backtrace.join("\n")
        next
      end
    end
  end
end

$file_count = 1
prepare_dir
config[:search_words].each do |search_word|
  run(search_word.gsub(/\s/, '+'))
end