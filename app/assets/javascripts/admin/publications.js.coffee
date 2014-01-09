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
