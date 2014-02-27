var UI={};
var months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
UI.colorizer;

var documentIdentifier = "";

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
		_category='',
		_authors='';

	for(var i=0; i<features.length; i++){
		var f = featuresMapping( features[i] );
		switch(f.NAME){
			case 'PUBDATE':
				var _time = new Date(f.VALUE);
				var _d = _time.getDate();
				var _m = months[_time.getMonth()];
				var _y = _time.getFullYear();
				_date = '<div class="dateTxt">'+ _m +' '+ _d +', '+ _y +'</div>';
				break;
			case 'SOURCE':
				_source = '<div class="feature"><span class="labelTxt">' + f.NAME + ':</span> ' + f.VALUE + '</div>';
				break;
			case 'CATEGORIES':
				if (f.VALUE) {
					_category = '<div class="feature"><span class="labelTxt">' + f.NAME + ':</span> ' + f.VALUE + '</div>';
				}
				break;
			case 'CATEGORY':
				if (f.VALUE) {
					_category = '<div class="feature"><span class="labelTxt">' + f.NAME + ':</span> ' + f.VALUE + '</div>';
				}
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


	return ('<fieldset class="extras_fieldset features_fieldset"><legend>Document Info</legend><div id="docHints">'+_date+'<br style="line-height:40px">'+_source+_category+_authors+'</div></fieldset>');
};
/*
var typesFix = [
	"http://data.emii.com/ontologies/location/Location",
	"http://data.euromoneyplc/economy/Indicator",
	"http://non-searchable.data.euromoneyplc/economy/Indicator",
	"http://data.emii.com/ontologies/core/Event",
	"http://non-searchable.data.euromoneyplc.com/ontologies/core/Event",
	"http://non-searchable.data.euromoneyplc.com/ontologies/core/TemporalEntity",
	"http://non-searchable.data.euromoneyplc.com/ontologies/core/Money",
	"http://non-searchable.data.euromoneyplc.com/ontologies/core/Percent",
	"http://data.emii.com/ontologies/economy/PolicyAction",
	"http://data.emii.com/ontologies/agency/Organization",
	"http://data.emii.com/ontologies/ext/PolicyMaker",
	"http://data.emii.com/ontologies/economy/Economy",
	"http://non-searchable.data.emii.com/ontologies/economy/Economy",
	"http://data.emii.com/classification-types/economy",
	"http://data.emii.com/ontologies/economy/FinancialMarket",
	"http://non-searchable.data.emii.com/ontologies/economy/FinancialMarket",
	"http://data.emii.com/ontologies/economy/EconomicConditionType",
	"http://data.emii.com/ontologies/economy/EconomicCondition",
	"http://data.emii.com/ontologies/economy/FinancialMarketCondition",
	"http://non-searchable.data.emii.com/ontologies/agency/Person",
	"http://data.emii.com/ontologies/bca/View",
	"http://data.emii.com/ontologies/economy/EconomicTheory",
	"http://non-searchable.data.euromoneyplc.com/ontologies/core/Chart",
	"http://non-searchable.data.euromoneyplc.com/ontologies/core/Table",
	"http://non-searchable.data.euromoneyplc.com/ontologies/core/Panel"
];
var typesFix2 = "http://www.ontotext.com/proton/protontop#";
*/
UI.ANNOTATE=function(json) {
	//////////////
	// DEFAULTS //
	//////////////
	var MEMO={
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
UI.LOADING = function () {
	switch (arguments[0]) {
	case true:
		$('#main_loader').show();
		UI.DARKEN();
		break;
	default:
		$('#main_loader').hide();
	}
};
UI.DARKEN = function () {
	if (!UI.CHANNELS.LEFT) {
		var rs = document.getElementById('right_side');
		var ls = document.getElementById('left_side');
		if (rs && ls) {
			UI.CHANNELS.LEFT = rs;
			UI.CHANNELS.RIGHT = ls;
			//!\\ button actions
			UI.CHANNELS.NEXT = rs.getElementsByTagName('a')[0];
			UI.CHANNELS.PREV = ls.getElementsByTagName('a')[0];
			UI.CHANNELS.NEXT.onclick = function () {
				UI.CHANNELS.SLIDE('next')
			};
			UI.CHANNELS.PREV.onclick = function () {
				UI.CHANNELS.SLIDE('prev')
			};
		} else {
			alert(1);
			return false
		}
	} else {
		UI.CHANNELS.NEXT.style.display = UI.CHANNELS.PREV.style.display = 'none';
		UI.CHANNELS.LEFT.style.width = '100%';
		UI.CHANNELS.RIGHT.style.width = '0%';
	}
};
UI.MESSAGE = function (txt) {
	var msg = $('#main_message');
	if (txt) {
		msg.text('');
		msg.html(txt);
		msg.show();
		UI.LOADING(false);
	} else {
		msg.hide()
	}
};

UI.MENU = function (section) {
	if (!section) {
		section = 0
	}
	if (!UI.MENU.MEMO) {

		//!\\ settings
		UI.MENU.MEMO = {
			duration: 11,
			easing: FISICS.strongEaseInOut,
		};

		//!\\ methods
		UI.MENU.FORMAT = function () {

		};
		UI.MENU.CALL = function (who) {
			if (who) {
				who.LINK.blur();
				if (UI.MENU.SELECT && UI.MENU.SELECT == who) {
					return false;
				}
				clearInterval(UI.MENU.interval);
				UI.MENU.COUNT = 0;
				UI.MENU.RUNNER = [];
				UI.MENU.RUNNER[0] = who;
				UI.MENU.RUNNER[1] = (UI.MENU.SELECT) ? UI.MENU.SELECT : null;
				if (UI.MENU.RUNNER[1]) {
					UI.MENU.RUNNER[1].className = UI.MENU.RUNNER[1].CLASS;
				} //collapsed

				UI.MENU.SELECT = who;
				UI.MENU.interval = setInterval(function () {
					UI.MENU.CALL()
				}, 30);
				if (who == UI.MENU.ITEM[0]) {
					$('#search_icon').click(function () {
						$.bbq.pushState(UI.composeSerachRequest(), 2);
					});
				} else {
					$('#search_icon').off('click');
				}
			}
			with(UI.MENU.RUNNER[0].style) {
				width = UI.MENU.RUNNER[0].FRAMES[UI.MENU.COUNT].width + 'px';
				height = UI.MENU.RUNNER[0].FRAMES[UI.MENU.COUNT].height + 'px';
			}
			var base = UI.MENU.RUNNER[0].FRAMES[UI.MENU.COUNT].width;
			if (UI.MENU.RUNNER[1]) {
				var reversed = UI.MENU.MEMO.duration - UI.MENU.COUNT - 1;
				with(UI.MENU.RUNNER[1].style) {
					width = UI.MENU.RUNNER[1].FRAMES[reversed].width + 'px';
					height = UI.MENU.RUNNER[1].FRAMES[reversed].height + 'px';
				}
				base = UI.MENU.RUNNER[1].FRAMES[reversed].width + UI.MENU.RUNNER[0].FRAMES[UI.MENU.COUNT].width - UI.MENU.RUNNER[0].MEMO.START.width;
			}

			UI.MENU.TARGET.style.left = Math.round(-(UI.MENU.baseWidth + base) / 2) + 'px';

			UI.MENU.COUNT++;
			if (UI.MENU.COUNT == UI.MENU.MEMO.duration) {
				clearInterval(UI.MENU.interval);
				UI.MENU.RUNNER[0].className = UI.MENU.RUNNER[0].CLASS + ' expanded'; //expanded
			}
		};

		//!\\ structure
		var mnu = UI.MENU.TARGET = $(".tools_zone")[0];
		UI.MENU.ITEM = [];
		var maxWidth = 0;
		for (var i = 0; i < mnu.childNodes.length; i++) {
			if (/tool/i.test(mnu.childNodes[i].className)) {
				var num = UI.MENU.ITEM.length;
				var itm = UI.MENU.ITEM[num] = mnu.childNodes[i];
				itm.INDEX = num;
				itm.CLASS = itm.className;
				itm.LINK = itm.lastChild;
				itm.BOARD = itm.firstChild;
				itm.DATA = itm.firstChild.firstChild;

				//!\\ initial measurements
				var marg = {
					width: itm.LINK.parentNode.offsetWidth - itm.LINK.offsetWidth - itm.LINK.offsetLeft,
					height: itm.LINK.offsetTop
				};
				itm.MEMO = {
					START: {
						width: itm.LINK.offsetWidth + 2 * marg.width,
						height: itm.LINK.offsetHeight + 2 * marg.height
					},
					END: {
						width: itm.offsetWidth,
						height: itm.offsetHeight + marg.height - 1
					}
				};

				//!\\ set width of menu
				if (maxWidth < itm.MEMO.END.width) {
					maxWidth = itm.MEMO.END.width;
				}

				//!\\ calc animation
				itm.FRAMES = [];
				for (var e = 0; e < UI.MENU.MEMO.duration; e++) {
					itm.FRAMES[e] = {
						width: itm.MEMO.START.width + Math.round(UI.MENU.MEMO.easing(e, itm.MEMO.END.width - itm.MEMO.START.width, UI.MENU.MEMO.duration)),
						height: itm.MEMO.START.height + Math.round(UI.MENU.MEMO.easing(e, itm.MEMO.END.height - itm.MEMO.START.height, UI.MENU.MEMO.duration))
					};
				}
				with(itm.style) {
					width = itm.MEMO.START.width + 'px';
					height = itm.MEMO.START.height + 'px';
				}
				itm.onclick = function () {
					UI.MENU(this.INDEX);
				}
			}
		}
		UI.MENU.baseWidth = UI.MENU.ITEM[UI.MENU.ITEM.length - 1].offsetLeft;
		UI.MENU.TARGET.style.left = Math.round(-(UI.MENU.baseWidth + UI.MENU.ITEM[0].MEMO.START.width) / 2) + 'px';
		UI.MENU.TARGET.style.width = (maxWidth + UI.MENU.baseWidth + 50) + 'px';
	}
	UI.MENU.CALL(UI.MENU.ITEM[section]);
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


UI.CHANNELS = function (arr) {
	if (!UI.CHANNELS.MEMO) {
		//!\\ settings
		UI.CHANNELS.MEMO = {
			colWidth: 300,
			minMargin: 50,
			colExpand: 940,
			slideNum: 0,
			easing: FISICS.strongEaseOut,
			duration: 10
		};
	}
	UI.CHANNELS.SLIDE = function (WHO) {
		//!\\ prepare animation
		if (WHO && !UI.CHANNELS.RUNNING) {
			UI.CHANNELS.RUNNING = true;
			UI.CHANNELS.COUNT = 0;
			var ch = document.getElementById("channels");
			var memo = UI.CHANNELS.MEMO;
			memo.START = {};
			memo.END = {};
			memo.last = null;
			memo.margin = (!UI.CHANNELS.toggled) ? (UI.SCREEN._w - memo.colNum * memo.colWidth) / 2 : (UI.SCREEN._w - memo.colExpand) / 2;
			switch (WHO) {
			case 'next':
				memo.START.left = ch.offsetLeft;
				if (UI.CHANNELS.toggled) {
					memo.START.width = memo.colWidth;
					memo.last = memo.current;
				}
				memo.slideNum += (!UI.CHANNELS.toggled) ? memo.colNum : 1;
				memo.current = memo.slideNum;
				break;
			case 'prev':
				memo.START.left = ch.offsetLeft;
				if (UI.CHANNELS.toggled) {
					memo.START.width = memo.colWidth;
					memo.last = memo.current;
				}
				memo.slideNum -= (!UI.CHANNELS.toggled) ? memo.colNum : 1;
				memo.current = memo.slideNum;
				break;
			default: //!\\ expand || collapse
				UI.CHANNELS.toggled = (!UI.CHANNELS.toggled) ? true : false;
				if (!UI.CHANNELS.toggled) {}
				memo.current = memo.slideNum = WHO.channel;
				memo.callback = WHO.callback;
				var cur = UI.CHANNELS.list[memo.current].CHANNEL;
				cur._class = 'channel';
				cur.className = 'channel current';
				var ls = document.getElementById("left_side");
				memo.START = {
					left: ch.offsetLeft,
					margin: ls.offsetWidth,
					width: (UI.CHANNELS.toggled) ? memo.colWidth : memo.colExpand
				}


			}


			if (UI.CHANNELS.toggled) {
				if (memo.last != null) {
					var las = UI.CHANNELS.list[memo.last].CHANNEL;
					las.className = las._class = 'channel';
				}
				var cur = UI.CHANNELS.list[memo.current].CHANNEL;
				cur._class = 'channel toggled';
				cur.className = (memo.last != null) ? cur._class : cur._class + ' current';
				UI.CHANNELS.CURRENT(cur);
			}


			//!\\ x-position defence
			if (!UI.CHANNELS.toggled && memo.slideNum > UI.CHANNELS.list.length - memo.colNum) {
				memo.slideNum = UI.CHANNELS.list.length - memo.colNum
			}
			if (memo.slideNum < 0) {
				memo.slideNum = 0
			}
			//!\\ END animation params
			if (memo.START.margin) {
				memo.END.margin = (UI.CHANNELS.toggled) ? (UI.SCREEN._w - memo.colExpand) / 2 : (UI.SCREEN._w - UI.CHANNELS.MEMO.colNum * UI.CHANNELS.MEMO.colWidth) / 2;
			}
			memo.END.left = (!memo.END.margin) ? memo.margin - memo.slideNum * memo.colWidth : memo.END.margin - memo.slideNum * memo.colWidth;
			if (memo.START.width) {
				memo.END.width = (UI.CHANNELS.toggled) ? memo.colExpand : memo.colWidth;
			}
			//!\\ prepare frames
			UI.CHANNELS.FRAMES = [];
			for (var i = 0; i < memo.duration; i++) {
				UI.CHANNELS.FRAMES[i] = {
					left: memo.START.left + memo.easing(i, memo.END.left - memo.START.left, memo.duration)
				};
				if (memo.START.margin && memo.START.margin != memo.END.margin) {
					UI.CHANNELS.FRAMES[i].margin = memo.START.margin + memo.easing(i, memo.END.margin - memo.START.margin, memo.duration);
				}
				if (memo.START.width) {
					UI.CHANNELS.FRAMES[i].width = memo.START.width + memo.easing(i, memo.END.width - memo.START.width, memo.duration)
				}
			}

			//!\\ start animation
			UI.CHANNELS.interval = setInterval(function () {
				UI.CHANNELS.SLIDE()
			}, 30);

		} else if (WHO && UI.CHANNELS.RUNNING) {
			return false
		}


		UI.CHANNELS.FORMAT_TOOLS();
		//!\\ do animation
		var memo = UI.CHANNELS.MEMO;
		var ch = document.getElementById("channels");
		ch.style.left = UI.CHANNELS.FRAMES[UI.CHANNELS.COUNT].left + 'px';
		if (UI.CHANNELS.FRAMES[UI.CHANNELS.COUNT].margin) {
			var ls = document.getElementById("left_side");
			var rs = document.getElementById("right_side");
			ls.style.width = rs.style.width = UI.CHANNELS.FRAMES[UI.CHANNELS.COUNT].margin + 'px';
		}
		if (UI.CHANNELS.FRAMES[UI.CHANNELS.COUNT].width) {
			UI.CHANNELS.list[memo.current].CHANNEL.style.width = UI.CHANNELS.FRAMES[UI.CHANNELS.COUNT].width + 'px';
			if (memo.last == null && memo.current + 1 < UI.CHANNELS.list.length) {
				for (var e = memo.current + 1; e < UI.CHANNELS.list.length; e++) {
					UI.CHANNELS.list[e].CHANNEL.style.left = (e * memo.colWidth + UI.CHANNELS.FRAMES[UI.CHANNELS.COUNT].width - memo.colWidth) + 'px';
				}
			}
			if (memo.last != null) {
				UI.CHANNELS.list[memo.last].CHANNEL.style.width = (memo.colExpand - UI.CHANNELS.FRAMES[UI.CHANNELS.COUNT].width + memo.colWidth) + 'px';
				if (memo.last > memo.current) {
					UI.CHANNELS.list[memo.last].CHANNEL.style.left = (memo.last * memo.colWidth + UI.CHANNELS.FRAMES[UI.CHANNELS.COUNT].width - memo.colWidth) + 'px';
				} else {
					UI.CHANNELS.list[memo.current].CHANNEL.style.left = (memo.current * memo.colWidth - UI.CHANNELS.FRAMES[UI.CHANNELS.COUNT].width + memo.colExpand) + 'px';
				}
			}
		}
		UI.CHANNELS.COUNT++;
		//!\\ end animation
		if (UI.CHANNELS.COUNT == memo.duration) {
			clearInterval(UI.CHANNELS.interval);
			UI.CHANNELS.RUNNING = false;
			if (memo.callback) {
				memo.callback();
				memo.callback = null;
			}
		}
	};
	UI.CHANNELS.FORMAT_TOOLS = function () {
		var _end = (!UI.CHANNELS.toggled) ? UI.CHANNELS.MEMO.colNum : 1;
		if ((UI.CHANNELS.MEMO.colNum >= UI.CHANNELS.list.length && !UI.CHANNELS.toggled) || UI.CHANNELS.list.length == 1) {
			UI.CHANNELS.NEXT.style.display = 'none';
			UI.CHANNELS.PREV.style.display = 'none';
		} else if (UI.CHANNELS.MEMO.slideNum == 0) {
			UI.CHANNELS.NEXT.style.display = '';
			UI.CHANNELS.PREV.style.display = 'none';
		} else if (UI.CHANNELS.MEMO.slideNum == UI.CHANNELS.list.length - _end) {
			UI.CHANNELS.NEXT.style.display = 'none';
			UI.CHANNELS.PREV.style.display = '';
		} else {
			UI.CHANNELS.NEXT.style.display = '';
			UI.CHANNELS.PREV.style.display = '';
		}
	};
	UI.CHANNELS.FORMAT = function () {
		//!\\ sizes
		UI.CHANNELS.MEMO.colNum = Math.floor((UI.SCREEN._w - UI.CHANNELS.MEMO.minMargin * 2) / UI.CHANNELS.MEMO.colWidth);
		if (UI.CHANNELS.MEMO.colNum >= UI.CHANNELS.list.length) {
			UI.CHANNELS.MEMO.colNum = UI.CHANNELS.list.length
		}
		if (UI.CHANNELS.MEMO.colNum == 0) {
			colNum = 1
		}
		var ch = document.getElementById("channels");
		var ls = UI.CHANNELS.LEFT;
		var rs = UI.CHANNELS.RIGHT;
		UI.CHANNELS.MEMO.margin = (!UI.CHANNELS.toggled) ? (UI.SCREEN._w - UI.CHANNELS.MEMO.colNum * UI.CHANNELS.MEMO.colWidth) / 2 : (UI.SCREEN._w - UI.CHANNELS.MEMO.colExpand) / 2;
		ls.style.width = rs.style.width = UI.CHANNELS.MEMO.margin + 'px';

		if (!UI.CHANNELS.toggled && UI.CHANNELS.list.length - UI.CHANNELS.MEMO.colNum < UI.CHANNELS.MEMO.slideNum) {
			UI.CHANNELS.MEMO.slideNum = UI.CHANNELS.list.length - UI.CHANNELS.MEMO.colNum;
		} else if (UI.CHANNELS.toggled) {
			UI.CHANNELS.MEMO.slideNum = UI.CHANNELS.MEMO.current;
		}
		UI.CHANNELS.FORMAT_TOOLS();
		ch.style.left = (UI.CHANNELS.MEMO.margin - UI.CHANNELS.MEMO.slideNum * UI.CHANNELS.MEMO.colWidth) + 'px';

	};
	UI.CHANNELS.CREATE = function () {
		/////////////////
		////////////////
		$("#main").html('');
		UI.LOADING(false);
		UI.CHANNELS.toggled = false;
		var ch = document.createElement('div');
		ch.id = "channels";
		$("#main").append(ch);

		$(window).resize(UI.CHANNELS.FORMAT);
		UI.CHANNELS.FORMAT();
		////////////////
		////////////////
		for (var i = 0; i < UI.CHANNELS.list.length; i++) {
			var col = UI.CHANNELS.list[i].CHANNEL = document.createElement('div');
			col._index = i;
			col._class = 'channel';
			col.className = 'channel';
			with(col.style) {
				width = UI.CHANNELS.MEMO.colWidth + 'px';
				left = UI.CHANNELS.MEMO.colWidth * i + 'px';
			}
			ch.appendChild(col);

			col._content = document.createElement('div');
			col._content._parent = col;
			col._content.className = 'c_content';
			//col._content.innerHTML='<b>'+i+'</b> '+UI.CHANNELS.list[i].label;
			col.appendChild(col._content);

			col._label = document.createElement('div');
			col._label._parent = col;
			col._label.className = 'c_label';
			col._label.innerHTML = '<div class="c_text">' + UI.CHANNELS.list[i].label + '</div><div class="c_gradient"></div><div class="c_ico"></div>';
			col.appendChild(col._label);

			//!\\ buttons & events
			if (UI.CHANNELS.list.length != 1) {
				col.onmouseover = function () {
					UI.CHANNELS.CURRENT(this);
				}
				//col.onmouseout=function(){this.className=this._class}
				col._label.onclick = function () {
					UI.CHANNELS.SLIDE({
						channel: this._parent._index
					});
				};
				col._label.onmouseover = function () {
					this.className = 'c_label label_over';
					if (!UI.CHANNELS.toggled) {
						_baloon('Expand')
					} else {
						_baloon('Collapse')
					}
				};
				col._label.onmouseout = function () {
					this.className = 'c_label';
				};
			} else {
				//!\\ details & search results

				//col._label.style.cursor = 'default'; // uncomment & comment rows below if no events to label!
				col._label.className = 'c_label c_close';

				col._label.onclick = function () {
					$.bbq.pushState('channels', 2);
				};
				col._label.onmouseover = function () {
					this.className = 'c_label c_close label_over';
					_baloon('Close {id=' + documentIdentifier + '}');
				};
				col._label.onmouseout = function () {
					this.className = 'c_label c_close';
				};
			}
		}
		UI.CHANNELS.CURRENT(UI.CHANNELS.list[0].CHANNEL);
	};
	UI.CHANNELS.CURRENT = function (trg) {
		if (UI.CHANNELS.MEMO._current) {
			if (UI.CHANNELS.MEMO._current != trg) UI.CHANNELS.MEMO._current.className = UI.CHANNELS.MEMO._current._class;
			else return false;
		}
		UI.CHANNELS.MEMO._current = trg;
		trg.className = trg._class + ' current';
	};
	UI.CHANNELS.FILL = function (WHO) {
		var col = UI.CHANNELS.list[WHO].CHANNEL;
		var json = UI.CHANNELS.list[WHO].documents;
		col.REVIEW = [];
		for (var i = 0; i < json.length; i++) {
			var tit = '<div class="c_title">' + json[i].title + '</div>';
			var txt = '<div class="c_summary">' + json[i].summary + '</div>';
			var tim = '';
			if (json[i].dateTime) {
				/**/
				var _time = new Date(json[i].dateTime);
				var _d = _time.getDate();
				var _m = months[_time.getMonth()];
				var _y = _time.getFullYear();
				//var _t = '';
				//_t += '/' + ((_m < 10) ? '0' + _m : _m);
				//_t += '/' + _time.getFullYear();
				tim = '<div class="c_date">'+ _m +' '+ _d +', '+ _y +'</div>';
				/**/
			}
			col.REVIEW[i] = document.createElement('div');
			col.REVIEW[i]._parent = col;
			col.REVIEW[i]._index = i;
			col.REVIEW[i]._id = json[i].clusterUri;
			col.REVIEW[i]._title = json[i].title;
			col.REVIEW[i].className = 'c_review';
			col.REVIEW[i].innerHTML = tim + tit + img + txt;
			col.REVIEW[i].onmouseover = function () {
				this.className = 'c_review active'
			};
			col.REVIEW[i].onmouseout = function () {
				this.className = 'c_review'
			};
			col.REVIEW[i].onclick = function () {
				UI.tempTitle = this._title
				$.bbq.pushState(UI.composeDetailsRequest(this._id), 2);
			};
			col._content.appendChild(col.REVIEW[i]);
		}
	}
	UI.CHANNELS.renderScore = function (score, label, id) {
		var _percent = (score.tolerance) ? Math.round((score.current - score.last) * (100 - 100 / score.steps) / score.tolerance + 100 / score.steps) : 100;
		return '<div class="d_score" onmouseover="_baloon(\'+ Add Search Concept\')" onclick="UI.addConceptInSearch(\'' + id + '\',\'' + label + '\');"><div class="d_scoreChart" style="width:' + _percent + '%;"></div><div class="d_scoreLabel">' + label + '</div></div>';
	};
	UI.CHANNELS.DETAILS = function () {
		var col = UI.CHANNELS.list[0].CHANNEL;
		var json = UI.CHANNELS.list[0].json;
		/*
			var img=(json.imageUri)?'<div class="d_image"><img src="asset/get?uri='+json.imageUri+'"></div>':'';
			var tit='<div class="d_title">'+json.title+'</div>';
			var txt='<div class="d_summary">'+json.summary+'</div>';
			var article='', concept='', similar='';
			for(var i=0; i<json.articles.length; i++){
				article+='<a class="d_article" href="'+json.articles[i].uri+'" target="_blank">'+json.articles[i].title+'</a>';
			}
			//scores (concepts)
			var _column=Math.round(json.concepts.length/2);
			var _score={
				steps:5,
				tolerance:(json.concepts[0].score-json.concepts[json.concepts.length-1].score),
				last:json.concepts[json.concepts.length-1].score
			};
			for(var i=0; i<json.concepts.length; i++){
				_score.current=json.concepts[i].score;
				concept+=UI.CHANNELS.renderScore(_score,json.concepts[i].label,json.concepts[i].inst);
			}*/
		/*PUBLISHING DEMO!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!*
			concept+='<div class="d_column">';
			for(var i=0; i<_column; i++){
				_score.current=json.concepts[i].score;
				concept+=UI.CHANNELS.renderScore(_score,json.concepts[i].label,json.concepts[i].inst);
			}
			concept+='</div><div class="d_column">';
			for(var e=_column; e<json.concepts.length; e++){
				_score.current=json.concepts[e].score;
				concept+=UI.CHANNELS.renderScore(_score,json.concepts[e].label,json.concepts[i].inst);
			}
			concept+='</div><div style="clear:left;"></div>';
			/**/

		//similar

		/*
			for(var i=0; i<json.similarClusters.length; i++){
				var simimg=(json.similarClusters[i].imageUri)?'<img src="'+json.similarClusters[i].imageUri+'" />':'';
				similar+='<div class="d_similar" onclick="UI.callMonsters(\''+json.similarClusters[i].clusterUri+'\')" onmouseover="this.className=\'d_similar hovered\'" onmouseout="this.className=\'d_similar\'"><div class="similarTitle">'+json.similarClusters[i].title+'</div>'+simimg+'</div>';
			}
			/**/

		col.DETAIL = document.createElement('div');
		col.DETAIL._parent = col;
		col.DETAIL._index = i;
		col.DETAIL._id = json.clusterUri;
		col.DETAIL.className = 't_container';

		/*PUBLISHING DEMO!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!*/
		//col.DETAIL.innerHTML = '<div class="d_content">'+tit + img + txt + '<div class="d_concepts">'+concept+'</div><div class="d_articles">'+article+'</div></div><div class="d_similars">'+similar+'</div>';
		//col.DETAIL.innerHTML = '<div class="d_content"><div class="d_ceccio"><div class="d_concepts">'+concept+'</div><div class="d_articles">'+article+'</div></div>' + tit + img + txt + '</div>';
		documentIdentifier = json.id.substring(json.id.lastIndexOf('/') + 1);
		col.DETAIL.innerHTML = featuresHTML(json["document-parts"]["feature-set"]) + '<div id="__bak" class="t_background"></div><div id="__tit" class="t_title"></div><div id="__sum" class="t_summary"></div><div id="__txt" class="t_text"></div><div id="__ann" class="t_annotations"></div>';
		col._content.appendChild(col.DETAIL);
		UI.ANNOTATE(json);

		col.EXTRAS = document.createElement('div');
		col.EXTRAS.className = 't_extras';
		col.EXTRAS.innerHTML = '<fieldset class="extras_fieldset"><legend>Top Concepts</legend><div id="extras_concepts"></div></fieldset><fieldset class="extras_fieldset"><legend>Similar Articles</legend><div id="extras_similars"></div>';
		col._content.appendChild(col.EXTRAS);

		$.ajax({
			url: 'clusterConcepts?id='+encodeURIComponent( json.id )+'&numConcepts=10',
			dataType: 'json',
			success: function(v){
				var concept = '', _score={
									steps:5,
									tolerance:(v[0].score-v[v.length-1].score),
									last:v[v.length-1].score
								 };
				for(var i=0; i<v.length; i++){
					_score.current=v[i].score;
					concept+=UI.CHANNELS.renderScore(_score,v[i].label,v[i].inst);
				}
				$('#extras_concepts').html(concept);
			},
			error: function (v) {
				$('#extras_concepts').parent().hide();
			}
		});
		setTimeout(function(){
		$.ajax({
			url: 'clusterSimilar?id='+encodeURIComponent( json.id )+'&numSimilar=10',
			dataType: 'json',
			success: function(v){
				var similar = '';
				if(!document.sanitizer){
					document.sanitizer = document.createElement('div');
					with(document.sanitizer.style){
						position = 'absolute';
						top = left = '-1000px';
						width = height = '10px';
						overflow = 'hidden';
						display = 'none';
					}
					document.body.appendChild(document.sanitizer);
				}
				for(var i=1; i<v.length; i++){
					var __t = '';
					if(v[i].publishedTime && v[i].publishedTime.millis){
						var _time = new Date(v[i].publishedTime.millis);
						var _d = _time.getDate();
						var _m = months[_time.getMonth()];
						var _y = _time.getFullYear();
						__t = '<div class="similarDate">'+ _m +' '+ _d +', '+ _y +'</div>';
					}
					document.sanitizer.innerHTML = v[i].title;
					v[i].title = document.sanitizer.textContent || document.sanitizer.innerText;
					document.sanitizer.innerHTML = v[i].content;
					v[i].content = document.sanitizer.textContent || document.sanitizer.innerText;
					similar+='<div class="d_similar" onclick="UI.callMonsters(\''+v[i].owlimUri+'\',\''+v[i].title+'\')" onmouseover="this.className=\'d_similar hovered\'" onmouseout="this.className=\'d_similar\'">'+__t+'<div class="similarTitle">'+v[i].title+'</div>'+v[i].content+'</div>';
				}
				$('#extras_similars').html(similar);
			},
			error: function (v) {
				$('#extras_similars').parent().hide();
			}
		});}, 100);

	}
	UI.CHANNELS.LOAD = function () {
		$.ajax({
			url: "getChannel?uri=" + UI.CHANNELS.list[UI.CHANNELS.countList].url,
			//url: UI.CHANNELS.list[UI.CHANNELS.countList].url,
			dataType: 'json',
			success: function (data) {
				if (location.hash != '#channels') {
					return false
				}
				if (UI.CHANNELS.countList == 0) {
					UI.CHANNELS.CREATE()
				}
				UI.CHANNELS.list[UI.CHANNELS.countList].documents = data;
				UI.CHANNELS.FILL(UI.CHANNELS.countList);
				UI.CHANNELS.countList++;
				if (UI.CHANNELS.countList < UI.CHANNELS.list.length) {
					UI.CHANNELS.LOAD();
				} else {
					UI.CHANNELS.listCopy = UI.CHANNELS.list.slice();
				}
			},
			error: function () {
				UI.MESSAGE('Failure')
			}
		});
	};
	UI.CHANNELS.SEARCH = function (_url) {
		var _success;
		if (/^search/i.test(_url)) {
			_success = function (data) {
				if (location.hash == "#channels") {
					return false
				}
				UI.CHANNELS.list = [{
					label: 'Search Results',
					documents: data.documents
				}];
				UI.CHANNELS.CREATE();
				UI.CHANNELS.FILL(0);
				UI.CHANNELS.SLIDE({
					channel: 0
				});
			}
		} else if (/^clusterDetails/i.test(_url)) {
			_success = function (data) {
				if (location.hash == "#channels") {
					return false
				}

				var aTitle = locateDocumentTitle(data["document-parts"]["feature-set"]);
				if (!aTitle) {
					aTitle = 'Details';
				}

				UI.CHANNELS.list = [{
					label: (UI.tempTitle) ? UI.tempTitle : aTitle,
					json: data
				}];
				UI.CHANNELS.CREATE();
				//UI.CHANNELS.DETAILS();
				UI.CHANNELS.SLIDE({
					channel: 0,
					callback: function () {
						UI.CHANNELS.DETAILS()
					}
				});
			}
		}

		$.ajax({
			url: _url, //"search",
			//data: _data,//UI.composeSerachRequest(),
			dataType: 'json',
			success: _success,
			error: function () {
				UI.MESSAGE('Failure')
			}
		});
	};
	///////////////////////////////////////////////////////

	if (!UI.CHANNELS.listCopy) {
		//!\\ init (must be present before all !!!)
		if (arr && arr != channels) {
			UI.CHANNELS.SEARCH(arr);
			UI.CHANNELS.countList = 0;
			return false;
		}
		UI.CHANNELS.list = [];
		UI.CHANNELS.countList = 0;
		for (var i = 0; i < arr.length; i++) {
			for (var ii in arr[i]) {
				UI.CHANNELS.list[i] = {
					label: ii,
					url: arr[i][ii]
				}
			}
		}
		//$("#main").html('');
		UI.CHANNELS.LOAD();
	} else {
		if (!arr) {
			//!\\ reload chached channels
			UI.CHANNELS.list = UI.CHANNELS.listCopy;
			UI.CHANNELS.CREATE();
			for (var i = 0; i < UI.CHANNELS.list.length; i++) {
				UI.CHANNELS.FILL(i);
			}
		} else {
			//!\\ details, search and so on...
			UI.CHANNELS.SEARCH(arr);
		}

	}

};

UI.composeSerachRequest = function () {
	var k = "";
	var e = "";
	if ($('#token-input-q').val().length > 0) {
		k = encodeURIComponent($('#token-input-q').val());
	} else {
		if (typeof (sessionStorage.getItem("selectedKeywords")) != 'undefined' && sessionStorage.getItem("selectedKeywords") != null && sessionStorage.getItem("selectedKeywords").length > 0) {
			k = encodeURIComponent(sessionStorage.getItem("selectedKeywords"));
		}
	}

	if (typeof (sessionStorage.getItem("selectedEntities")) != 'undefined' && sessionStorage.getItem("selectedEntities") != null) {
		e = encodeURIComponent(sessionStorage.getItem("selectedEntities"));
	}
	return Base64.encode('search?q=' + k + '&inst=' + e);
}
UI.composeDetailsRequest = function (_id) {
	_id = encodeURIComponent(_id);
	return Base64.encode('clusterDetails?id=' + _id);
}
UI.addConceptInSearch = function (id, label) {
	$("#q").tokenInput("add", {
		inst: id,
		label: label
	});
}
UI.callMonsters = function (_id, title) {
	if(title){
		UI.tempTitle = title;
	}
	$.bbq.pushState(UI.composeDetailsRequest(_id), 2);
};
