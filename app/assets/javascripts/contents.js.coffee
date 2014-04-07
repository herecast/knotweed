jQuery ->
  $(document).on 'change', '#content_source_id', ->
    $.ajax $("#content_issue_id").data("optionsUrl"),
      data:
        publication_id: $(this).val()
      dataType: "script"

  $(document).on 'change', "#content_issue_id", ->
    $.ajax "/issues/" + $(this).val(),
      dataType: "json"
      success: (data, status, xhr)->
        # if copyright and/or pubdate are empty, populate them with the issue's value
        if $("input#content_copyright").val().length == 0
          $("input#content_copyright").val(data.issue.copyright)
        if $("input#content_pubdate").val().length == 0
          date = new Date(data.issue.publication_date)
          $("input#content_pubdate").val(date.toLocaleString())
