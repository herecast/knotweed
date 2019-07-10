# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

jQuery ->
  $(document).on 'change', '#content_content_category_id', ->
    content_id = $(this).find("option:selected").val()
    news_children = $("#news-child-id").data('news-child-ids')
    is_child_of_news = $.inArray(parseInt(content_id), news_children)
    if is_child_of_news == -1
      $('.sponsored-content').hide()
      $('.sponsored-content input').val('')
    else
      $('.sponsored-content').show()
  $("#content_content_category_id").trigger('change')

  # parent content search box
  $("#parent_search").on 'change', ->
    if $("#content_parent_id").length > 0
      updateParentOptions()

updateParentOptions = ->
  $.ajax $("#content_parent_id").data("optionsUrl"),
    data:
      content_id: $("#content_parent_id").data("contentId"),
      search_query: $("#parent_search").val(),
      q:
        organization_id: $("#content_organization_id").val(),
    success: ->
      $("#content_parent_id").trigger('chosen:updated')

