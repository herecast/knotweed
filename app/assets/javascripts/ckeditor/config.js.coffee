CKEDITOR.editorConfig = (config) ->
  config.height = "500px"
  config.toolbar = [
      [ 'Source' ],
      [ 'Cut', 'Copy', 'Paste', 'PasteText', 'PasteFromWord', '-', 'Undo', 'Redo' ],
      [ 'Find','Replace','-','SelectAll','-','SpellChecker', 'Scayt' ],
      '/',
      [ 'Bold','Italic','Underline' ],
      [ 'NumberedList','BulletedList','-','Outdent','Indent','JustifyLeft','JustifyCenter','JustifyRight','JustifyBlock' ],
      [ 'Link','Unlink' ],
      [ 'Image','HorizontalRule','SpecialChar' ]
      '/',
      [ 'Styles'],['Format'],['Font'],['FontSize' ],
      [ 'TextColor','BGColor' ],
      [ 'About' ]
    ];
  true
