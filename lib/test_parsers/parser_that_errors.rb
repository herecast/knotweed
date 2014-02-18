# parser_that_errors.rb
#
# a parser for testing that throws an error

def parse_file(source, config)
  raise StandardError, "fake error for testing"
end
