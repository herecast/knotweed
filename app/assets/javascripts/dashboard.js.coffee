# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

jQuery ->
  $("#mixpanel_charts_container").spin
    radius: 5
    top: '100px'

    
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
