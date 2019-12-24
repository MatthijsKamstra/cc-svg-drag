package;

import js.html.svg.Rect;
import js.html.svg.Transform;
import js.html.MouseEvent;
import js.html.svg.GraphicsElement;
import js.html.DOMElement;
import js.html.svg.SVGElement;
import js.Browser.*;
import App;

class MainSVGDrag {
	public function new() {
		document.addEventListener("DOMContentLoaded", function(event) {
			console.info('${App.NAME} Dom ready :: build: ${App.getBuildDate()} ');
			init1();
		});
	}

	function init1() {
		var svgs:Array<SVGElement> = cast document.getElementsByTagName('svg');

		trace('svgs : ' + svgs.length);
		for (i in 0...svgs.length) {
			var _svg:SVGElement = cast svgs[i];
			// wrap svg with postitioner.. to make sure we will remove it!
			wrap(_svg);
			var children = (_svg.children);
			for (i in children) {
				var child:GraphicsElement = cast i;
				child.setAttribute('class', 'shadow draggable');
				// console.log(child.tagName);
				makeDraggable(child);
				// child.onclick = function() {
				// 	console.log(child);
				// }
				switch (child.tagName) {
					case 'g':
					// trace('deeper in the rabithole');
					default:
				}
			}
		}
	}

	// http://www.petercollingridge.co.uk/tutorials/svg/interactive/dragging/
	var selectedElement:GraphicsElement;
	var offset:Point;
	var transform:Transform;
	var bbox:Rect;
	var minX:Float;
	var maxX:Float;
	var minY:Float;
	var maxY:Float;
	var confined:Bool;

	var boundaryX1:Float = 10.5;
	var boundaryX2:Float = 30;
	var boundaryY1:Float = 2.2;
	var boundaryY2:Float = 19.2;

	function makeDraggable(el:GraphicsElement) {
		trace('makeDraggable "${el.tagName}"');
		var svg = el;
		svg.addEventListener('mousedown', startDrag);
		svg.addEventListener('mousemove', drag);
		svg.addEventListener('mouseup', endDrag);
		svg.addEventListener('mouseleave', endDrag);
		// touch
		// svg.addEventListener('touchstart', startDrag);
		// svg.addEventListener('touchmove', drag);
		// svg.addEventListener('touchend', endDrag);
		// svg.addEventListener('touchleave', endDrag);
		// svg.addEventListener('touchcancel', endDrag);
	}

	function getMousePosition(evt:MouseEvent):Point {
		var svg:SVGElement = cast untyped evt.explicitOriginalTarget.farthestViewportElement;
		var CTM = svg.getScreenCTM();
		// for now no touch
		// if (evt.touches != null) {
		// 	evt = evt.touches[0];
		// }
		return {
			x: (evt.clientX - CTM.e) / CTM.a,
			y: (evt.clientY - CTM.f) / CTM.d
		};
	}

	function startDrag(evt:MouseEvent) {
		var svg:SVGElement = cast untyped evt.explicitOriginalTarget.farthestViewportElement;
		// if (cast(evt.target, DOMElement).classList.contains('draggable')) {
		selectedElement = cast evt.target;

		// trace(selectedElement);
		offset = getMousePosition(evt);

		// trace(offset);

		// Make sure the first transform on the element is a translate transform
		var transforms = selectedElement.transform.baseVal;

		// trace(transforms);
		if (transforms.length == 0 || transforms.getItem(0).type != Transform.SVG_TRANSFORM_TRANSLATE) {
			// Create an transform that translates by (0, 0)
			var translate = svg.createSVGTransform();
			translate.setTranslate(0, 0);
			selectedElement.transform.baseVal.insertItemBefore(translate, 0);
		}

		// Get initial translation
		transform = transforms.getItem(0);
		offset.x -= transform.matrix.e;
		offset.y -= transform.matrix.f;

		confined = cast(evt.target, DOMElement).classList.contains('confine');
		if (confined) {
			bbox = selectedElement.getBBox();
			minX = boundaryX1 - bbox.x;
			maxX = boundaryX2 - bbox.x - bbox.width;
			minY = boundaryY1 - bbox.y;
			maxY = boundaryY2 - bbox.y - bbox.height;
		}
		// }
	}

	function drag(evt:MouseEvent) {
		if (selectedElement != null) {
			evt.preventDefault();

			var coord = getMousePosition(evt);
			var dx = coord.x - offset.x;
			var dy = coord.y - offset.y;

			if (confined) {
				if (dx < minX) {
					dx = minX;
				} else if (dx > maxX) {
					dx = maxX;
				}
				if (dy < minY) {
					dy = minY;
				} else if (dy > maxY) {
					dy = maxY;
				}
			}

			transform.setTranslate(dx, dy);
		}
	}

	function endDrag(evt:MouseEvent) {
		selectedElement = null;
	}

	function wrap(el:DOMElement) {
		// create wrapper container
		var wrapper = document.createDivElement();
		wrapper.className = 'cc-svg-drag-wrapper';
		el.parentNode.insertBefore(wrapper, el);
		wrapper.appendChild(el);

		var cursorCSS = '.static { cursor: not-allowed;}.draggable {  cursor: move;} ';
		cursorCSS += '.cc-svg-drag-wrapper {position: relative;margin: 0;padding: 0;}.cc-svg-drag-wrapper::after {background:#ffdd57;border-radius:2 px 2 px 0 0;bottom:100 %;color:rgba(0, 0, 0, 0.7);content:"CC-SVG-DRAG active";display:inline-block;font-size:0.4 rem;font-weight:700;right:-1 px;letter-spacing:1 px;margin-left: -1 px;padding:3 px 5 px;position:absolute;text-transform:uppercase;vertical-align:top;font-family:Arial, Helvetica, sans-serif;}';
		setCSS(cursorCSS, null);
	}

	/**
	 * make sure the css is injected, but only once
	 *
	 * @param styles 		what styles you want to inject into the file
	 * @param elementID   	make sure we only inject once...
	 */
	function setCSS(styles:String, elementID:String) {
		if (elementID == null)
			elementID = ' inject-' + Date.now().getTime();

		styles = (styles);
		// trace(document.getElementById(elementID));

		var css = document.createStyleElement();
		css.id = elementID;

		// [mck] it seems that styleSheet isn't in the html externs from Haxe
		if (untyped css.styleSheet)
			untyped css.styleSheet.cssText = styles;
		else
			css.appendChild(document.createTextNode(styles));

		// [mck] maybe check this before adding
		document.getElementsByTagName("head")[0].appendChild(css);

		// trace(document.getElementById(elementID));
	}

	static public function main() {
		var app = new MainSVGDrag();
	}
}

typedef Point = {
	var x:Float;
	var y:Float;
};
