RAW_DATA = Dir.entries(Rails.root.join('..', 'raw_data')).reject { |e| %w{. ..}.include?(e) }.sort do |a, b|
  if a.split('_')[0].to_i == b.split('_')[0].to_i
    a <=> b
  else
    a.split('_')[0].to_i - b.split('_')[0].to_i
  end
end.freeze