/*
 * Addmind Interfaces™
 * Copyright (C) 2002-2012 Yavor Boykov Panchev
 * 
 * Licensed under the terms of the GNU General Public License:
 * 		http://www.opensource.org/licenses/gpl-license.php
 * 
 * For further information visit:
 * 		http://www.addmind.org/
 *
 */

var browserType=navigator.userAgent.toLowerCase();
_ie=(browserType.indexOf("msie")!=-1)?{ver:browserType.substring(browserType.lastIndexOf("msie")+5,browserType.lastIndexOf("msie")+6)}:false;
_ff=(browserType.indexOf("firefox")!=-1)?{ver:browserType.substring(browserType.lastIndexOf("/")+1,browserType.lastIndexOf("/")+2)}:false;
_ns=(browserType.indexOf("netscape")!=-1&&browserType.indexOf("chrome")==-1)?true:false;
_sf=(browserType.indexOf("safari")!=-1)?true:false;
_cr=(browserType.indexOf("chrome")!=-1)?true:false;
_op=(window.opera)?{ver:browserType.substring(Number(browserType.indexOf("/")+1),Number(browserType.indexOf("/")+2))}:false;
_mobile=(window.deviceorientation)?true:false;
_mobile=((/iphone|ipod|android|ie|blackberry|fennec/).test(browserType))?true:false;
DEBUG=true;
function debug(){
	if(!DEBUG){return false}
	var what="";
	if(!document.report){
		document.report=document.createElement("div");
		document.report.tool='&nbsp; &nbsp; &nbsp; <span onclick="document.report._reset()" style="position:absolute; right:0px; top:0px; padding:2px; cursor:pointer; background-color:#ff0000; font-weight:bold; line-height:.7em">X</span>';
		document.report.separator='--------------------------<br>';
		document.report._reset=function(){
			document.report.innerHTML="debug console™"+document.report.tool+"<br>";
		};
		document.body.appendChild(document.report);
		with(document.report.style){
			position="fixed";
			zIndex="999";
			top="0px";
			left="0px";
			padding="2px";
			color="#fff";
			backgroundColor="#000";
			font="10px verdana";
			border="1px solid #fff";
			lineHeight="1.4em";
			//whiteSpace="nowrap";
		}
		//document.report.noWrap=true;
		setOpacity(document.report,60);
		document.report.ondblclick=document.report._reset;
	}
	with(document.report.style){width="";height="";overflow="";}
	var win=getWindowSize();
	for(var j=0; j<arguments.length; j++){
		what+=(j==0)?arguments[j]:separator+arguments[j];
	}
	if(document.report.offsetHeight>win._h-30){document.report.innerHTML=document.report.separator+what+document.report.tool+"<br>"}
	else{document.report.innerHTML+=(document.report.innerHTML=="")?document.report.separator+what+document.report.tool+"<br>":document.report.separator+what+"<br>"};
}

function AJAX(url,callbackFunction){
	var that=this;
	this.update=function(passData,postMethod){
		that.AJAX = null;
		that.AJAX=(window.XMLHttpRequest)?new XMLHttpRequest():new ActiveXObject("Microsoft.XMLHTTP");
		if(!that.AJAX){initMessage('HTTPREQUEST IS INACTIVE!!!!'); return false}
		else{
			that.AJAX.onreadystatechange=function(){
				if(that.AJAX.readyState==4){
					that.callback(that.AJAX.responseText,that.AJAX.status,that.AJAX.responseXML,that);
					that.AJAX=null;
				}
			}
			if(/post/i.test(postMethod)){
				var uri=urlCall;
				that.AJAX.open("POST", uri, true);
				that.AJAX.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
				that.AJAX.setRequestHeader("Content-Length", passData.length);
				that.AJAX.send(passData);
			}else{
				var uri=urlCall+'?'+passData;
				that.AJAX.open("GET", uri, true);
				that.AJAX.send(null);
			}
			return true;
		}
	}
	var urlCall = url;
	this.callback = callbackFunction || function () { };
}


function getWindowSize() {
	var myWidth = 0, myHeight = 0;
	if( typeof( window.innerWidth ) == 'number' ) {
		//Non-IE
		myWidth = window.innerWidth;
		myHeight = window.innerHeight;
	} else if( document.documentElement && ( document.documentElement.clientWidth || document.documentElement.clientHeight ) ) {
		//IE 6+ in 'standards compliant mode'
		myWidth = document.documentElement.clientWidth;
		myHeight = document.documentElement.clientHeight;
	} else if( document.body && ( document.body.clientWidth || document.body.clientHeight ) ) {
		//IE 4 compatible
		myWidth = document.body.clientWidth;
		myHeight = document.body.clientHeight;
	}
	return {_w:myWidth,_h:myHeight};
}

function getXY(obj,refobj_optional){
	var x=0,y=0;
	while(obj!=refobj_optional){
		x+=obj.offsetLeft;
		y+=obj.offsetTop;
		obj=obj.offsetParent;
	}
	return {_x:x,_y:y};
}

