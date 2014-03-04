var UI={};
var months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
UI.colorizer;

cleanArrayFromDuplicates = function(arr){
	var _new = [];
	for(var e=0; e<arr.length; e++){
		if(e == 0){
			_new.push(arr[e]);
		}else{
			var candidate = arr[e];
			for(var ee=0; ee<_new.length; ee++){
				if(_new[ee] == arr[e]) candidate = null;
			}
			if(candidate) _new.push(candidate);
		}
	}
	return _new;
};
featuresMapping = function(feature){

	var json = {
		NAME : feature.name.name,
		VALUE : feature.value.value,
	};

	return json;
};

locateDocumentTitle = function(features) {
	for (var i = 0; i < features.length; i++) {
		var f = featuresMapping(features[i]);
		if (f.NAME == 'TITLE') {
			return f.VALUE;
		}
	}
};

featuresHTML = function(features){

	var _date='',
		_source='',
    _title='',
		_authors='';

	for(var i=0; i<features.length; i++){
		var f = featuresMapping( features[i] );
		switch(f.NAME){
      case 'TITLE':
        _title = '<div class="title"><span class="labelTxt">' + f.NAME + ':</span> ' + f.VALUE + '</div>';
        break;
			case 'PUBDATE':
				var _time = new Date(f.VALUE);
				var _d = _time.getDate();
				var _m = months[_time.getMonth()];
				var _y = _time.getFullYear();
				_date = '<div class="feature"><span class="labelTxt">' + f.NAME + ':</span> '+ _m +' '+ _d +', '+ _y +'</div>';
				break;
			case 'SOURCE':
				_source = '<div class="feature"><span class="labelTxt">' + f.NAME + ':</span> ' + f.VALUE + '</div>';
				break;
			case 'AUTHOR':
				if (f.VALUE) {
					_authors = '<div class="feature"><span class="labelTxt">' + f.NAME + ':</span> ' + f.VALUE +'</div>';
				}
				break;
			case 'AUTHORS':
				if (f.VALUE) {
					_authors = '<div class="feature"><span class="labelTxt">' + f.NAME + ':</span> ' + f.VALUE +'</div>';
				}
				break;
		}
	}


	return ('<fieldset class="extras_fieldset features_fieldset"><div id="docHints">'+_title+_source+_date+_authors+'</div></fieldset>');
};

