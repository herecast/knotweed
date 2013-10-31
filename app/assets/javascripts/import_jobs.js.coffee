jQuery ->
  # when creating new import jobs, load parameter fields via ajax when parser is selected
  $("select#import_job_parser_id").on 'change', ->
    $("#params_fields").load("/admin/parsers/" + $(this).val() + "/parameters",
      { import_job_id: $("form.edit_import_job").data("id") })
  # when editing existing import jobs, load and populate param fields
  if $("select#import_job_parser_id").val() and $("select#import_job_parser_id").val().length > 0
    $("#params_fields").load("/admin/parsers/" + $("select#import_job_parser_id").val() + "/parameters",
      { import_job_id: $("form.edit_import_job").data("id") })

  # set up recurring checkbox / frequency field hide show relationship
  if $("input#import_job_frequency").val() == "0"
    $(".import_job_frequency").hide()
  else
    $("input#import_job_recurring").prop("checked", true)

  $("input#import_job_recurring").on 'change', ->
    if $(this).prop("checked")
      $(".import_job_frequency").show()
    else
      $(".import_job_frequency").hide()
      $(".import_job_frequency input").val("0")

  # replace run job button with spinner until remote load is finished and status updated
  $("td.run-job-button").on 'click', ->
    $(this).html("")
    $(this).spin({
      lines: 8,
      length: 4,
      width: 3,
      radius: 5,
      top: 4,
      left: 20})
