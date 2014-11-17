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
