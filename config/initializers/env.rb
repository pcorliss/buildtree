if File.exist? '.env'
  env = File.read '.env'
  env.each_line do |line|
    key, val = line.split('=')
    ENV[key] = val.chomp
  end
end
