jQuery ->
  $('#organization-selectors').on('change', '.user-organization-select', ->
    initialId = parseInt($(this).attr('id').replace('organization-selector-', ''))
    orgName = $(this).children('option:selected').text()
    select = $('#organization-selector-' + initialId).html()

    # add delete option for chosen organization
    $(this).replaceWith('<div id="removal-link-wrapper-' + initialId +
      '"><input type="hidden" name="user[controlled_organization_' + initialId +
      ']" value="' + $(this).val() + '" /><p><b>' + orgName + '</b> | <a id="removal-link-for-' +
      initialId + '" class="organization-removal-link">remove</a></p></div>')

    # add new organization drop-down
    newId = initialId + 1
    newSelect = '<select id="organization-selector-' + newId +
      '" class="user-organization-select">' + select + '</select>'
    $('#organization-selectors').append newSelect
    )

  $('#organization-selectors').on('click', '.organization-removal-link', ->
    removalId = $(this).attr('id').replace('removal-link-for-', '')
    $('#removal-link-wrapper-' + removalId).remove()
    )