function executeJavascript(trg){
	if(!trg){trg=document}
	var scr=trg.getElementsByTagName("script");
	for(var s=0; s<scr.length; s++){
		var cod=(scr[s].firstChild)?scr[s].firstChild.nodeValue:scr[s].nodeValue;
		if(_ie){cod=scr[0].innerHTML}
		if(cod){eval(cod)}
	}
}

function setOpacity(obj,opacity){
	//var rst=(opacity == 100);
	var rst;
	if(opacity == 0){
		obj.style.visibility='hidden';
		return false;
	}
	obj.style.filter=(!rst)?"alpha(opacity:"+opacity+")":"";// IE/Win
	obj.style.KHTMLOpacity = (!rst)?opacity/100:"";// Safari<1.2, Konqueror
	obj.style.MozOpacity = (!rst)?opacity/100:"";// Older Mozilla and Firefox
	obj.style.opacity = (!rst)?opacity/100:"";// CSS3
	if(obj.style.visibility=="hidden"){obj.style.visibility=""}
}

function _baloon(inf,sty){
	if(!document.baloon){
		document.baloon=document.createElement("div");
		document.body.appendChild(document.baloon);
		document.baloon.className="baloon";
		document.baloon.innerHTML="<div></div>";
		createListener("mouseout",function(){_baloon()},document);
		createListener("mousedown",function(){_baloon()},document);
	}
	//document.baloon.className=(sty)?"baloon "+sty:"baloon";
	if(sty){
		document.baloon.changedStyle = sty.name;
		document.baloon.style[sty.name] = sty.value;
	}else if(document.baloon.changedStyle){
		document.baloon.style[document.baloon.changedStyle]='';
		document.baloon.changedStyle = null;
	}
	if(inf){
		document.baloon.firstChild.innerHTML=inf;
		if(document.baloon.offsetWidth>330) document.baloon.style.width="330px";
		document.baloon.hlim=(_ie)?document.body.offsetWidth-document.baloon.offsetWidth:window.innerWidth-document.baloon.offsetWidth;
		document.baloon.vlim=(_ie)?document.body.offsetHeight-document.baloon.offsetHeight:window.innerHeight-document.baloon.offsetHeight;
		createListener("mousemove",dragBaloon,document);
	}else{
		document.baloon.style.width="";
		document.baloon.firstChild.innerHTML="";
		deleteListener("mousemove",dragBaloon,document);
		document.baloon.style.left="-1000px";	
	}
}

function dragBaloon(e){
	var tip=document.baloon;
	if(!e){e=event}
	tip.style.left=(e.clientX>=tip.hlim)?(e.clientX-document.baloon.offsetWidth+8)+"px":e.clientX+"px";//-tip.offsetWidth/2; //LEFT
	//tip.style.left=(e.clientX-document.baloon.offsetWidth/2+7)+"px"// CENETR
	var _toppos=e.clientY-document.baloon.offsetHeight-5;
	tip.style.top=(e.clientY+20>=tip.vlim)?(e.clientY-document.baloon.offsetHeight-5)+"px":(e.clientY+20)+"px"; //BELOW
	//tip.style.top=(_toppos<0)?(e.clientY+20)+"px":_toppos+"px"; //ABOVE
}

var _COOKIE={
	set:function(name,value,days){
		if(!value){value=""}
		if (days) {
			var date = new Date();
			date.setTime(date.getTime()+(days*24*60*60*1000));
			var expires = "; expires="+date.toGMTString();
		}else{ var expires = ""}
		var srvhst="";//(location.href.indexOf('http://')!=-1&&serviceHost!=undefined)?" domain=."+serviceHost:""; ////////
		document.cookie = name+"="+escape(value)+expires+"; path=/;"+srvhst;
	},
	read:function(name){
		var nameEQ = name + "=";
		var ca = document.cookie.split(';');
		for(var i=0;i < ca.length;i++) {
			var c = ca[i];
			while (c.charAt(0)==' '){ c = c.substring(1,c.length) }
			if (c.indexOf(nameEQ) == 0){ return unescape(c.substring(nameEQ.length,c.length)) }
		}
		return null;	
	},
	del:function(name){
		_COOKIE.set(name,"",-1);
	}
};

function _CSS(el,styleProp) {
	//EXAMPLE: var sidebarWidth = _CSS('sidebar','width');
    if(typeof(el)=="string"){el = document.getElementById(el)}
    var result;
    if(el.currentStyle) {
        result = el.currentStyle[styleProp];
    } else if (window.getComputedStyle) {
        result = document.defaultView.getComputedStyle(el,null).getPropertyValue(styleProp);
    } else {
        result = 'unknown';
    }
    return result;
}

function _DEPTH(trg,front_back,min_opacity){
	var point=parseInt(trg.style.zIndex);
	trg.style.zIndex=AI.wins.depth+AI.wins.item.length-1;
	var coef=40/AI.wins.item.length;
	AI.wins.current=trg;
	setOpacity(trg,100);
	for(var i=0; i<AI.wins.item.length; i++){
		if(trg!=AI.wins.item[i]){
			var pnts=parseInt(AI.wins.item[i].style.zIndex);
			if(pnts>point){pnts--; AI.wins.item[i].style.zIndex=pnts;}
			nm=50+(pnts-AI.wins.depth)*coef+coef;//75;
			setOpacity(AI.wins.item[i],nm);
		}
	}
}

