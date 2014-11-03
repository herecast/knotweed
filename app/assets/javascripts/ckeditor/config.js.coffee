CKEDITOR.editorConfig = (config) ->
  config.toolbar = [
      [ 'Source', '-', 'Print' ],
      [ 'Cut', 'Copy', 'Paste', 'PasteText', 'PasteFromWord', '-', 'Undo', 'Redo' ],
      [ 'Find','Replace','-','SelectAll','-','SpellChecker', 'Scayt' ],
      '/',
      [ 'Bold','Italic','Underline','Strike','Subscript','Superscript','-','RemoveFormat' ],
      [ 'NumberedList','BulletedList','-','Outdent','Indent','-','Blockquote','CreateDiv','-','JustifyLeft','JustifyCenter','JustifyRight','JustifyBlock' ],
      [ 'Link','Unlink','Anchor' ]
      '/',
      [ 'Image','Table','HorizontalRule','SpecialChar' ]
      '/',
      [ 'Styles'],['Format'],['Font'],['FontSize' ],
      [ 'TextColor','BGColor' ],
      [ 'About' ]
    ];
  true
