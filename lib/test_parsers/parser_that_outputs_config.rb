# this parser is used by test suite to confirm that import 
# jobs are functioning properly
# must have timestamp and guid as config

def parse_file(path, config)
  output = []
  output << config
  return output.to_json
end
