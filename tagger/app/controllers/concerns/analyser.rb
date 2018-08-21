module Analyser
  extend ActiveSupport::Concern

  BASE64_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789@-_?!'
  HEX_CHARS = '1234567890abcdefABCDEF'

  def analyse_content(content)
    sensitive_marks = analyse_sensitive_word(content)
    key_word_marks = analyse_key_word(content)
    password_marks = password_analyse(content)
    result_marks = if !key_word_marks.empty? && !password_marks.empty?
                     trim(sensitive_marks, key_word_marks, password_marks)
                   else
                     trim(sensitive_marks)
                   end
  end

  def analyse_sensitive_word(block)
    marks = []
    SENSITIVE_WORDS.each do |word|
      if word =~ /\p{Han}/  # Chinese Character
        block.scan(/(#{word})/) do |match|
          marks << [Regexp.last_match.begin(0), Regexp.last_match.end(0)]
        end
      else
        block.scan(/[^a-zA-Z0-9]#{word}[^a-zA-Z0-9]/i) do |match|
          marks << [Regexp.last_match.begin(0) + 1, Regexp.last_match.end(0) - 1]
        end
      end
    end
    marks
  end

  def analyse_key_word(block)
    marks = []
    KEY_WORDS.each do |pattern|
      block.scan(pattern) do |match|
        marks << [Regexp.last_match.begin(0) + 1, Regexp.last_match.end(0) - 1]
      end
    end
    marks
  end

  def password_analyse(block)
    marks = []
    block.scan(/[a-zA-Z0-9@!\?]+/i) do |match|
      marks << [Regexp.last_match.begin(0), Regexp.last_match.end(0)] if check_shannon_entropy(match)
    end
    marks
  end

  def check_shannon_entropy(word)
    base64_strings = get_strings_of_set(word, BASE64_CHARS)
    hex_strings = get_strings_of_set(word, HEX_CHARS)
    for string in base64_strings
      b64Entropy = shannon_entropy(string, BASE64_CHARS)
      return true if b64Entropy > 4.5
    end
    for string in hex_strings
      hexEntropy = shannon_entropy(string, HEX_CHARS)
      return true if hexEntropy > 3
    end
    false
  end

  def condense(block, arr)
    result = "Too large to display. Please view snippet on GitHub. Contains words:\n"
    words = []
    arr.each do |index_arr|
      words << block.slice(index_arr[0]..index_arr[1])
    end
    result + words.uniq.join(', ')
  end

  # trim the array, cause those arrays could be overlaped
  def trim(*arrays)
    combine_array = [].concat(*arrays).sort {|a, b| a[0] <=> b[0]}
    return [] if combine_array.empty?
    min_index = combine_array.min {|a, b| a[0] <=> b[0]}&.first
    max_index = combine_array.max {|a, b| a[1] <=> b[1]}&.last

    result_array = []
    i = 0
    start_pos = min_index
    end_pos = combine_array[0][1]
    loop do
      if i + 1 > combine_array.length - 1
        result_array << [start_pos, end_pos]
        break
      else
        if combine_array[i + 1][0] <= end_pos
          end_pos = [end_pos, combine_array[i + 1][1]].max
        else
          result_array << [start_pos, end_pos]
          break if i + 1 > combine_array.length - 1
          start_pos = combine_array[i + 1][0]
          end_pos = combine_array[i + 1][1]
        end
        i += 1
      end
    end
    result_array
  end

  def shannon_entropy(data, iterator)
    return 0 if not data
    entropy = 0
    iterator.each_char do |x|
      p_x = Float(data.count(x))/data.length
      entropy += - p_x * Math.log2(p_x) if p_x > 0
    end
    return entropy
  end

  def get_strings_of_set(word, char_set, threshold=SHANNON_ENTROPHY_THRESHOLD)
    letters = ""
    strings = []
    word.each_char do |char|
      if char_set.include? char
        letters << char
      else
        strings << letters if letters.length > threshold
        letters = ""
      end
    end
    strings << letters if letters.length > threshold
    return strings
  end

end