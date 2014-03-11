# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

jQuery ->
  $("#create-annotation-report").on 'click', ->
    $.ajax $(this).data("actionUrl"),
      dataType: "script",
      data: {
        "name": $("input#report_name").val()
      }
    $("input#report_name").val("")

  $(document).on 'click', ".edit-annotation-report-link", ->
    $.ajax $(this).data("actionUrl"),
      dataType: "script"

  $(".modal#annotations").on 'hidden', ->
    if reportId and $("tr#ar-row-"+reportId).length == 0
      $.get "/annotation_reports/" + reportId + "/table_row", (data)->
        $("#annotation_reports table tbody").prepend(data)
    $(this).find("#annotation_form").html("")
    $(this).find(".modal-body").html("Loading annotations...")
