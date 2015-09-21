jQuery ->
  # hide published select box if no repo is selected
  if $("#repository_id").length > 0 and $("#repository_id").val().length == 0
    $("#published_selector").hide()

  $("fieldset#query_params").on 'change', ->
    if $(this).find("#ids").val().length > 0
      $(this).find("#query-fields").attr("style", "opacity: 0.5;").find(":input").attr("disabled", true)
      $(this).find("#published_selector").attr("style", "opacity: 0.5;").find(":input").attr("disabled", true)
    else
      $(this).find("#query-fields").attr("style", "opacity: inherit;").find(":input").attr("disabled", false)
      $(this).find("#published_selector").attr("style", "opacity: inherit;").find(":input").attr("disabled", false)

    if $("#repository_id").val().length > 0
      $("#published_selector").show()
    else
      $("#published_selector").hide()

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
  $("fieldset#query_params").trigger 'change'

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
