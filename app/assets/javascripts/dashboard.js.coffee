# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

jQuery ->
    
  path = $("#mixpanel_charts_container").data("loadPath")
  $("#mixpanel_charts_container").load path, (response, status, xhr)->
    if status == "error"
      $("#mixpanel_charts_container").html "There was an error retrieving Mixpanel data."
    else
      $.plot $("#yesterday_article_clicks"), yesterday_clicks_data,
        series:
          pie:
            show: true
      $.plot $("#past_week_article_clicks"), past_week_clicks_data,
        series:
          pie:
            show: true
    $(this).spin(false)

  loadSignInsGraph()
  $(document).on 'change', "#sign_in_time_frame", ->
    loadSignInsGraph()

  loadArticleClicksGraph()
  $(document).on 'change', "#article_clicks_time_frame", ->
    loadArticleClicksGraph()

  loadClicksByCategoryGraph()
  $(document).on 'change', "#clicks_by_category_time_frame", ->
    loadClicksByCategoryGraph()

  loadSessionDurationGraph()
  $(document).on 'change', "#session_duration_time_frame", ->
    loadSessionDurationGraph()
  
loadSignInsGraph = ->
  $("#total_sign_ins_container").spin
    radius: 5
  url = $("#total_sign_ins_container").data("loadPath")
  timeformat = "%b %e"
  if $("#sign_in_time_frame").length > 0
    url = url + "?" + $.param({ time_frame: $("#sign_in_time_frame").val() })
    if $("#sign_in_time_frame").val() == "day"
      timeformat = "%a %I%p"
  $("#total_sign_ins_container").load url, (response, status, xhr) ->
    if status != "error"
      $.plot $("#sign_in_line_graph"), sign_in_data,
        series:
          lines: { show: true } 
        xaxis: 
          mode: "time"
          timeformat: timeformat
      $(this).spin(false)

loadArticleClicksGraph = ->
  $("#article_clicks_container").spin
    radius: 5
  url = $("#article_clicks_container").data("loadPath")
  timeformat = "%b %e"
  if $("#article_clicks_time_frame").length > 0
    url = url + "?" + $.param({ time_frame: $("#article_clicks_time_frame").val() })
    if $("#article_clicks_time_frame").val() == "day"
      timeformat = "%a %I%p"
  $("#article_clicks_container").load url, (response, status, xhr) ->
    if status != "error"
      $.plot $("#article_clicks_line_graph"), article_clicks_data,
        series:
          lines: { show: true }
        xaxis:
          mode: "time"
          timeformat: timeformat
      $(this).spin(false)

loadSessionDurationGraph = ->
  $("#session_duration_container").spin
    radius: 5
  url = $("#session_duration_container").data("loadPath")
  timeformat = "%b %e"
  if $("#session_duration_time_frame").length > 0
    url = url + "?" + $.param({ time_frame: $("#session_duration_time_frame").val() })
    if $("#session_duration_time_frame").val() == "day"
      timeformat = "%a %I%p"
  $("#session_duration_container").load url, (response, status, xhr) ->
    if status != "error"
      $.plot $("#session_duration_line_graph"), session_duration_data,
        series:
          lines: { show: true }
        xaxis:
          mode: "time"
          timeformat: timeformat
      $(this).spin(false)

loadClicksByCategoryGraph = ->
  $("#clicks_by_category_container").spin
    radius: 5
  url = $("#clicks_by_category_container").data("loadPath")
  if $("#clicks_by_category_time_frame").length > 0
    url = url + "?" + $.param({ time_frame: $("#clicks_by_category_time_frame").val() })
  $("#clicks_by_category_container").load url, (response, status, xhr) ->
    if status != "error"
      $.plot $("#clicks_by_category_bar_graph"), clicks_by_category_data,
        series:
          bars: 
            show: true
            barWidth: 0.6
            align: "center"
        xaxis:
          mode: "categories"
          tickLength: 0
      $(this).spin(false)
