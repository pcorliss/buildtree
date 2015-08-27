if File.exist? '.env'
  env = File.read '.env'
  env.each_line do |line|
    next if line.start_with?('#')
    key, val = line.split('=')
    ENV[key] = val.chomp
  end
end
