jQuery ->
  $(document).on 'change', '#content_source_id', ->
    $.ajax $("#content_issue_id").data("optionsUrl"),
      data:
        publication_id: $(this).val()
      dataType: "script"
    $.ajax $("#content_parent_id").data("optionsUrl"),
      data:
        publication_id: $(this).val(),
        content_id: $("#content_parent_id").data("contentId")

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

  # update publish links when user changes repository dropdown
  $("#publish_repository_id").on 'change', ->
    $(".publish-methods a.btn").each ->
      split_href = $(this).attr("href").split("/")
      new_repo_id = $("#publish_repository_id").val()
      split_href[split_href.length-1] = new_repo_id
      new_href = split_href.join("/")
      $(this).attr("href", new_href)
