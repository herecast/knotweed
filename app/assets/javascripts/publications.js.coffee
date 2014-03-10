# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

jQuery ->
  # handle new contact button loading form via ajax
  $("#new_contact_button").on 'click', ->
    $(".modal#contact_form .modal-body").load($(this).data("formUrl"))
  # this needs to be from document to allow editing of newly added ones
  $(document).on "click", ".edit-contact-link", ->
    $(".modal#contact_form .modal-body").load($(this).data("formUrl"))

  $("#new_location_button").on 'click', ->
    $(".modal#location_form .modal-body").load($(this).data("formUrl"))

  $("#publication_location_ids").multiSelect
    selectableHeader: "<div class='custom-header'>Available</div>"
    selectionHeader: "<div class='custom-header'>Selected</div>"
    afterInit: (ms) ->
      that = this
      $selectableSearch = $("#search_locations")
      selectableSearchString = '#'+that.$container.attr('id')+' .ms-elem-selectable:not(.ms-selected)'

      that.qs1 = $selectableSearch.quicksearch(selectableSearchString).on 'keydown', (e) ->
        if e.which == 40
          that.$selectableUl.focus()
          return false
    afterSelect: ->
      this.qs1.cache()
    afterDeselect: ->
      this.qs1.cache()

  $("#select-all-locs").on 'click', ->
    $("#publication_location_ids").multiSelect("select_all")
  $("#deselect-all-locs").on 'click', ->
    $("#publication_location_ids").multiSelect("deselect_all")