function _FX(val,trg,reskin){ //vat = 0:out 1:over 2:press 3:select 4:reset 5:loading -1:disable
	if(!val){val=0}
	if(!trg&&this.parentNode){trg=this}
	if(!trg){return}
	if(trg.fxStatus!=val){trg.fxStatus=val}
	else if(!reskin){return}

	if(!trg._class&&trg.className){trg._class=trg.className}
	if(trg._class){
		if(val==1){trg.className=trg._class+" over";}
		else if(val==2||val==3){trg.className=trg._class+" press"}
		else if(val==-1){trg.className=trg._class+" disable"}
		else if(val==5){trg.className=trg._class+" loading"}
		else{trg.className=trg._class}
	}
	switch(val){
		case -1, 5:
			stopEvent(trg);
			if(trg.parentNode&&trg==trg.parentNode._select){
				trg.parentNode._select=null;
			}
			break;
		case 3:
			if(trg.parentNode&&trg!=trg.parentNode._select){
				if(trg.parentNode._select&&typeof(trg.parentNode._select)=="object"){
					_FX(0,trg.parentNode._select);
					startEvent(trg.parentNode._select);
				}
				trg.parentNode._select=trg;
				stopEvent(trg);
			}
			break;
		case 4:
			if(trg.parentNode&&trg==trg.parentNode._select){
				_FX(0,trg.parentNode._select);
				startEvent(trg.parentNode._select);
				trg.parentNode._select=null;
			}
			break;
	}
}

var _SKIN=function(theme,param,trg){ //[out,over,press] ["red","green","blue"]
	trg=(trg)?trg:this;
	if(!document._themes){document._themes=[]}
	if(!document._themes[theme]){document._themes[theme]={}}
	if(!document._themes[theme]._target){document._themes[theme]._target=[]}
	if(typeof(param)=='object'){document._themes[theme].S=param}
	if(param==true){
		document._themes[theme]._target[document._themes[theme]._target.length]=trg;
		trg._theme=theme;
		_FX(this.fxStatus,trg);
	}else{
		if(document._themes[theme]._target.length>0){
			for(var i=0; i<document._themes[theme]._target.length; i++){
				var mc=document._themes[theme]._target[i];
				_FX(mc.fxStatus,mc,true);
			}
		}
	}
};

var FISICS={ //function( Time, Change, Duration, [ Begin, P, A ] )
	normal:function(t,c,d,b){
		if(!b){b=0}
		if ((t/=d)==1){return b+c;}
		return t*c/d;
	},
	elasticEaseOut:function(t,c,d,b,a,p){
		if(!b){b=0}
		if (t==0) return b;  if ((t/=d)==1) return b+c;  if (!p) p=d*.3;
		if (!a || a < Math.abs(c)) { a=c; var s=p/4; }
		else var s = p/(2*Math.PI) * Math.asin (c/a);
		return (a*Math.pow(2,-10*t) * Math.sin( (t*d-s)*(2*Math.PI)/p ) + c + b);
	},
	elasticEaseIn:function(t,c,d,b,a,p){
		if(!b){b=0}
		if (t==0) return b;  
		if ((t/=d)==1) return b+c;  
		if (!p) p=d*.3;
		if (!a || a < Math.abs(c)) {
			a=c; var s=p/4;
		}else{
			var s = p/(2*Math.PI) * Math.asin (c/a);
		}
		return -(a*Math.pow(2,10*(t-=1)) * Math.sin( (t*d-s)*(2*Math.PI)/p )) + b;
	},
	elasticEaseInOut:function (t,c,d,b,a,p){
		if(!b){b=0}
		if (t==0) return b;
		if ((t/=d/2)==2) return b+c;
		if (!p) p=d*(.3*1.5);
		if (!a || a < Math.abs(c)) {var a=c; var s=p/4; }
		else var s = p/(2*Math.PI) * Math.asin (c/a);
		if (t < 1) return -.5*(a*Math.pow(2,10*(t-=1)) * Math.sin( (t*d-s)*(2*Math.PI)/p )) + b;
		return a*Math.pow(2,-10*(t-=1)) * Math.sin( (t*d-s)*(2*Math.PI)/p )*.5 + c + b;
	},
	regularEaseOut:function(t,c,d,b){
		if(!b){b=0}
		return -c *(t/=d)*(t-2) + b;
	},
	regularEaseIn:function(t,c,d,b){
		if(!b){b=0}
		return c*(t/=d)*t + b;
	},
	regularEaseInOut:function(t,c,d,b){
		if(!b){b=0}
		if ((t/=d/2) < 1) return c/2*t*t + b;
		return -c/2 * ((--t)*(t-2) - 1) + b;
	},
	bounceEaseOut:function(t,c,d,b){
		if(!b){b=0}
		if ((t/=d) < (1/2.75)) {
			return c*(7.5625*t*t) + b;
		} else if (t < (2/2.75)) {
			return c*(7.5625*(t-=(1.5/2.75))*t + .75) + b;
		} else if (t < (2.5/2.75)) {
			return c*(7.5625*(t-=(2.25/2.75))*t + .9375) + b;
		} else {
			return c*(7.5625*(t-=(2.625/2.75))*t + .984375) + b;
		}
	},
	bounceEaseIn:function(t,c,d,b){
		if(!b){b=0}
		return c - this.bounceEaseOut (d-t, 0, c, d) + b;
	},
	bounceEaseInOut:function(t,c,d,b){
		if(!b){b=0}
		if (t < d/2) return this.bounceEaseIn (t*2, 0, c, d) * .5 + b;
		else return this.bounceEaseOut (t*2-d, 0, c, d) * .5 + c*.5 + b;
	},
	strongEaseOut:function(t,c,d,b){
		if(!b){b=0}
		return c*((t=t/d-1)*t*t*t*t + 1) + b;
	},
	strongEaseIn:function(t,c,d,b){
		if(!b){b=0}
		return c*(t/=d)*t*t*t*t + b;
	},
	strongEaseInOut:function(t,c,d,b){
		if(!b){b=0}
		if ((t/=d/2) < 1) return c/2*t*t*t*t*t + b;
		return c/2*((t-=2)*t*t*t*t + 2) + b;
	},
	backEaseOut:function(t,c,d,b,a,p){
		if(!b){b=0}
		if (s == undefined) var s = 1.70158;
		return c*((t=t/d-1)*t*((s+1)*t + s) + 1) + b;
	},
	backEaseIn:function(t,c,d,b,a,p){
		if(!b){b=0}
		if (s == undefined) var s = 1.70158;
		return c*(t/=d)*t*((s+1)*t - s) + b;
	},
	backEaseInOut:function(t,c,d,b,a,p){
		if(!b){b=0}
		if (s == undefined) var s = 1.70158; 
		if ((t/=d/2) < 1) return c/2*(t*t*(((s*=(1.525))+1)*t - s)) + b;
		return c/2*((t-=2)*t*(((s*=(1.525))+1)*t + s) + 2) + b;
	}
};

