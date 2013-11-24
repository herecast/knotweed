jQuery ->
  $('.chosen-select').chosen();

  $("fieldset#contents-query").on 'change', ->
    $.ajax({
      type: "POST",
      url: $(this).data("contentsQueryPath"),
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
  # trigger a change event so that on edit, we load the count
  $("fieldset#contents-query").trigger 'change'

  # asynchronous loading of content counts
  # on the publish job index page
  $(".num-contents-matched").html("").spin({
      lines: 8,
      length: 4,
      width: 3,
      radius: 5,
      top: 4,
      left: 20
    })
  $(".num-contents-matched").each ->
    $(this).load($(this).parent("tr").data("jobContentsCountPath"))
