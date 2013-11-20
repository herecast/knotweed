jQuery ->
  $('.chosen-select').chosen();

  $("form#contents-query").on 'change', ->
    $.ajax({
      type: "POST",
      url: $(this).attr('action'),
      data: $(this).serialize(),
      beforeSend: ->
        $("#number-of-contents").html("").spin({
          lines: 8,
          length: 4,
          width: 3,
          radius: 5,
          top: 4,
          left: 20})
    })