function argumentsEvent(arg){
	var target, listener, type, full;
	for(var i=0; i<arg.length; i++){
		var tp=typeof(arg[i]);
		if(tp=="object"){target=arg[i]}
		else if(tp=="function"){listener=arg[i]}
		else if(tp=="string"){
			if(!type){type=arg[i]}
			else{listener=arg[i]}
		}else if(tp=="boolean"){full=arg[i]}
	}
	return {target:target,listener:listener,type:type,full:full};
}
function callEvent(type,element){
	if(!element){element=document}
	if(document.createEventObject){// dispatch for IE
		var evt = document.createEventObject();
		return element.fireEvent('on'+type,evt);
	}
	else{// dispatch for firefox + others
		var evt = document.createEvent("HTMLEvents");
		evt.initEvent(type, true, true );//event (type,bubbling,cancelable)
		return !element.dispatchEvent(evt);
	}
};
function observeEvent(e){
	var targ;
	if(!e){e=window.event}
	if(e.target){targ=e.target}
	else if(e.srcElement){targ=e.srcElement}
	if(targ&&targ.nodeType==3){targ=targ.parentNode}
	return {target:targ,event:e,type:e.type};	
};
function startEvent(target,type,listener){
	/**/
	if(!target._eventOff){
		target._eventOff=[];

	}
	if(!target._event){
		if(type&&listener){
			target._test=function(evt,fun){
				var exp=new RegExp(fun,"gi");
				if(!this._event[evt]){return false}
				if(exp.test(this._event[evt])){return true}
				else{return false}
			}
			target._event=[];
			target._event[type]=listener;
			eval("target.on"+type+"=function(e){"+listener+"};");
		}else if(type&&!listener){
			var f=eval("target.on"+type);
			if(target._eventOff[type]||f){f=null}
		}
	}else{
		if(type){
			if(listener){
				if(target._test(type,listener)){
					if(target._eventOff[type]){
						eval("target.on"+type+"=function(e){"+target._event[type]+"};");
						target._eventOff[type]=null;
					}
				}else{
					if(!target._event[type]){target._event[type]=""};
					target._event[type]+=listener;
					eval("target.on"+type+"=function(e){"+target._event[type]+"};");
				}
			}else{
				var f=eval("target.on"+type);
				if(f&&target._eventOff[type]){
					if(target._event[type]){eval("target.on"+type+"=function(e){"+target._event[type]+"}")}
					else{f=null}
					target._eventOff[type]=null;
				}else if(f){f=null}
			}
		}else{
			for(var tip in target._event){
				if(target._eventOff[tip]){
					eval("target.on"+tip+"=function(e){"+target._event[tip]+"};");
					target._eventOff[tip]=null;
				}
			}
		}
	}
}
function stopEvent(target,type,listener){
	if(!target._eventOff){target._eventOff=[]}
	if(!target._event){
		if(type){
			target._eventOff[type]=true;
			eval("target.on"+type+"=function(e){return false};");
		}
	}else{
		if(listener){
			if(target._test(type,listener)){
				var exp=new RegExp(listener,"gi");
				target._event[type]=target._event[type].replace(exp,"");
				eval("target.on"+type+"=function(e){"+target._event[type]+"};");
			}
		}else if(type){
			target._eventOff[type]=true;
			eval("target.on"+type+"=function(e){return false};");
		}else{
			for(var tip in target._event){
				target._eventOff[tip]=true;
				eval("target.on"+tip+"=function(e){return false};");
			}
		}
	}
}
function createListener(type,listener,target){
	target=(!target)?document:target;
	if(type=="mousewheel"){
		type=(_ie||_op||_cr)?type:"DOMMouseScroll";
	}
	if(_ie){target.attachEvent("on"+type, listener)}
	else{target.addEventListener(type, listener, false)}
}
function deleteListener(type,listener,target){
	target=(!target)?document:target;
	if(type=="mousewheel"){
		type=(_ie||_op||_cr)?type:"DOMMouseScroll";
	}
	if(_ie){target.detachEvent("on"+type, listener)}
	else{target.removeEventListener(type, listener, false)}
}

