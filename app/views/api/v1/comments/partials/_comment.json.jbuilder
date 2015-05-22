attrs = [:id, :title, :pubdate, :authors, :location, :authoremail, 
         :tier]
json.content comment.raw_content

attrs.each{|attr| json.set! attr, comment.send(attr) }