UI.ANNOTATE=function(json) {
	//////////////
	// DEFAULTS //
	//////////////
	var MEMO = {
    optimization : true,								// OPTIMIZE -> GROUP TOGETHER ANNOTATIONS WITH SAME TYPE ON SAME OFFSET AND BUBBLE IDs
    errorMessage : debug,								// ERROR OUTPUT
    viewAnnotation : UI.SEARCHTYPE.CALL,						// annotation details
    startAlpha : 50,									// FADED ANNOTATIONS (100 -> NO FADE)
    ant : [],											// list annotations
    bak : document.getElementById('__bak'),				// backgorund - text highlights
    tit : document.getElementById('__tit'),				// TITLE
    sum : document.getElementById('__sum'),				// HIGHLIGHT
    txt : document.getElementById('__txt'),				// BODY
    ann : document.getElementById('__ann'),				// annotations
    place : document.getElementById('__txt').parentNode,// component container
    underlines : [6,4,5],								// [ TITLE, HIGHLIGHT, BODY ] - ..documentParts.documentPart[n]
    margin : 30,										// LEFT & RIGHT MARGINS
    colorset : [										// ANNOTATIONS COLORSET
      {"Economy":"#bd0074"},
      {"Location":"#f9bc01"},
      {"Territory":"#f9bc01"}, // duplicated
      {"Region":"#f9bc01"}, // duplicated
      {"FinancialMarket":"#16890a"},
      {"EconomicConditionType":"#004102"},
      {"EconomicCondition":"#682f6e"},
      {"View":"#3079c6"},
      {"TemporalEntity":"#53090a"},
      {"Organization":"#f85d00"},
      {"Money":"#e00000"},
      {"Percent":"#000269"},
      {"PolicyAction":"#883dcb"},
      {"PolicyMaker":"#517680"},
      {"PolicyMaker_NS":"#517680"}, // duplicated
      {"Person":"#517680"}, // duplicated
      {"Indicator":"#ff15dd"},
      {"EconomicTheory":"#a2e630"},
      {"Event":"#33c5c8"},
      {"Event_NS":"#33c5c8"}, // duplicated

      //From Aptara (manual annotations):
      {"http://data.emii.com/annotation-types/support":"#333"},
      {"http://data.emii.com/annotation-types/chart-reference":"#555"},
      {"http://data.emii.com/annotation-types/scenario":"#777"},
      {"http://data.emii.com/annotation-types/mention":"#999"},
      {"http://data.emii.com/annotation-types/counterargument":"#aaa"},
      {"UNDEFINED":"#000"}
    ]
  };

	var _colorize = UI.colorizer = function (type) {
		for (var i = 0; i < MEMO.colorset.length; i++) {
			if (MEMO.colorset[i][type]) {
				return MEMO.colorset[i][type];
			}
		}
		return MEMO.colorset[MEMO.colorset.length - 1].UNDEFINED;
	};
	var _printArray = function (arr) {
		var sty = '';//'style="width:'+UI.SEARCHTYPE.tempWidth+'px; left:-'+UI.SEARCHTYPE.tempWidth/2+'px;"';
		var res = '<div class="t_center"><div class="t_details" '+sty+'>';
		for (var i = 0; i < arr.length; i++) {
			res += '<span>ID:' + arr[i]._id + ' - ' + arr[i]._inst + '</span>';
		}
		res += '</div></div>'
		//var res = (arr.length==1) ? 'ID: '+arr[0] : 'IDS: '+arr.join(', ');
		return res;
	};
	/////////////
	var _getDefaultLineHeight = function (trg) {
		$(trg).html('&nbsp;');
		trg._lineHeight = $(trg).height();
		$(trg).html('<br>&nbsp;');
		trg._lineHeight = $(trg).height() - trg._lineHeight;
		$(trg).html('');
	}
	_getDefaultLineHeight(MEMO.tit);
	_getDefaultLineHeight(MEMO.sum);
	_getDefaultLineHeight(MEMO.txt);

	var _prepareRows = function (trg) {
		if (trg.getElementsByTagName('span')[0]) {
			trg.firstRow = getXY(trg.getElementsByTagName('span')[0], MEMO.place);
			trg.rows = $(trg).height() / trg._lineHeight;
		}
		trg.row = [];
		//debug(trg.firstRow._y)
	};
	/////////////

	MEMO.tit._underH = MEMO.underlines[0];
	MEMO.sum._underH = MEMO.underlines[1];
	MEMO.txt._underH = MEMO.underlines[2];

	/////////////
	// METHODS //
	/////////////
	var _checkForLineBreak = function (_y) {
		if (!MEMO.br) {
			MEMO.br = [];
			var s = MEMO.place.getElementsByTagName('span');
			for (var i = 0; i < s.length; i++) {
				var t = s[i].getAttribute('title');
				if (!t || t == 'undefined') {
					switch (s[i].className) {
					case 'br':
						var _index = MEMO.br.length;
						MEMO.br[_index] = s[i];
						MEMO.br[_index].xy = getXY(s[i], MEMO.place);
						break;
					default:
						//
					}

				}
			}
		}
		for (var i = 0; i < MEMO.br.length; i++) {
			if (MEMO.br[i].xy._y == _y) return MEMO.br[i].xy;
		}
		return false;
	};

	var _getSpanByTitle = function (trg, title) {
		var s = trg.getElementsByTagName('span');
		for (var i = 0; i < s.length; i++) {
			var t = s[i].getAttribute('title');
			if (t == title) {
				return s[i];
			}
		}
		return false;
	};

	var _putIndexedInRow = function (arr, itm) {
		if (arr.length) {
			for (var i = 0; i < arr.length; i++) {
				if (itm.xyw._w > arr[i].xyw._w) {
					arr.splice(i, 0, itm);
					return false;
				} else if (itm.xyw._w == arr[i].xyw._w) {
					if (itm._parent.innerRows >= arr[i]._parent.innerRows) {
						arr.splice(i, 0, itm);
						return false;
					}

					if (i == arr.length - 1) {
						arr.push(itm);
					} else {
						arr.splice(i + 1, 0, itm);
					}
					return false;
				}
			}
			arr.push(itm);
		} else {
			arr.push(itm);
		}
	};

	var _formatAntsInRow = function (elms) {
		for (var m = 0; m < elms.length; m++) {
			elms[m].style.visibility = 'visible';
			/**/
			var _test = _testForConflicts(elms, elms[m]);
			//debug(_test)
			if (_test) {
				for (var u = 0; u < _test.length; u++) {
					if (MEMO.optimization) { // group annotations with same width and type
						if (elms[m].xyw._x == _test[u].xyw._x && elms[m].xyw._w == _test[u].xyw._w && elms[m]._parent._type == _test[u]._parent._type) {
							elms[m]._parent._log.push({
								_id: _test[u]._parent._log[0]._id,
								_inst: _test[u]._parent._log[0]._inst
							});
							_test[u].style.display = 'none';
							_test[u]._level = -1;
						} else {
							_test[u].style.top = (_test[u].xyw._y + (_test[u]._parent.underHeight + 1) * _test[u]._level) + 'px';
						}
					} else {
						_test[u].style.top = (_test[u].xyw._y + (_test[u]._parent.underHeight + 1) * _test[u]._level) + 'px';
					}
				}
			}
			/**/
		}
	};

	var _reorderAnts = function (init) {

		if (init) {
			if (MEMO.timeout) clearTimeout(MEMO.timeout);
			MEMO.sequence = [MEMO.tit, MEMO.sum, MEMO.txt];
			MEMO.rowcount = 0;
			MEMO.current = MEMO.sequence[0];
			MEMO.sequence.splice(0, 1);
		}

		var trg = MEMO.current;

		if (trg.row && trg.row.length) {
			if (trg.row[MEMO.rowcount]) {
				var _reorder = [];

				// order annotations in one row
				for (var e = 0; e < trg.row[MEMO.rowcount].length; e++) {
					_putIndexedInRow(_reorder, trg.row[MEMO.rowcount][e]);
				}

				trg.row[MEMO.rowcount] = _reorder.slice();

				// set the new indexes of annotations in one row
				for (var ee = 0; ee < trg.row[MEMO.rowcount].length; ee++) {
					trg.row[MEMO.rowcount][ee]._index = ee;
				}

				_formatAntsInRow(trg.row[MEMO.rowcount]);

			}
			MEMO.rowcount++;
		} else {
			if (MEMO.sequence.length) { // jumt to next documentPart element
				MEMO.current = MEMO.sequence[0];
				MEMO.sequence.splice(0, 1);
				MEMO.rowcount = 0;
				_reorderAnts();
				return false;
			}
		}
		/////////////////////////////
		if (MEMO.rowcount == MEMO.current.row.length) {
			if (MEMO.sequence.length) { // jumt to next documentPart element
				MEMO.current = MEMO.sequence[0];
				MEMO.sequence.splice(0, 1);
				MEMO.rowcount = 0;
			} else return false; // stop the cycle
		}

		if (trg.parentNode && trg.parentNode.parentNode) {
			MEMO.timeout = setTimeout(function () {
				_reorderAnts()
			}, 25)
		}

		/* INMEDIATE FORMATTING OF ALL ROWS (argument -> trg = documentPart container) * 
		for(var i=0; i<trg.row.length; i++){// all rows
			if(trg.row[i]){
				var _reorder = [];
				for(var e=0; e<trg.row[i].length; e++){// one row
					_putIndexedInRow(_reorder, trg.row[i][e]);
				}
				///////
				trg.row[i] = _reorder.slice();
				///////
				for(var e=0; e<trg.row[i].length; e++){// one row
					trg.row[i][e]._index = e;
				}
				///////
				_formatAntsInRow(trg.row[i]);
				///////
			}
		}
		/**/

	};

	var _testForConflicts = function (arr, itm) {
		var _result = [];
		var _copy = arr.slice();
		_copy.splice(itm._index, 1);

		for (var iii = 0; iii < _copy.length; iii++) {
			if (_copy[iii]._level == itm._level) {
				//debug(itm.xyw._x + '...'+ _copy[iii].xyw._x)
				if (itm.xyw._x < _copy[iii].xyw._x && (itm.xyw._x + itm.xyw._w) > _copy[iii].xyw._x) {
					_result.push(_copy[iii]);
					_copy[iii]._level++;
				} else if (itm.xyw._x >= _copy[iii].xyw._x && (_copy[iii].xyw._x + _copy[iii].xyw._w) > itm.xyw._x) {
					_result.push(_copy[iii]);
					_copy[iii]._level++;
				}
			}
		}

		if (!_result.length) {
			return false
		} else {
			return _result
		}
	};

	var _getFeatureSetInst = function (farr) {
		for (var i = 0; i < farr.length; i++) {
			if (farr[i].name.name == 'inst') return farr[i].value.value;
		}
	};

	var _annotate = function (v) {
		// do not highlight document part annotations
		if (v.type == 'document-part') {
			return;
		}
		
		var ann = MEMO.ann;

		var a = _getSpanByTitle(MEMO.place, v.startnode);
		var b = _getSpanByTitle(MEMO.place, v.endnode);

		if (a.parentNode != b.parentNode) {
			return false
		}
		/*var a = document.getElementById('__'+v.startnode);
		var b = document.getElementById('__'+v.endnode);*/
		if (!a || !b) {
			var dbg = '';
			dbg += (!a) ? v.startnode : '';
			dbg += (!b) ? ' ' + v.endnode : '';
			// UNCOMMENT HERE TO VIEW MISSING OFFSET IDS!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
			//console.log('Missing Offset IDs: ' + dbg);
			return false;
		}

		/**/
		var currentLineHeight = a.parentNode._lineHeight;
		if (currentLineHeight == null) {
			currentLineHeight = a.parentNode.parentNode._lineHeight;
		}
		a.xy = getXY(a, MEMO.place);
		b.xy = getXY(b, MEMO.place);
		////////////////////////////
		var _index = MEMO.ant.length;
		MEMO.ant[_index] = {};
		MEMO.ant[_index].innerRows = 1;
		MEMO.ant[_index].lineHeight = currentLineHeight;
		if (a.xy._y != b.xy._y) {
			MEMO.ant[_index].innerRows += (b.xy._y - a.xy._y) / currentLineHeight;
			//console.log( MEMO.ant[_index].innerRows );
		}

		MEMO.ant[_index].data = v;
		MEMO.ant[_index].elm = [];
		MEMO.ant[_index].underHeight = a.parentNode._underH;
		MEMO.ant[_index]._type = v.type;
		MEMO.ant[_index]._log = [{
			_id: v.id,
			_inst: _getFeatureSetInst(v["feature-set"])
		}];

    console.log(MEMO.ant);
    console.log(MEMO.ant[_index]);
		for (var i = 0; i < MEMO.ant[_index].innerRows; i++) {

			MEMO.ant[_index].elm[i] = document.createElement('div');
			MEMO.ant[_index].elm[i]._parent = MEMO.ant[_index];
			MEMO.ant[_index].elm[i]._level = 0;
			MEMO.ant[_index].elm[i].className = 't_underline ' + MEMO.ant[_index].data.id;

			var _top = (a.xy._y + currentLineHeight * i);

			with(MEMO.ant[_index].elm[i].style) {

				top = (!_op) ? (_top + 2) + 'px' : (_top + currentLineHeight) + 'px';
				left = (i == 0) ? a.xy._x + 'px' : MEMO.margin + 'px';
				height = a.parentNode._underH + 'px';
				backgroundColor = _colorize(v.type);

				// calc width
				if (MEMO.ant[_index].innerRows == 1) {
					width = (b.xy._x - a.xy._x) + 'px';
				} else {
					if (i == MEMO.ant[_index].innerRows - 1) {
						width = (b.xy._x - MEMO.margin) + 'px';
					} else {
						var br = _checkForLineBreak(_top);
						if (br) {
							width = (br._x == a.xy._x) ? '0px' : (br._x - MEMO.margin) + 'px';
						} else {
							right = MEMO.margin + 'px';
						}
					}
				}

			}
			setOpacity(MEMO.ant[_index].elm[i], MEMO.startAlpha);
			MEMO.ant[_index].elm[i].onmouseover = function () {
				_baloon(this._parent._type,{name:'borderColor',value:_colorize(this._parent._type)});
				for (var i = 0; i < this._parent.elm.length; i++) {
					setOpacity(this._parent.elm[i], 100);
					this._parent.elm[i].highlight = document.createElement('div');
					this._parent.elm[i].highlight.className = 't_highlight';
					with(this._parent.elm[i].highlight.style) {
						top = (this._parent.elm[i].xyw._y - 19) + 'px';
						left = this._parent.elm[i].xyw._x + 'px';
						width = this._parent.elm[i].xyw._w + 'px';
						/*height = (this._parent.lineHeight - 10) + 'px';*/
						backgroundColor = _colorize(this._parent._type);
					}
					MEMO.bak.appendChild(this._parent.elm[i].highlight);
				}
			};
			MEMO.ant[_index].elm[i].onclick = function () {
        $("#annotation_form").load(annotationFormBasePath + MEMO.ant[_index].data.id + "/edit");
        //$(this).addClass(MEMO.ant[_index].data.id);
        $("#annotation_form").show();
			};
			MEMO.ant[_index].elm[i].onmouseout = function () {
				for (var i = 0; i < this._parent.elm.length; i++) {
					setOpacity(this._parent.elm[i], MEMO.startAlpha);
					MEMO.bak.removeChild(this._parent.elm[i].highlight);
				}
			};

			//console.log(MEMO.ant[_index].elm[i].xyw._y)
			/////////////////////////////////////////
			ann.appendChild(MEMO.ant[_index].elm[i]);
			if (MEMO.ant[_index].elm[i].previousSibling && MEMO.ant[_index].elm[i].previousSibling.className == 'br') {
				MEMO.ant[_index].elm[i].style.width = '0px';
			}

			MEMO.ant[_index].elm[i].xy = {
				a: a.xy,
				b: b.xy
			};
			MEMO.ant[_index].elm[i].xyw = {
				_x: MEMO.ant[_index].elm[i].offsetLeft,
				_y: MEMO.ant[_index].elm[i].offsetTop,
				_w: MEMO.ant[_index].elm[i].offsetWidth
			};
			/////////////////////////////////////////
			var theParent = a.parentNode;
                        if (theParent.firstRow == null) {
				theParent = a.parentNode.parentNode;
			}
			var currentRow = (_top - theParent.firstRow._y) / currentLineHeight;
			if (!theParent.row[currentRow]) {
				theParent.row[currentRow] = [];
			}
			theParent.row[currentRow].push(MEMO.ant[_index].elm[i]);
			//debug(a.parentNode.row.length)
		}



		/**/

	};
	var _anchors = function (v) {
		if (!v.length) return false;
		/**/
		for (var i = 0; i < v.length; i++) {
			_annotate(v[i]);
		}


		/**/

		/********* VIEW ANCHORS ********

		var t = document.getElementById('__txt');
		var a = document.getElementById('__ann');
		var s = t.parentNode.getElementsByTagName('span');
		for(var i=0; i<s.length; i++){
			var xy=getXY(s[i],t.parentNode);
			var p=document.createElement('div');
			p.className='t_point';
			p.innerHTML='';
			with(p.style){
				top=xy._y+'px';
				left=xy._x+'px';
			}
			a.appendChild(p);
		}

/**/
	};
	var _prepare = function (v) {
		function addNewLines(str) {

			str = str.replace(/\n/g, '<span class="br"><br></span>');

			return str;
		};

		for (var ii = 0; ii < v["document-parts"]["document-part"].length; ii++) {

			var cleanup = v["document-parts"]["document-part"][ii].content.text;
			//cleanup = v["document-parts"]["document-part"][ii].content.text.replace(/<div>/ig, "");
			//cleanup = cleanup.replace(/<div>/ig, "_______");
			//cleanup = cleanup.replace(/[<>]/ig, "|");

			var inject = ' ';

			//cleanup = cleanup.replace(/<\/p><p>/ig, ".......\n");

			//cleanup = cleanup.replace(/<p>/ig, "...");
			//cleanup = cleanup.replace(/<\/p>/ig, "....");
			//cleanup = cleanup.replace(/\s∎/ig, "\n∎");
			//cleanup = cleanup.replace(/[<>]/ig, "|");*/
			
			cleanup = cleanup.replace(/(<)([^<]+)(>)/g, function ($0, $1, $2, $3) {
			    return inject + ' ' + (new Array($2.length).join(inject)) + inject;
			});

			var _text = cleanup;
			var _nodes = v["document-parts"]["document-part"][ii].content.node;
			var _newtext = '';


			for (var i = 0; i < _nodes.length; i++) {
				if (i == 0) {
					//first split
					var firstPiece = (_nodes[i].offset == 0) ? '' : '<span>.</span>' + addNewLines(_text.substring(0, _nodes[i].offset));
					_newtext += firstPiece + '<span title="' + _nodes[i].id + '">.</span>' + addNewLines(_text.substring(_nodes[i].offset, _nodes[i + 1].offset));
				} else if (i == _nodes.length - 1) {
					//last split
					_newtext += '<span title="' + _nodes[i].id + '">.</span>' + addNewLines(_text.substring(_nodes[i].offset));
				} else {
					//all the rest of splits
					_newtext += '<span title="' + _nodes[i].id + '">.</span>' + addNewLines(_text.substring(_nodes[i].offset, _nodes[i + 1].offset));
				}
			}
			switch (v["document-parts"]["document-part"][ii].part) {
			case 'TITLE':
				$('#__tit').html(_newtext);
				break;
			case 'HIGHLIGHT':
				$('#__sum').html(_newtext);
				break;
			case 'CONTENT':
				$('#__txt').html(_newtext);
			}
		}

		//_prepareRows(MEMO.tit);
		//_prepareRows(MEMO.sum);
		$('#__tit').hide();
		$('#__sum').hide();
		_prepareRows(MEMO.txt);

		for (var ii = 0; ii < v["annotation-sets"].length; ii++) {
			_anchors(v["annotation-sets"][ii].annotation);
		}

		////////////////////////////
		////////////////////////////

		_reorderAnts(true);

		////////////////////////////
		////////////////////////////

	};




	//var newjson = eval('('+json.summary+')');
	_prepare(json);




	/*
	$.ajax({
		url: 'annotations/USB-WKB-20110119.xml.gate.xml.json',//'annotations.json',
		dataType: 'json',
		success: _prepare,
		error: function () {
			MEMO.errorMessage('Failure !')
		}
	});*/
};

