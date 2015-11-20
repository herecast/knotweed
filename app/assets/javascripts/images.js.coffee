updateRows = (ele)->
  if ele.scrollTop() > 0
    ele.attr("rows", parseInt(ele.attr("rows"))+1)

jQuery ->
  submitUrl = $("#image_image").data("uploadUrl")
  $("#image_image").fileupload
    url: submitUrl
    type: "POST"
    dataType: "script"
    dropZone: $("#images")
    formData: (form) ->
      $("fieldset#image_fields").serializeArray()
    add: (e, data) ->
      types = /(\.|\/)(gif|jpe?g|png)$/i
      file = data.files[0]
      if types.test(file.type) || types.test(file.name)
        data.context = $(tmpl("template-upload", file))
        $('#images').prepend(data.context)
        data.submit()
      else
        alert("#{file.name} is not a gif, jpeg, or png image file")
    progress: (e, data) ->
      if data.context
        progress = parseInt(data.loaded / data.total * 100, 10)
        data.context.find('.bar').css('width', progress + '%')
    done: (e, data) ->
      if data.context
        data.context.remove()
      $("span.file-input-name").text("")

  $(document).on 'click', 'a.update-image', (event)->
    event.preventDefault()
    saveImageAttributes(this)

  $(document).on 'change', '.image-field', ->
    updateButton = $(this).closest('.image').find("a.update-image")
    saveImageAttributes(updateButton)


  # resize textbox
  $(document).on 'keyup', ".caption-field", ->
    updateRows($(this))

# saves image attributes 
# called when "update" is pressed or when the text fields are changed
saveImageAttributes = (updateButton) ->
  imageId = $(updateButton).data('imageId')
  primary = $('#image_' + imageId + '_primary:checked').length > 0;
  if primary
    # uncheck and update any other images marked primary
    $('.primary-checkbox:checked').each ->
      if $(this).attr('id') !=  ('image_' + imageId + '_primary')
        $(this).attr('checked', false)
        # don't need to trigger an ajax call here because the actual data update
        # is handled automatically by the Image model, so we're just changing
        # the UX to reflect the updated database

  $.ajax($(updateButton).data("url"), {
    type: "PUT",
    dataType: "script",
    data: { 
      "image": { 
        "caption": $("#image_" + imageId + "_caption").val(),
        "credit": $("#image_" + imageId + "_credit").val(),
        "primary": $('#image_' + imageId + '_primary').is(':checked')
      }
    }
  })
