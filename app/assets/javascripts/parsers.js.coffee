jQuery ->
  Numerous.init()
  $(document).on 'click', '.existing-fields-for-parameters span.close', ->
    $(this).prev(".control-group").remove() # remove the param name input
    $(this).next(".control-group").find("input.hidden").val(true) # set _delete field to true
    $(this).remove() # remove the x remove button
    
