jQuery ->
  $(document).on 'change', '#content_source_id', ->
    $.ajax $("#content_issue_id").data("optionsUrl"),
      data:
        publication_id: $(this).val()
      dataType: "script"
