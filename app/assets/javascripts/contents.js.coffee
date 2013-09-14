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
  $("#channels li a").on 'click', ->
    container.isotope({ filter: $(this).data("option-value") })
    console.log($(this).data("option-value"))
    $("#channels li.active").removeClass("active")
    $(this).parent("li").addClass("active")

  # custom_admin datatables
  $('#documents_table').dataTable( {
    "sDom": "<'row'<'span8'l><'span8'f>r>t<'row'<'span8'i><'span8'p>>",
    "bFilter": false
  })