PRELOAD=function(imgs,callback,params){ //imgs=[ {img:'file1.png'} , {img:'file2.png',callback:function(trg){animate(trg)}} ];
	var _temp;
	if(!_temp){
		//create
		_temp=new Image();
		with(_temp.style){
			position='absolute';
			top=left='-1000px';
			width=height='0px';
			overflow='hidden';
		}
		_temp._evoke=function(){
			if(this._current&&this._current.callback){
				//reset
				if(this._wait){
					clearTimeout(this._wait);
					this._wait=null;
				}
				//callback
				this._current.callback(this._current);
			}
			if(this.imgs.length>0){
				this._current=this.imgs.pop();
				this.src=this._current.img;
				this._wait=setTimeout(function(){if(_temp._wait){debug(_temp._current.img+' - <b style="color:red">Image Not Found!</b>');_temp._evoke()}},7777);
			}else{//destroy
				if(this._wait){
					clearTimeout(this._wait);
					this._wait=null;
				}
				this.parentNode.removeChild(this);
				this.callback(this.params);
			}			
		};
		_temp.onload=_temp._evoke;
		document.body.appendChild(_temp);
	}
	_temp.imgs=imgs;
	_temp.callback=(callback)?callback:function(){null};
	_temp.params=params;

	_temp._evoke();
};

function FADER(trg,prop){//{type:'fadeOut',func:regularEaseOut,interval:30,duration:10,callback:'stringFunction'}
	if(prop){
		clearInterval(trg._interval);
		trg.prop=prop;
		trg.prop._width=trg.offsetWidth;
		trg._count=0;
		trg._interval=setInterval(function(){FADER(trg)},trg.prop.interval);
		trg._fadding=true;
	}
	var opc=trg.prop.func(trg._count,100,trg.prop.duration);
	var cent=(trg.prop.type=="fadeout")?100-opc:opc;
	//////
	setOpacity(trg,cent);
	//////
	if(trg.prop.duration==trg._count||!trg.parentNode||!trg.parentNode.parentNode){
		clearInterval(trg._interval);
		trg._fadding=false;
		if(trg.prop.callback){
			switch(typeof(trg.prop.callback)){
				case 'string': eval(trg.prop.callback); break;
				case 'function': trg.prop.callback(); break;
			}
		}
	}else{trg._count++}
}

