module Incrementable
  # accepts symbol reference to a count field that needs to be
  # incremented and needs to skip callbacks
  #
  # @param attr_name [Symbol] the attribute to iterate; `:view_count`, `:comment_count`, `:commenter_count`
  def increment_integer_attr!(attr_name)
    update_column attr_name, send(attr_name) + 1
  end
end
