# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

jQuery ->
  $('.add-hours-link').on 'click', ->
    new_index = $('#business_location_hours input').length
    $('#business_location_hours').append '
      <div class="row-fluid">
        <div class="span6">
          <input class="span12" id="business_location_attributes_hours" + name="business_profile[business_location_attributes][hours][]" value="" />
        </div>
        <div class="span2 offset4">
          <div class="btn btn-danger remove-hours-field">
            X
          </div>
        </div>
      </div>'
  $(document).on 'click', '.remove-hours-field', ->
    $(this).parents('.row-fluid').first().remove()

jQuery ->
  $('.edit_business_profile #business_profile_archived').on 'change', ->
    state = $(this).attr('data-state')
    if state.includes('active') and state.includes('claimed')
      c = confirm('Archive this business and delete its organization and profile records? (This action cannot be undone.)')
      if c then $(this.form).submit() else $(this).prop('checked', false)
    else
      $(this.form).submit()

jQuery ->
  $('.nav-tabs a[data-target="#managers"]').tab('show') if window.location.hash == '#managers'