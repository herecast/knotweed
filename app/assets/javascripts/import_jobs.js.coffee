jQuery ->
  # when creating new import jobs, load parameter fields via ajax when parser is selected
  $("select#import_job_parser_id").on 'change', ->
    $("#params_fields").load("/parsers/" + $(this).val() + "/parameters",
      { import_job_id: $("form.edit_import_job").data("id") })
  # when editing existing import jobs, load and populate param fields
  if $("select#import_job_parser_id").val() and $("select#import_job_parser_id").val().length > 0
    $("#params_fields").load("/parsers/" + $("select#import_job_parser_id").val() + "/parameters",
      { import_job_id: $("form.edit_import_job").data("id") })

  # on change job_type, hide or display recurring field (frequency)
  $("#import_job_job_type").on 'change', ->
    if $(this).val() == "recurring"
      $(".frequency").show()
    else
      $(".frequency input").val("0")
      $(".frequency").hide()
  $("#import_job_job_type").trigger 'change'

  # replace run job button with spinner until remote load is finished and status updated
  $(".run-job-button").on 'click', ->
    $(this).html("")
    $(this).spin({
      lines: 8,
      length: 4,
      width: 3,
      radius: 5,
      top: 4,
      left: 20})

  # hide repo / publish method fields unless automatically publish is flagged
  $("#import_job_automatically_publish").on 'change', ->
    if $("#import_job_automatically_publish:checked").length > 0
      $(".control-group.auto-publish").show()
    else
      $(".control-group.auto-publish").hide()
  $("#import_job_automatically_publish").trigger('change')