UI.SEARCHTYPE = function () {

	//!\\ settings
	UI.SEARCHTYPE.duration = 8;
	UI.SEARCHTYPE.easing = FISICS.strongEaseOut;
	UI.SEARCHTYPE.maxHeight = 120;
	UI.SEARCHTYPE.tempWidth = 900;
	UI.SEARCHTYPE.services = [ 'entityTypes' , 'entityLabels' , 'entityComment' , 'entitySubject' , 'entityObject' ];
	UI.SEARCHTYPE.successes = {
		'entityTypes' : function(_data){
			UI.SEARCHTYPE.queue[UI.SEARCHTYPE.queue.length] = {type:'entityTypes',data:_data};
			if(UI.SEARCHTYPE.queue.length == UI.SEARCHTYPE.services.length){UI.SEARCHTYPE.SUCCESS2()}
		},
		'entityLabels' : function(_data){
			UI.SEARCHTYPE.queue[UI.SEARCHTYPE.queue.length] = {type:'entityLabels',data:_data};
			if(UI.SEARCHTYPE.queue.length == UI.SEARCHTYPE.services.length){UI.SEARCHTYPE.SUCCESS2()}
		},
		'entityComment' : function(_data){
			UI.SEARCHTYPE.queue[UI.SEARCHTYPE.queue.length] = {type:'entityComment',data:_data};
			if(UI.SEARCHTYPE.queue.length == UI.SEARCHTYPE.services.length){UI.SEARCHTYPE.SUCCESS2()}
		},
		'entitySubject' : function(_data){
			UI.SEARCHTYPE.queue[UI.SEARCHTYPE.queue.length] = {type:'entitySubject',data:_data};
			if(UI.SEARCHTYPE.queue.length == UI.SEARCHTYPE.services.length){UI.SEARCHTYPE.SUCCESS2()}
		},
		'entityObject' : function(_data){
			UI.SEARCHTYPE.queue[UI.SEARCHTYPE.queue.length] = {type:'entityObject',data:_data};
			if(UI.SEARCHTYPE.queue.length == UI.SEARCHTYPE.services.length){UI.SEARCHTYPE.SUCCESS2()}
		},
	};

	//!\\ methods
	UI.SEARCHTYPE.ANIMATE = function (_start, _from, _to) {
		if (_start) {
			/*if (_to > UI.SEARCHTYPE.maxHeight){
				_to = UI.SEARCHTYPE.maxHeight;
				UI.SEARCHTYPE.scrollable = true;
			}else{
				UI.SEARCHTYPE.scrollable = false;
			}*/
			//!\\ prepare animation
				var st = UI.SEARCHTYPE;
			clearInterval(st.interval);
			st.COUNT = 0;
			st.FRAMES = [];
			for (var i = 0; i < st.duration; i++) {
				st.FRAMES[i] = {
					height: _from + Math.round(st.easing(i, _to - _from, st.duration))
				};
			}
			st.interval = setInterval(function () {
				UI.SEARCHTYPE.ANIMATE()
			}, 30);
		}

		//!\\ do animation
		$("#drop_zone").css({
			height: (UI.SEARCHTYPE.FRAMES[UI.SEARCHTYPE.COUNT].height) + 'px'
		});
		$("#section").css({
			top: (UI.SEARCHTYPE._header + UI.SEARCHTYPE.FRAMES[UI.SEARCHTYPE.COUNT].height + 3) + 'px'
		});
		UI.SEARCHTYPE.COUNT++;

		//!\\ end animation
		if (UI.SEARCHTYPE.COUNT == UI.SEARCHTYPE.duration) {
			clearInterval(UI.SEARCHTYPE.interval);
			/*if(UI.SEARCHTYPE.scrollable){
				$("#drop_zone").css({
					overflow: 'auto'
				});
			}else{
				$("#drop_zone").css({
					overflow: ''
				});
			}*/
		}
	}
	UI.SEARCHTYPE.FORMAT = function (_h) {
		if (!UI.SEARCHTYPE.dropMinHeight) {
			UI.SEARCHTYPE.dropMinHeight = $("#drop_zone").height()
		}
		UI.SEARCHTYPE._header = $("header").height();
		if (!_h) {
			_h = UI.SEARCHTYPE.dropMinHeight
		}

		//!\\ call animation
		UI.SEARCHTYPE.ANIMATE(true, $("#drop_zone").height(), _h);
	};
	UI.SEARCHTYPE.CLOSE = function () {
		$("#drop").text('');
		$("#drop_loader").hide();
		///
		$('#faceted').attr('checked', false);
		$('#faceted').parent().attr("class","icon_checkbox");
		$('#trending').attr('checked', false);
		$('#trending').parent().attr("class","icon_checkbox");
		///
		UI.SEARCHTYPE.FORMAT();
	};
	UI.SEARCHTYPE.CALL = function (_uri) {
		$("#drop").text('');
		$("#drop_loader").show();

		UI.SEARCHTYPE.FORMAT(40);
		if (_uri) {
			///
			$('#faceted').attr('checked', false);
			$('#faceted').parent().attr("class","icon_checkbox");
			$('#trending').attr('checked', false);
			$('#trending').parent().attr("class","icon_checkbox");
			///
			UI.SEARCHTYPE.queue = [];
			for(var i=0; i<UI.SEARCHTYPE.services.length; i++){
				$.ajax({
					url: UI.SEARCHTYPE.services[i] + '?id=' + escape(_uri),
					dataType: 'json',
					success: UI.SEARCHTYPE.successes[UI.SEARCHTYPE.services[i]],
					error: UI.SEARCHTYPE.successes[UI.SEARCHTYPE.services[i]]
				});
			}

			/*
			clearTimeout(document._timeout);
			document._timeout = setTimeout(function () {
				UI.SEARCHTYPE.SUCCESS(customHTML)
			}, 300);*/
		}
	};
	UI.SEARCHTYPE.SUCCESS = function (customHTML) {
		$("#drop_loader").hide();
		if (customHTML) {
			$("#drop").text('');
			$("#drop").html(customHTML);
			var closeButton = '<div class="t_closeLinkContainer"><a href="javascript:void(0)" id="closeLink"><i class="icon-remove icon-large icon-white"</a></div>';
			$(closeButton).appendTo('#drop');
		}
		UI.SEARCHTYPE.FORMAT($("#drop").height() + parseInt($("#drop").css("top")) * 2);
	};
	UI.SEARCHTYPE.SUCCESS2 = function () {
		$("#drop_loader").hide();
		$("#drop").text('');
		_html = '<div class="t_center"><div class="t_details">'
		var _type = '', _label='', _comment='', _relation='', _arr;
		for(var i=0; i<UI.SEARCHTYPE.queue.length; i++){
			switch(UI.SEARCHTYPE.queue[i].type){
				case 'entityTypes':
					if(UI.SEARCHTYPE.queue[i].data.length && UI.SEARCHTYPE.queue[i].data[0] && UI.SEARCHTYPE.queue[i].data[0] != ""){
						_type += '<div class="t_column"><span class="t_label">Type</span><div class="t_container">';

						//////// TYPE -> SIMPLIFY, CUT [protontop#]

						_simpleType = [];
						for(var ii=0; ii<UI.SEARCHTYPE.queue[i].data.length; ii++){
							var _str = UI.SEARCHTYPE.queue[i].data[ii].substring(UI.SEARCHTYPE.queue[i].data[ii].lastIndexOf('/')+1);
							_str = _str.replace(/protontop#/g, '');
							_simpleType.push(_str);
						}

						///////// DUPLICATES //////////

						_simpleType = cleanArrayFromDuplicates(_simpleType);

						///////////////////////////////

						for(var ii=0; ii<_simpleType.length; ii++){
							_type += '<a href="javascript:void(0)" class="t_marker" style="color:#fff !important; background-color:'+UI.colorizer(_simpleType[ii])+'">' + _simpleType[ii].replace(/([A-Z])/g, ' $1') + '</a>';
						}
						_type += '</div></div>';
					}
					break;
				case 'entityLabels':
					if(UI.SEARCHTYPE.queue[i].data.length && UI.SEARCHTYPE.queue[i].data[0] && UI.SEARCHTYPE.queue[i].data[0] != ""){
						_label += '<div class="t_column"><span class="t_label">Label</span><div class="t_container">';

						///////// DUPLICATES //////////

						UI.SEARCHTYPE.queue[i].data = cleanArrayFromDuplicates(UI.SEARCHTYPE.queue[i].data);

						///////////////////////////////

						for(var ii=0; ii<UI.SEARCHTYPE.queue[i].data.length; ii++){
							_label += '<a href="javascript:void(0)" class="t_marker">' + UI.SEARCHTYPE.queue[i].data[ii] + '</a>';
						}
						_label += '</div></div>';
					}
					break;
				case 'entityComment':
					if(UI.SEARCHTYPE.queue[i].data.length && UI.SEARCHTYPE.queue[i].data[0] && UI.SEARCHTYPE.queue[i].data[0] != ""){
						_comment += '<div class="t_column"><span class="t_label">Comment</span><div class="t_container">';
						for(var ii=0; ii<UI.SEARCHTYPE.queue[i].data.length; ii++){
							_comment += '<a href="javascript:void(0)" class="t_marker">' + UI.SEARCHTYPE.queue[i].data[ii] + '</a>';
						}
						_comment += '</div></div>';
					}
					break;
				case 'entitySubject':
					if(UI.SEARCHTYPE.queue[i].data.length && UI.SEARCHTYPE.queue[i].data[0] && UI.SEARCHTYPE.queue[i].data[0] != ""){
						if(!_arr) _arr={};
						for(var ii=0; ii<UI.SEARCHTYPE.queue[i].data.length; ii++){
							if(!_arr[UI.SEARCHTYPE.queue[i].data[ii].predicateLabel]){
								_arr[UI.SEARCHTYPE.queue[i].data[ii].predicateLabel] = [UI.SEARCHTYPE.queue[i].data[ii].entityLabel];
							}else{
								_arr[UI.SEARCHTYPE.queue[i].data[ii].predicateLabel].push(UI.SEARCHTYPE.queue[i].data[ii].entityLabel);
							}
							//_relation += '<span class="t_marker">' + UI.SEARCHTYPE.queue[i].data[ii].predicateLabel + ' -> '+UI.SEARCHTYPE.queue[i].data[ii].entityLabel+'</span>';
						}
						//_relation += '<br>';
					}
					break;
				case 'entityObject':
					if(UI.SEARCHTYPE.queue[i].data.length && UI.SEARCHTYPE.queue[i].data[0] && UI.SEARCHTYPE.queue[i].data[0] != ""){
						if(!_arr) _arr={};
						for(var ii=0; ii<UI.SEARCHTYPE.queue[i].data.length; ii++){
							if(!_arr[UI.SEARCHTYPE.queue[i].data[ii].predicateLabel]){
								_arr[UI.SEARCHTYPE.queue[i].data[ii].predicateLabel] = [UI.SEARCHTYPE.queue[i].data[ii].entityLabel];
							}else{
								_arr[UI.SEARCHTYPE.queue[i].data[ii].predicateLabel].push(UI.SEARCHTYPE.queue[i].data[ii].entityLabel);
							}
							//_relation += '<span class="t_marker">' + UI.SEARCHTYPE.queue[i].data[ii].predicateLabel + ' <- ' + UI.SEARCHTYPE.queue[i].data[ii].entityLabel+'</span>';
						}
						//_relation += '<br>';
					}
					break;
			}
			
		}
		if(_arr){
			var _count = 0;
			for(var i in _arr){ _count++ }
			var _width = Math.floor(100 / _count);
			for(var i in _arr){
				_relation += '<div class="t_column"><span class="t_label">'+ i +'</span><div class="t_container">';

				///////// DUPLICATES //////////

				_arr[i] = cleanArrayFromDuplicates(_arr[i]);

				///////////////////////////////

				for(var ii=0; ii<_arr[i].length; ii++){
					_relation += '<a href="javascript:void(0)" class="t_marker">' + _arr[i][ii] + '</a>';
				}
				_relation += '</div></div>';
			}
		}
		_html += _type + _label + _comment + _relation;
		_html += '</div></div>';
		$("#drop").html(_html);

		///////// FORMAT CENTER //////////
		var _drop = document.getElementById('drop');
		var _details = drop.firstChild.firstChild;
		_details.style.left = Math.round( - 15 - (_details.lastChild.offsetLeft + _details.lastChild.offsetWidth) / 2) + 'px';
		//////////////////////////////////

		var closeButton = '<div class="t_closeLinkContainer"><a href="javascript:void(0)" id="closeLink"><i class="icon-remove icon-large icon-white"</a></div>';
		$(closeButton).appendTo('#drop');

		UI.SEARCHTYPE.FORMAT($("#drop").height() + parseInt($("#drop").css("top")) * 2);
	};
	UI.SEARCHTYPE.CLICK = function () {
		var inp = this.firstChild;
		if (inp.checked) {
			this.className = "icon_checkbox";
			inp.checked = false;
			UI.SEARCHTYPE.CLOSE();
		} else {
			inp.checked = true;
			this.className = "icon_checkbox checked";
			var other = (inp.id == "trending") ? $("#faceted") : $("#trending");
			if (other.attr("checked")) {
				other.attr("checked", false);
				other.parent().attr("class", "icon_checkbox");
			}
			UI.SEARCHTYPE.CALL();
		}
	};

	//!\\ button actions
	$("#faceted").parent().click(UI.SEARCHTYPE.CLICK);
	$("#trending").parent().click(UI.SEARCHTYPE.CLICK);
};