function SCROLLER(){
	var _P=this;
	_P.frame=document.createElement('div');_P.frame.className="scrollframe";document.body.appendChild(_P.frame);
	_P.seek=function(e){
		if(!e){ e=event; }
		var dist=_P.init+e.clientY-_P.ref;
		_P.scrolling(dist);
	};
	_P.scrolling=function(point){
		if(typeof(point)=="string"){
			_P.formatScroll();
			var delta=Math.ceil(20/_P.koef);
			_P._delta=(point=="up")?-delta:delta;
			_P._timer=setTimeout(function(){
				_P._timer=setInterval(function(){
					var newpoint=_P.scrollbar.slider.offsetTop+_P._delta;
					_P.scrolling(newpoint);
					if(newpoint<0||newpoint>_P.limit){clearInterval(_P._timer)};
				},50);
			},350);
			point=_P.scrollbar.slider.offsetTop+_P._delta;
		}
		var pos=(point<=0)?0:(point>=_P.limit)?_P.limit:point;
		_P.scrollbar.slider.style.top=pos+"px";
		_P.content.style.top=-pos*_P.koef+"px";
		_P.checkFlow();
	};
	_P.wheel=function(e){
		if(!_P||!_P.scrollable){return false}
		var delta = 0;
		if(!e){e=window.event}// IE
		if(e.wheelDelta){// IE/opera
			delta = e.wheelDelta/120; 
			//if(window.opera){delta=-delta}// opera
		}else if(e.detail){
			delta=-e.detail/3;// mozilla
		}
		if(delta){// if!(0) -> (+)=up (-)=down
			delta*=Math.ceil(20/_P.koef);//Math.ceil(_P.koef);
			_P.scrolling(_P.scrollbar.slider.offsetTop-delta);
			// disable default mousewheel
			if(e.preventDefault){e.preventDefault()}
			e.returnValue = false;
			return delta;
		}
		return null;
	};
	_P.setContent=function(itm){
		_P.content.appendChild(itm);
		_P.formatScroll();
	};
	_P.create=function(){
		//elements
		_P.mask=document.createElement("div");with(_P.mask.style){position="absolute";top=left="0px";width=height="100%";overflow="hidden"};_P.frame.appendChild(_P.mask);
		_P.content=document.createElement("div");_P.content.className="scrollcontent";_P.mask.appendChild(_P.content);
		_P.content.innerHTML="<div style='position:absolute; bottom:0px; left:0px; padding-bottom:13px; width:100%; font-size:12px; text-align:center; background-color:#fff'><br>• • •</div>";
		_P.scrollbar=document.createElement("div");_P.scrollbar.className="scrollbar";_P.scrollbar.style.visibility="hidden";_P.frame.appendChild(_P.scrollbar);
		_P.scrollbar.back=document.createElement("div");_P.scrollbar.back.className="scrollback";_P.scrollbar.appendChild(_P.scrollbar.back);
		var tmp=_P.scrollbar.slidezone=document.createElement('div');with(tmp.style){position='absolute';width=height='100%';top=left='0px';overflow='hidden'};_P.scrollbar.appendChild(tmp);
		_P.scrollbar.slider=document.createElement("div");_P.scrollbar.slider.className="scrollslider";_P.scrollbar.slider.style.top="0px";tmp.appendChild(_P.scrollbar.slider);
		_P.scrollbar.up=document.createElement("div");_P.scrollbar.up.className="scrollup";_P.scrollbar.appendChild(_P.scrollbar.up);
		_P.scrollbar.down=document.createElement("div");_P.scrollbar.down.className="scrolldown";_P.scrollbar.appendChild(_P.scrollbar.down);
		//events
		_P.scrollbar.slider.onmouseover=function(){_P.draggable=true};
		_P.scrollbar.slider.onmouseout=function(){_P.draggable=false};
		_P.scrollbar.up.onmousedown=function(){
			_P.evokeScroll();
			_FX(2,this);
			_P.scrolling("up");
		};
		_P.scrollbar.down.onmousedown=function(){
			_P.evokeScroll();
			_FX(2,this);
			_P.scrolling("down");
		};
		_P.scrollbar.slidezone.onmousedown=function(e){
			_FX(2,_P.scrollbar.slider);
			if(!e){e=event}
			_P.ref=e.clientY;
			if(!_P.draggable){
				_P.formatScroll();
				var scrT=getXY(_P.scrollbar);
				var newpos=_P.ref-scrT._y;
				var half=Math.round(_P.scrollbar.slider.offsetHeight/2);
				newpos=(newpos<half)?0:(newpos>_P.limit+half)?_P.limit:newpos-half;
				_P.scrolling(newpos);
				_P.init=newpos;
			}else{
				_P.init=_P.scrollbar.slider.offsetTop;
				_P.formatScroll();
			}
			_P.evokeScroll(_P.seek);
		};
		createListener("mouseup",_P.relaxScroll);
		createListener("mousewheel",_P.wheel);
		createListener("resize",_P.formatScroll,window);
	};
	_P.checkFlow=function(){
		if(!_P.scrollable||(_P.limit-_P.scrollbar.slider.offsetTop)*_P.koef<10){ //less than 10px to the end
			//debug(pane.scrollbar.slider.offsetTop+">"+pane.limit+" - "+(pane.limit*5/100))
			if(_P.callFlow){_P.callFlow(_P)}
		}
	};
	_P.formatScroll=function(){
		var _scroll=(_P.content.offsetHeight>_P.mask.offsetHeight)?_P.content.offsetHeight-_P.mask.offsetHeight:0;
		if(_scroll>0){
			if(!_P.scrollable){
				_P.scrollable=_scroll;
				_P.scrollbar.className="scrollbar showall";
				_P.scrollbar.style.visibility="visible";
			}
			var scrLIM=_P.scrollbar.offsetHeight-_P.scrollbar.slider.offsetHeight;
			//params for scrolling
			_P.limit=scrLIM;
			_P.koef=_scroll/scrLIM;
			//format
			//debug(-_P.content.offsetTop+">"+_scroll,pane.scrollbar.slider.offsetTop+">"+scrLIM)
			var panTOP=_P.content.offsetTop;
			if(-panTOP>_scroll){
				panTOP=-_scroll;
				_P.content.style.top=panTOP+"px";
			}
			_P.scrollbar.slider.style.top=Math.ceil(-panTOP/_P.koef)+"px";
		}else{
			if(_P.scrollable){
				_P.scrollbar.style.visibility="hidden";
				_P.scrollable=_scroll;//which is [0]
				_P.content.style.top="0px";
			}
		}
		_P.checkFlow();
	};
	_P.relaxScroll=function(){
		if(_P._relax){
			//debug('relaxScroll twice:FIX startevent!')
			clearInterval(_P._timer);
			deleteListener("mousemove",_P.seek);
			var tmp=_P.scrollbar;
			_FX(0,tmp.slider); _FX(0,tmp.up); _FX(0,tmp.down);
			if(_ie){startEvent(document,"selectstart");startEvent(document,"dragstart")}else{startEvent(document,"mousedown")}
			_P._relax=null;
		}
	};
	_P.evokeScroll=function(callback){
			_P._relax=true;
			if(_ie){stopEvent(document,"selectstart");stopEvent(document,"dragstart")}else{stopEvent(document,"mousedown")}
			if(callback){createListener("mousemove",callback)}
	}
	_P.create();
}
//////////////////////////////////////////
//////////////// KEYBOARD ////////////////
//////////////////////////////////////////
var NOKEYS=false;
function FOCUS(){
	if(!document.FOCUS){document.FOCUS=[]}
	if(!document._observedFocus){
		document._observedFocus=true;
		createListener('keydown',checkKeys,document);
	}
	var a=arguments;
	if(a[1]){
		if(document.FOCUS.length>0&&document.FOCUS[document.FOCUS.length-1]==a[0]){return false}
		document.FOCUS[document.FOCUS.length]=a[0];
		//debug('ADD:'+a[0].name)
	}else{
		for(var i=0; i<document.FOCUS.length; i++){
			if(document.FOCUS[i]==a[0]){
				document.FOCUS.splice(i,1);
				//debug('DEL:'+a[0].name);
				return;
			}
		}
	}
}
function mapKeys(e){
	var keycode;
	if(!e){ e=(window.event)}
	keycode = (_ie)?e.keyCode:e.which;
	//character=String.fromCharCode(keycode);
	return keycode;//character
}
function checkKeys(e){
	if(document.FOCUS.length>0){
		var f=document.FOCUS[document.FOCUS.length-1];
		if(!f.keys){return}
		if(f.keys.esc&&mapKeys(e)==27){if(!_ie){e.preventDefault()}f.keys.esc()}//ESC
		else if(f.keys.entr&&mapKeys(e)==13){f.keys.entr()}//ENTER
		else if(f.keys.space&&mapKeys(e)==32){f.keys.space()}//SPACEBAR
		else if(f.keys.back&&mapKeys(e)==8){f.keys.back()}//BACKSPACE
		else if(f.keys.next&&mapKeys(e)==39){f.keys.next()}//RIGHT
		else if(f.keys.prev&&mapKeys(e)==37){f.keys.prev()}//LEFT
		else if(f.keys.up&&mapKeys(e)==38){f.keys.up()}//UP
		else if(f.keys.down&&mapKeys(e)==40){f.keys.down()}//DOWN
		//
		if(f.keys.callback){f.keys.callback()}//regular callback function
		return;
	}else if(NOKEYS){
		return;
	}
}


