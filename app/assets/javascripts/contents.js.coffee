# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

jQuery ->
  container = $("#wall")
  container.imagesLoaded ->
    container.isotope({
      resizable: false,
      masonry: { columnWidth: container.width() / 12 },
      itemSelector: ".item"
    })

    $(window).smartresize ->
      container.isotope({
        masonry: { columnWidth: container.width() / 12 }
      })
