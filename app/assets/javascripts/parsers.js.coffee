jQuery ->
  Numerous.init()
  $(document).on 'click', '.existing-fields-for-parameters span.close', ->
    $(this).prev(".control-group").remove()
    $(this).remove()
