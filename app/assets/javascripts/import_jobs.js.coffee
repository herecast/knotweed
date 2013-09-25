jQuery ->
  # when creating new import jobs, load parameter fields via ajax when parser is selected
  $("select#import_job_parser_id").on 'change', ->
    $("#params_fields").load("/admin/parsers/" + $(this).val() + "/parameters")