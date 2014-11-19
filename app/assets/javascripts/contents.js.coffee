# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

jQuery ->
  $('.index-curated-checkbox').on 'click', ->
    console.log 'clicked'
    $.ajax $(this).data('updatePath'), 
      method: "PUT"
      data:
        has_event_calendar: $(this).prop("checked")
      

  $('#event_tab_link, #contents_tab_link').on 'click', ->
    $("#content_content_category_id").trigger('change')

  $("#add_new_publication").on 'click', ->
    $(".modal#publication_form .modal-body").load($(this).data('formUrl'))

  $(".tab-traversal-link").on 'click', ->
    current = $(".nav-tabs-simple li.active")[0]
    index = $(".nav-tabs-simple li").index(current)
    new_index = index + parseInt($(this).data("moveIndex"))
    if new_index < 0
      new_index = 0
    # account for tabs that might be hidden
    new_tab = $(".nav-tabs-simple li a:eq(" + new_index + ")")
    while new_tab.parent().hasClass("hidden")
      new_index = new_index + parseInt($(this).data("moveIndex"))
      new_tab = $(".nav-tabs-simple li a:eq(" + new_index + ")")
    new_tab.tab('show')

  updateIssueOptions()
  $(document).on 'change', '#content_source_id', ->
    updateIssueOptions()

  $(document).on 'change', '#content_content_category_id', ->
    name = $(this).find("option:selected").text()
    if name == "Event" or name == "Sale Event"
      $("#add_new_publication").show()
      $("#event_tab_link").removeClass("hidden")
      $("#contents_tab_link").addClass("hidden")
      $("label[for='content_source_id']").text("Organization")
    else
      $("#add_new_publication").hide()
      $("#event_tab_link").addClass("hidden")
      $("#contents_tab_link").removeClass("hidden")
      $("label[for='content_source_id']").text("Publication")
  $("#content_content_category_id").trigger('change')

  # parent content search box
  $("#parent_search").on 'change', ->
    if $("#content_parent_id").length > 0
      updateParentOptions()

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

updateParentOptions = ->
  $.ajax $("#content_parent_id").data("optionsUrl"),
    data:
      content_id: $("#content_parent_id").data("contentId"),
      search_query: $("#parent_search").val(),
      q:
        publication_id: $("#content_source_id").val(),
    beforeSend: ->
      $("#content_parent_id_chosen .chosen-single").spin({radius: 1})
    success: ->
      $("#content_parent_id_chosen .chosen-single").spin(false)
      $("#content_parent_id").trigger('chosen:updated')


updateIssueOptions = ->
  $.ajax $("#content_issue_id").data("optionsUrl"),
    data:
      publication_id: $("#content_source_id").val(),
      selected_id: $("#content_issue_id").data('selectedId')
    dataType: "script"
