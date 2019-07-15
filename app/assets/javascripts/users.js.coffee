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

  $('#user_search').on 'input', ->
    searchInput = $(this).val()
    managedIdKey = $(this).data('searchType') + '_id'
    if searchInput.length > 3 # only search if enough chars are typed
      $.ajax $(this).data('searchUrl'),
        data:
          q:
            name_or_email_cont: searchInput,
          search_context:
            search_type: $(this).data('searchType'),
            "#{managedIdKey}": $(this).data('managedId')
        success: (data) ->
          $('#user_search_results tbody').html(data)

  $('.nav-tabs a[data-target="#managers"]').tab('show') if window.location.hash == '#managers'