//////////////////////////////////////////
////////// BASE64 ENCODE/DECODE //////////
//////////////////////////////////////////
function StringBuffer()
{ 
    this.buffer = []; 
} 

StringBuffer.prototype.append = function append(string)
{ 
    this.buffer.push(string); 
    return this; 
}; 

StringBuffer.prototype.toString = function toString()
{ 
    return this.buffer.join(""); 
}; 

var Base64 =
{
    codex : "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=",

    encode : function (input)
    {
        var output = new StringBuffer();

        var enumerator = new Utf8EncodeEnumerator(input);
        while (enumerator.moveNext())
        {
            var chr1 = enumerator.current;

            enumerator.moveNext();
            var chr2 = enumerator.current;

            enumerator.moveNext();
            var chr3 = enumerator.current;

            var enc1 = chr1 >> 2;
            var enc2 = ((chr1 & 3) << 4) | (chr2 >> 4);
            var enc3 = ((chr2 & 15) << 2) | (chr3 >> 6);
            var enc4 = chr3 & 63;

            if (isNaN(chr2))
            {
                enc3 = enc4 = 64;
            }
            else if (isNaN(chr3))
            {
                enc4 = 64;
            }

            output.append(this.codex.charAt(enc1) + this.codex.charAt(enc2) + this.codex.charAt(enc3) + this.codex.charAt(enc4));
        }

        return output.toString();
    },

    decode : function (input)
    {
        var output = new StringBuffer();

        var enumerator = new Base64DecodeEnumerator(input);
        while (enumerator.moveNext())
        {
            var charCode = enumerator.current;

            if (charCode < 128)
                output.append(String.fromCharCode(charCode));
            else if ((charCode > 191) && (charCode < 224))
            {
                enumerator.moveNext();
                var charCode2 = enumerator.current;

                output.append(String.fromCharCode(((charCode & 31) << 6) | (charCode2 & 63)));
            }
            else
            {
                enumerator.moveNext();
                var charCode2 = enumerator.current;

                enumerator.moveNext();
                var charCode3 = enumerator.current;

                output.append(String.fromCharCode(((charCode & 15) << 12) | ((charCode2 & 63) << 6) | (charCode3 & 63)));
            }
        }

        return output.toString();
    }
}


