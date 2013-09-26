require 'json'

# super simple parser
# literally just opens a file that contains
# a json array of articles (hashes)
# and returns that json.

def parse_file(path)
  f = File.open(path, "r:UTF-8")
  json = JSON.parse f.read
  return json
end