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