function Utf8EncodeEnumerator(input)
{
    this._input = input;
    this._index = -1;
    this._buffer = [];
}

Utf8EncodeEnumerator.prototype =
{
    current: Number.NaN,

    moveNext: function()
    {
        if (this._buffer.length > 0)
        {
            this.current = this._buffer.shift();
            return true;
        }
        else if (this._index >= (this._input.length - 1))
        {
            this.current = Number.NaN;
            return false;
        }
        else
        {
            var charCode = this._input.charCodeAt(++this._index);

            // "\r\n" -> "\n"
            //
            if ((charCode == 13) && (this._input.charCodeAt(this._index + 1) == 10))
            {
                charCode = 10;
                this._index += 2;
            }

            if (charCode < 128)
            {
                this.current = charCode;
            }
            else if ((charCode > 127) && (charCode < 2048))
            {
                this.current = (charCode >> 6) | 192;
                this._buffer.push((charCode & 63) | 128);
            }
            else
            {
                this.current = (charCode >> 12) | 224;
                this._buffer.push(((charCode >> 6) & 63) | 128);
                this._buffer.push((charCode & 63) | 128);
            }

            return true;
        }
    }
}

function Base64DecodeEnumerator(input)
{
    this._input = input;
    this._index = -1;
    this._buffer = [];
}

Base64DecodeEnumerator.prototype =
{
    current: 64,

    moveNext: function()
    {
        if (this._buffer.length > 0)
        {
            this.current = this._buffer.shift();
            return true;
        }
        else if (this._index >= (this._input.length - 1))
        {
            this.current = 64;
            return false;
        }
        else
        {
            var enc1 = Base64.codex.indexOf(this._input.charAt(++this._index));
            var enc2 = Base64.codex.indexOf(this._input.charAt(++this._index));
            var enc3 = Base64.codex.indexOf(this._input.charAt(++this._index));
            var enc4 = Base64.codex.indexOf(this._input.charAt(++this._index));

            var chr1 = (enc1 << 2) | (enc2 >> 4);
            var chr2 = ((enc2 & 15) << 4) | (enc3 >> 2);
            var chr3 = ((enc3 & 3) << 6) | enc4;

            this.current = chr1;

            if (enc3 != 64)
                this._buffer.push(chr2);

            if (enc4 != 64)
                this._buffer.push(chr3);

            return true;
        }
    }
};
//////////////////////////////////////////
/////////////// TIMESTAMP ////////////////
//////////////////////////////////////////
function timeToHuman(theDate,str){
	theDate = new Date(theDate * 1000);
	var dateString = theDate.toGMTString();
	var arrDateStr = dateString.split(" ");
	var dat={};
	dat._Mon = arrDateStr[2];
	dat._Day = arrDateStr[1];
	dat._Year = arrDateStr[3];
	dat._ShortYear = (arrDateStr[3]>999)?arrDateStr[3].substring(2):arrDateStr[3];
	dat._Hr = arrDateStr[4].substr(0,2);
	dat._Min = arrDateStr[4].substr(3,2);
	dat._Sec = arrDateStr[4].substr(6,2);
	dat._MonNum=getMonthNum(dat._Mon);
	dat._MonEng=setMonthNum(dat._MonNum);
	if(str){return (dat._Day+" "+dat._Mon+" "+dat._Year+" / "+dat._Hr+":"+dat._Min+":"+dat._Sec)}
	//return ("<i>"+dat._Day+"."+getMonthNum(dat._Mon)+"."+dat._ShortYear+" "+dat._Hr+":"+dat._Min);
	else{return dat}
}
function humanToTime(inYear,inMon,inDay,inHr,inMin,inSec){
	var humDate = new Date(Date.UTC(inYear,(stripLeadingZeroes(inMon)-1),stripLeadingZeroes(inDay),stripLeadingZeroes(inHr),stripLeadingZeroes(inMin),stripLeadingZeroes(inSec)));
	return (humDate.getTime()/1000.0);
}
function stripLeadingZeroes(input){
	if((input.length > 1) && (input.substr(0,1) == "0")){
	  return parseInt(input.substr(1));
	}else{
	  return parseInt(input);
	}
}
function getMonthNum(abbMonth){
	var arrMon = new Array("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
	for(i=0; i<arrMon.length; i++){
		if(abbMonth == arrMon[i]){return (i+1)}
	}
}
function setMonthNum(abbMonth){
	var arrMon = new Array("January","February","March","April","May","June","July","August","September","October","November","December");
	return arrMon[i];
}
