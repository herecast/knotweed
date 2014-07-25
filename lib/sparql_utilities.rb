module SparqlUtilities
  extend self


  # Attempts to sanitize input to be injected into a SPARQL query to prevent
  # injection 
  def sanitize_input(input_string)
    new_str = ""
    input_string.each_char do |c|
      case c
      when "\'"
        new_str << "\\\'"
      when "\\"
        new_str << "\\\\"
      when "\t"
        new_str << "\\t"
      when "\n"
        new_str << "\\n"
      when "\r"
        new_str << "\\r"
      when "\b"
        new_str << "\\b"
      when "\""
        new_str << "\\\""
      when "\0"
        new_str << "\\0"
      else 
        new_str << c
      end
    end
    new_str
  end

  # Attempts to clean a lucene - bound query to remove characters that the search
  # system won't like, even if they're not creating an application vulnerability
  def clean_lucene_query(input_string)
    input_string = input_string.sub(":", "")
    balance_quotes(input_string)
  end

  def balance_quotes(str, depth=0)
    if str.count("\"").even?
      return str
    else
      # cut-off to make sure we don't recurse too much
      return str.replace("\"", "") unless depth < 5
      l = str.index("\"")
      r = str.rindex("\"")
      if l == r
        str.slice!(l)
        str
      else
        str.slice(0..l) +  balance_quotes(str[l+1..r-1], depth+1) + str.slice(r..str.length)
      end
    end
  end
end
