# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

jQuery ->
  $("#organizations_select").on 'change', ->
    updateContentSetsSelect()
  # handle new contact button loading form via ajax
  $("#new_contact_button").on 'click', ->
    $(".modal#contact_form .modal-body").load($(this).data("formUrl"))
  # this needs to be from document to allow editing of newly added ones
  $(document).on "click", ".edit-contact-link", ->
    $(".modal#contact_form .modal-body").load($(this).data("formUrl"))
  
  $(document).on "click", ".edit-issue-link", ->
    $(".modal#issue_form .modal-body").load $(this).data("formUrl"), ->
      $(".modal-body").find(".datetimepicker").datetimepicker()
  $(document).on "click", "#new_issue_button", ->
    $(".modal#issue_form .modal-body").load $(this).data("formUrl"), ->
      $(".modal-body").find(".datetimepicker").datetimepicker()

  $("#new_location_button").on 'click', ->
    $(".modal#location_form .modal-body").load($(this).data("formUrl"))

  $("#organization_location_ids").multiSelect
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
    $("#organization_location_ids").multiSelect("select_all")
  $("#deselect-all-locs").on 'click', ->
    $("#organization_location_ids").multiSelect("deselect_all")

  $(".add-new-field-link").on 'click', ->
    $('.serialized-field-header').show()
    field_type = $(this).data("fieldType")
    model = $(this).data("model")
    val = $(this).next(".new-serialized-field").val()
    $(this).next(".new-serialized-field").val("")
    if val.length == 0
      return
    $(this).parent().nextAll(".serialized-field-header").after('
      <div class="row-fluid serialized-field-row">
        <div class="span2">
          <label for="' + val + '">' + val + '</label>
        </div>
        <div class="span6">
          <input class="span12" id="' + model + '_'+ field_type + '_' + val + '" name="' + model + '[' + field_type + '][' + val + ']" size="30" type="text" value="" />
        </div>
        <div class="span2">
          <div class="btn btn-danger remove-serialized-field">
            X
          </div>
        </div>
      </div>
    ')

  $(document).on 'click', '.remove-serialized-field', ->
    $(this).parents(".serialized-field-row").remove()

  # add new business location
  $("#new_business_location_button").on 'click', ->
    console.log 'hello'
    $(".modal#business_location_form .modal-body").load($(this).data("formUrl"))
  # edit existing location
  $(document).on 'click', '.edit-business-location-link', ->
    $(".modal#business_location_form .modal-body").load($(this).data("formUrl"))

updateContentSetsSelect = ->
  $.ajax({
    url: $("#organizations_select").data("updateContentSetsUrl")
    data: {
      organization_id: $("#organizations_select").val()
    }
    dataType: "script"
  })
