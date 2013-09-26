def parse_file(path, config)
  output = []
  config["timestamp"] = "20110607"
  config["guid"] = "117"
  output << config
  return output.to_json
end
