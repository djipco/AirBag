/*

Licensed under the MIT License

Copyright (c) 2013 Jean-Philippe Côté
http://cote.cc/projects/airbag

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and 
associated documentation files (the "Software"), to deal in the Software without restriction, 
including without limitation the rights to use, copy, modify, merge, publish, distribute, 
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial 
portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT 
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND 
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES 
OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN 
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

*/

package cc.cote.airbag
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.errors.EOFError;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.AntiAliasType;
	import flash.text.TextField;
	import flash.utils.ByteArray;
	import flash.utils.getQualifiedClassName;
	
	
	/**
	 * Dispatched each time <code>AirBag</code> performs its detection routine. This typically is on
	 * each <code>ENTER_FRAME</code> but can be altered by the <code>skip</code> property.
	 * 
	 * @eventType cc.cote.airbag.AirBagEvent.DETECTION
	 * @since 1.0a rev1
	 */
	[Event(name="detection",type="cc.cote.airbag.AirBagEvent")]
	
	/**
	 * Dispatched when <code>AirBag</code> detects at least one collision during its scheduled 
	 * detection run.
	 * 
	 * @eventType cc.cote.airbag.AirBagEvent.COLLISION
	 * @since 1.0a rev1
	 */
	[Event(name="collision",type="cc.cote.airbag.AirBagEvent")]
	
	/**
	 * The <code><b>AirBag</b></code> class allows the pixel-precise detection of collisions amongst 
	 * a list of <code>DisplayObject</code>s (<code>MovieClip</code>s, <code>Sprite</code>s, 
	 * <code>Bitmap</code>s, <code>TextField</code>s, <code>Video</code>s, etc.). It also 
	 * facilitates the exclusion of certain color ranges from detection and takes into account the
	 * desired alpha threshold.
	 * 
	 * <p>Most of the core collision detection code comes from 
	 * <a href="http://coreyoneil.com/">Corey O'Neil</a>'s excellent 
	 * <a href="http://code.google.com/p/collisiondetectionkit/">Collision Detection Kit</a>. By 
	 * releasing <code>AirBag</code>, we hope to overcome some limitations and repair some API 
	 * quirks found in the original CDK.</p>
	 * 
	 * To perform collision detection, you must first specify a list of objects upon which the 
	 * detection will take place. The way do do that is to pass a list of 
	 * <code>DisplayObject</code>s to the constructor or to the <code>add()</code> method. Both the 
	 * constructor and the <code>add()</code> method support any combination of the following 
	 * objects:
	 * 
	 * <ul>
	 *   <li><code>Vector.&lt;DisplayObject&gt;</code></li>
	 *   <li><code>DisplayObject</code></li>
	 *   <li><code>Array</code> of <code>DisplayObject</code>s</li>
	 * </ul>
	 * 
	 * <p>By default, collision detection works in a <b>many-to-many</b> relationship. That
	 * is, all objects will be checked against all other objects when calling the 
	 * <code>checkCollisions()</code> method.</p>
	 * 
	 * <p>Alternatively, if a specific target has been assigned by way of the 
	 * <code>singleTarget</code> property, detection will work in a <b>one-to-many</b> relationship. 
	 * This means that only collisions between the <code>singleTarget</code> and one of the objects 
	 * in the list will be reported.</p>
	 * 
	 * <p><b>Usage</b></p>
	 * 
	 * <p>To use <code>AirBag</code>, you simply create an <code>AirBag</code> object by supplying 
	 * it with <code>DisplayObject</code>s to add to its detection list. This can be done through 
	 * the constructor and/or with the <code>add()</code> method: </p>
	 * 
	 * <listing version="3.0">
	 * public var airbag:AirBag = new AirBag(obj1, obj2, obj3);
	 * airbag.add(obj4, obj5);</listing>
	 * 
	 * <p>Then, you call the <code>checkCollisions()</code> method whenever appropriate. For 
	 * example, you can continually check for collisions by using an <code>ENTER_FRAME</code>
	 * handler:</p>
	 * 
	 * <listing version="3.0">
	 * addEventListener(Event.ENTER_FRAME, checkCollisions);
	 * 
	 * public function checkCollisions(e:Event):void {
	 * 	var collisions:Vector.&lt;Collision&gt; = airbag.checkCollisions();
	 * 	if (collisions.length) {
	 * 		trace("Collision detected!");
	 * 	}
	 * }</listing>
	 * 
	 * <p>If you only want to track collisions against a single object, you can use the 
	 * <code>singleTarget</code> property:</p>
	 * 
	 * <listing version="3.0">
	 * public var airbag:AirBag = new AirBag(obj1, obj2, obj3);
	 * airbag.singleTarget(obj4);</listing>
	 * 
	 * <p>This will report all collisions of <code>obj1</code>, <code>obj2</code> and 
	 * <code>obj3</code> with <code>obj4</code> but won't report collisions of <code>obj1</code>, 
	 * <code>obj2</code> and <code>obj3</code> with themselves.</p>
	 * 
	 * <p>Starting in version 1.0a rev1, you can listen to events directly on the <code>AirBag</code>
	 * object.</p>
	 * 
	 * <listing version="3.0">
	 * public var airbag:AirBag = new AirBag(obj1, obj2, obj3);
	 * airbag.addEventListener(AirBagEvent.DETECTION, onDetection);
	 * 
	 * public function onDetection(e:Event):void {
	 * 	if (e.collisions.length) {
	 * 		trace("Collision detected!");
	 * 	}
	 * }</listing>
	 * 
	 * <p>The <code>AirBagEvent.DETECTION</code> event is triggered each time detection is performed 
	 * (typically on <code>ENTER_FRAME</code> unless the <code>skip</code> property is used). The 
	 * <code>AirBagEvent.COLLISION</code> event is triggered only when at least one collision is 
	 * found in a detection run.</p>
	 * 
	 * @see cc.cote.airbag.Collision
	 * @see cc.cote.airbag.AirBagEvent
	 * @see http://cote.cc/projects/airbag Official AirBag project page
	 */
	public class AirBag extends EventDispatcher
//	public class AirBag extends Sprite
	{
		/** Current version of the library. */
		public static const VERSION:String = '1.0a rev2';
		
		/** Constant defining a ONE_TO_MANY detection mode. */
		public static const ONE_TO_MANY:String = 'oneToMany';
		
		/** Constant defining a MANY_TO_MANY detection mode. */
		public static const MANY_TO_MANY:String = 'manyToMany';
		
		/** @private */
		protected var _calculateAngles:Boolean = false;
		/** @private */
		protected var _calculateOverlap:Boolean = false;
		/** @private */
		protected var _ignoreParentless:Boolean = true;
		/** @private */
		protected var _ignoreInvisibles:Boolean = true;
		
		/** @private */
		protected var _alphaThreshold:uint;
		/** @private **/
		protected var _mode:String = MANY_TO_MANY;
		
		/** @private */
		protected var objectArray:Vector.<DisplayObject>;
		/** @private */
		protected var objectCheckArray:Vector.<Vector.<DisplayObject>>;
		/** @private */
		protected var objectCollisionArray:Vector.<Collision>;
		/** @private */
		protected var colorExclusionArray:Array;
		
		/** @private */
		protected var bmd1:BitmapData;
		/** @private */
		protected var bmd2:BitmapData;
		/** @private */
		protected var bmdResample:BitmapData;
		/** @private */
		protected var pixels1:ByteArray;
		/** @private */
		protected var pixels2:ByteArray;
		/** @private */
		protected var item1BoundingBox:Rectangle;
		/** @private */
		protected var item2BoundingBox:Rectangle;
		/** @private */
		protected var transMatrix1:Matrix;
		/** @private */
		protected var transMatrix2:Matrix;
		/** @private */
		protected var colorTransform1:ColorTransform;
		/** @private */
		protected var colorTransform2:ColorTransform;
		/** @private */
		protected var item1GlobalRegistrationPoint:Point;
		/** @private */
		protected var item2GlobalRegistrationPoint:Point;
		
		/** @private */
		protected var _enterFrameCatcher:Shape;
		
		/** @private */
		protected var _skip:uint;
		
		/** @private */
		protected var _skipCounter:uint;
		
		/**
		 * Creates an <code>AirBag</code> object from the <code>DisplayObject</code>s passed as 
		 * parameters. The <code>DisplayObject</code>s to use can be specified by passing any of the 
		 * following as parameters:
		 * 
		 * <ul>
		 *   <li><code>Vector.&lt;DisplayObject&gt;</code></li>
		 *   <li><code>DisplayObject</code></li>
		 *   <li><code>Array</code> of <code>DisplayObject</code>s</li>
		 * </ul>
		 * 
		 * <p>By default, collision detection works in a "many-to-many" relationship. That
		 * is, all objects will be checked against all other objects. Any collision found will be 
		 * reported.</p>
		 * 
		 * <p>If a specific target is assigned by way of the <code>singleTarget</code> property, 
		 * detection will work in a "one-to-many" relationship. This means that only collisions 
		 * between the <code>singleTarget</code> and one of the objects in the list will be 
		 * reported.</p>
		 * 
		 * @param objects 			A variable number of any of the following objects: 
		 * 							Vector.&lt;DisplayObject&gt;, DisplayObject or Array of 
		 * 							DisplayObjects.
		 * 
		 * @throws ArgumentError 	The parameters used to create an AirBag object must be of one of 
		 * 							the following data types: Vector.&lt;DisplayObject&gt;, 
		 * 							DisplayObject or Array.
		 */
		
		public function AirBag(...objects):void {
			
			objectCheckArray = new <Vector.<DisplayObject>>[];
			objectCollisionArray = new <Collision>[];
			objectArray = new <DisplayObject>[];
			colorExclusionArray = [];
			_alphaThreshold = 1;
			_skip = 0;
			_skipCounter = 0;
			
			for each (var obj:* in objects) add(obj);
			
		}
		
		/**
		 * Adds DisplayObjects to the detection list. Objects to add can be specified using any 
		 * combination of the following data types: <code>Vector.&lt;DisplayObject&gt;</code>, 
		 * <code>DisplayObject</code> or <code>Array</code> (of <code>DisplayObject</code>s).
		 * 
		 * @param objects 			A variable number of any of the following objects: 
		 * 							<code>Vector.&lt;DisplayObject&gt;</code>, 
		 * 							<code>DisplayObject</code> or <code>Array</code> (of 
		 * 							<code>DisplayObject</code>s).
		 * 
		 * @throws ArgumentError 	The <code>add()</code> method only accepts parameters of the 
		 * 							following types: <code>Vector.&lt;DisplayObject&gt;</code>, 
		 * 							<code>DisplayObject</code> or <code>Array</code>.
		 */
		public function add(...objects):void {
			
			for each (var object:* in objects) {
				
				if (object is Vector.<DisplayObject>) {				// Vector.<DisplayObject>
					objectArray = objectArray.concat(object);
				} else if (object is DisplayObject) {				// DisplayObject
					objectArray.push(object);
				} else if (object is Array) {						// Array
					for each (var obj:* in object) {
						if (obj is DisplayObject) objectArray.push(obj);
					}
				} else {
					throw new ArgumentError(
						'The add() method only accepts parameters of the following types: ' +
						'Vector.<DisplayObject>, DisplayObject or Array.'
					);
				}
				
			}
			
		}
		
		/**
		 * Removes DisplayObjects from the detection list. Objects to remove can be specified using 
		 * any combination of the following data types: <code>Vector.&lt;DisplayObject&gt;</code>, 
		 * <code>DisplayObject</code> or <code>Array</code> (of <code>DisplayObject</code>s).
		 * 
		 * @param objects 			A variable number of any of the following objects: 
		 * 							Vector.&lt;DisplayObject&gt;, DisplayObject or Array of 
		 * 							DisplayObjects.
		 * 
		 * @throws ArgumentError 	The remove() method only accepts parameters of the following 
		 * 							types: Vector.&lt;DisplayObject&gt;, DisplayObject or Array.'
		 */
		public function remove(...objects):void {
			
			for each (var object:* in objects) {
				
				if (object is Vector.<DisplayObject>) {				// Vector.<DisplayObject>
					for each (var vObj:DisplayObject in object) {
						_removeObject(vObj);
					}
				} else if (object is DisplayObject) {				// DisplayObject
					_removeObject(object);
				} else if (object is Array) {						// Array
					for each (var aObj:* in object) {
						if (aObj is DisplayObject) _removeObject(aObj);
					}
				} else {
					throw new ArgumentError(
						'The remove() method only accepts parameters of the following types: ' +
						'Vector.<DisplayObject>, DisplayObject or Array.'
					);
				}
				
			}
			
		}
		
		/** @private */
		protected function _removeObject(obj:DisplayObject):void {
			
			var start:uint = 0;
			if (_mode == ONE_TO_MANY) start = 1;
			
			var loc:int = objectArray.indexOf(obj, start);
			
			if(loc >= 0) {
				objectArray.splice(loc, 1);
			} else {
				throw new ArgumentError(obj + " was not removed because it could not be found.");
			}
			
		}
		
		/**
		 * Clears the detection list and removes any <code>singleTarget</code> that might have been 
		 * assigned. Other settings such as <code>alphaThreshold</code> and 
		 * <code>excludeColor</code> are not affected by this method.
		 */
		public function clear():void {
			objectArray = new <DisplayObject>[];
			_mode = MANY_TO_MANY;
		}
		
		/**
		 * Performs the collision detection and returns a vector of <code>Collision</code> objects.
		 * 
		 * @throws Error 		The <code>singleTarget</code> must be on stage when 
		 * 						<code>ignoreParentless</code> is true.
		 * 
		 * @throws Error 		The <code>singleTarget</code> must be visible when 
		 * 						<code>ignoreInvisibles</code> is true.
		 * 
		 * @see cc.cote.airbag.Collision
		 */
		public function checkCollisions():Vector.<Collision> {
			
			objectCheckArray = new <Vector.<DisplayObject>>[];
			objectCollisionArray = new <Collision>[];
			
			if (_mode == ONE_TO_MANY) {
				return _checkOneToManyCollisions();
			} else {
				return _checkManyToManyCollisions();
			}
			
		}
		
		/** @private */
		protected function _checkOneToManyCollisions():Vector.<Collision> {
			
			var NUM_OBJS:uint = objectArray.length;
			var item1:DisplayObject = objectArray[0];
			var item2:DisplayObject;
			
			if (ignoreParentless && !item1.parent) {
				throw new Error(
					"The singleTarget must be on stage when ignoreParentless is true."
				);
			}
			
			if (ignoreInvisibles && !item1.visible) {
				throw new Error(
					"The singleTarget must be visible when ignoreInvisibles is true."
				);
			}
			
			for(var i:uint = 1; i < NUM_OBJS; i++) {
				item2 = objectArray[i];
				
				if (ignoreParentless && !item2.parent) break;
				
				if (item1.hitTestObject(item2)) {
					
//					// THIS IS SUPER FUCKING IMPORTANT FOR PERFORMANCE !!!!!!!!!
					if((item2.width * item2.height) > (item1.width * item1.height)) {
						objectCheckArray.push(new <DisplayObject>[item1,item2])
					} else {
						objectCheckArray.push(new <DisplayObject>[item2,item1]);
					}
					
				}
				
			}
			
			NUM_OBJS = objectCheckArray.length;
			var c:Collision = null;
			for(i = 0; i < NUM_OBJS; i++) {
				
				if (calculateAngles || calculateOverlap) {
					c = _findCollisionWithDetails(
						objectCheckArray[i][0], objectCheckArray[i][1], 
						calculateAngles, calculateOverlap
					);
				} else {
					c = _findCollision(objectCheckArray[i][0], objectCheckArray[i][1]);
				}
				
				c && objectCollisionArray.push(c);
				
			}
			
			return objectCollisionArray;
		}
		
		/** @private */
		protected function _checkManyToManyCollisions():Vector.<Collision> { 
			
			var NUM_OBJS:uint = objectArray.length;
			var item1:DisplayObject;
			var item2:DisplayObject;
			
			for(var i:uint = 0; i < NUM_OBJS - 1; i++) {
				
				item1 = objectArray[i];
				
				if (ignoreParentless && !item1.parent) break;
				if (ignoreInvisibles && !item1.visible) break;
				
				for(var j:uint = i + 1; j < NUM_OBJS; j++) {
					item2 = objectArray[j];
					
					if (ignoreParentless && !item2.parent) break;
					if (ignoreInvisibles && !item2.visible) break;
					
					if(item1.hitTestObject(item2)) {
						
						// THIS IS SUPER FUCKING IMPORTANT !!!!!!!!!
						if((item2.width * item2.height) > (item1.width * item1.height)) {
							objectCheckArray.push(new <DisplayObject>[item1,item2])
						} else {
							objectCheckArray.push(new <DisplayObject>[item2,item1]);
						}
					}
				}
				
			}
			
			NUM_OBJS = objectCheckArray.length;
			var c:Collision = null;
			for(i = 0; i < NUM_OBJS; i++) {
				
				if (calculateAngles || calculateOverlap) {
					c = _findCollisionWithDetails(
						objectCheckArray[i][0], objectCheckArray[i][1], 
						calculateAngles, calculateOverlap
					);
				} else {
					c = _findCollision(objectCheckArray[i][0], objectCheckArray[i][1]);
				}
				
				c && objectCollisionArray.push(c);
			}
			
			return objectCollisionArray;
		}
		
		/**
		 * Starts the collision detection process. On <code>ENTER_FRAME</code>, <code>AirBag</code>
		 * will check if any collisions happened and, if at least one was detected, it will dispatch 
		 * a <code>CollisionEvent</code> object.
		 * 
		 * <p>If you want to use a higher frame rate for your application than for collision 
		 * detection, you can use the <code>skip</code> property.</p>
		 * 
		 * <p>Important: do not forget to call <code>stop()</code> when you are done with 
		 * detection.</p>
		 * 
		 * @since 1.0a rev1
		 */
		public function start():void {
			!_enterFrameCatcher && (_enterFrameCatcher = new Shape());
			_enterFrameCatcher.addEventListener(Event.ENTER_FRAME, _onEnterFrame);
		}
		
		/**
		 * Stops the collision detection process.
		 * 
		 * @since 1.0a rev1
		 */
		public function stop():void {
			_enterFrameCatcher.removeEventListener(Event.ENTER_FRAME, _onEnterFrame);
		}
		
		/** @private */
		protected function _onEnterFrame(e:Event):void {
			
			if (_skipCounter % (_skip + 1) == 0) {
				
				_skipCounter = 1;
				
				
				
				var collisions:Vector.<Collision> = checkCollisions();
				
				dispatchEvent(
					new AirBagEvent(AirBagEvent.DETECTION, false, false, collisions)
				);
				
				if (collisions.length) {
					dispatchEvent(
						new AirBagEvent(AirBagEvent.COLLISION, false, false, collisions)
					);
				}
				
			} else {
				_skipCounter++;
			}
			
		}
		
		/**
		 * Properly disposes of the object. You should always use <code>dispose()</code> instead of 
		 * setting the object to <code>null</code>.
		 */
		public function dispose():void {
			if (_enterFrameCatcher.hasEventListener(Event.ENTER_FRAME)) {
				_enterFrameCatcher.removeEventListener(Event.ENTER_FRAME, _onEnterFrame);
			}
		}
		
		
		/**
		 * Adds a color to the color exclusion list. Pixels whose values are within the specified 
		 * range will not trigger a collision.
		 * 
		 * @param color The color to exclude
		 * @alpharange	A range of alpha values around the specified colors that should be excluded
		 * @redRange	A range of red values around the target color that should be excluded
		 * @greenRange	A range of green values around the target color that should be excluded
		 * @blueRange	A range of blue values around the target color that should be excluded
		 */
		public function addColorToExclusionList(
			color:uint, 
			alphaRange:uint = 255, 
			redRange:uint = 20, 
			greenRange:uint = 20, 
			blueRange:uint = 20
		):void {
			
			var numColors:int = colorExclusionArray.length;
			for (var i:uint = 0; i < numColors; i++) {
				if (colorExclusionArray[i].color == color) return; // fail silently
			}
			
			var aPlus:uint;
			var aMinus:uint;
			var rPlus:uint;
			var rMinus:uint;
			var gPlus:uint;
			var gMinus:uint;
			var bPlus:uint;
			var bMinus:uint;
			
			aPlus = (color >> 24 & 0xFF) + alphaRange;
			aMinus = aPlus - (alphaRange << 1);
			rPlus = (color >> 16 & 0xFF) + redRange;
			rMinus = rPlus - (redRange << 1);
			gPlus = (color >> 8 & 0xFF) + greenRange;
			gMinus = gPlus - (greenRange << 1);
			bPlus = (color & 0xFF) + blueRange;
			bMinus = bPlus - (blueRange << 1);
			
			var colorExclusion:Object = {
				color:color, 
				aPlus:aPlus, 
				aMinus:aMinus, 
				rPlus:rPlus, 
				rMinus:rMinus, 
				gPlus:gPlus, 
				gMinus:gMinus, 
				bPlus:bPlus, 
				bMinus:bMinus
			};
			colorExclusionArray.push(colorExclusion);
		}
		
		/**
		 * Removes a color from the color exclusion list.
		 * 
		 * @throws ArgumentError 	The color was not removed because it could not be found in the 
		 * 							color exclusion list.
		 */
		public function removeColorFromExclusionList(theColor:uint):void
		{
			var found:Boolean = false;
			var numColors:int = colorExclusionArray.length;
			
			for(var i:uint = 0; i < numColors; i++) {
				if(colorExclusionArray[i].color == theColor) {
					colorExclusionArray.splice(i, 1);
					found = true;
					break;
				}
			}
			
			if (!found) {
				throw new ArgumentError(
					"The color (" + theColor + ") was not removed because it could not be found " +
					"in the color exclusion list."
				);
			}
		}
		
		/** @private */
		protected function _findCollision(item1:DisplayObject, item2:DisplayObject):Collision {
			
			// Plot the registration point of both items in the global coordinate space (from their 
			// local coordinates). The localToGlobal() method takes into account any transformations 
			// that have been applied to parents so we don't need to worry about that.
			item1GlobalRegistrationPoint = item1.localToGlobal(new Point());
			item2GlobalRegistrationPoint = item2.localToGlobal(new Point());
			
			// Retrieve the transformation matrices (we will modify them belw)
			transMatrix1 = item1.transform.matrix;
			transMatrix2 = item2.transform.matrix;
			
			// Combine matrices of item1 and those of all its parents into a single one that can be
			// used at the global level. At the same time, grab the bounding box rectangle (in the
			// coordinate space of its top-level parent)
			var currentObj:DisplayObject = item1;
			while (currentObj.parent != null) {
				transMatrix1.concat(currentObj.parent.transform.matrix);
				currentObj = currentObj.parent;
			}
			
			item1BoundingBox = item1.getBounds(currentObj);
			if (item1 != currentObj) {
				item1BoundingBox.x += currentObj.x;
				item1BoundingBox.y += currentObj.y;
			}
			
			// Combine matrices of item1 and those of all its parents into a single one that can be
			// used at the global level. At the same time, grab the bounding box rectangle (in the
			// coordinate space of its top-level parent)
			currentObj = item2;
			while(currentObj.parent != null) {
				transMatrix2.concat(currentObj.parent.transform.matrix);
				currentObj = currentObj.parent;
			}
			
			item2BoundingBox = item2.getBounds(currentObj);
			if (item2 != currentObj) {
				item2BoundingBox.x += currentObj.x;
				item2BoundingBox.y += currentObj.y;
			}
			
			// Calculate the translation that needs to be applied to the global matrix of each 
			// object to match where the object is actually located in the global coordinate space
			transMatrix1.tx = (item1GlobalRegistrationPoint.x - item1BoundingBox.x);
			transMatrix1.ty = (item1GlobalRegistrationPoint.y - item1BoundingBox.y);
			transMatrix2.tx = (item2GlobalRegistrationPoint.x - item2BoundingBox.x);
			transMatrix2.ty = (item2GlobalRegistrationPoint.y - item2BoundingBox.y);
			
			
			
			
			
			
			
			

			// HOW THE FUCK CAN WE DO THIS ?!!!!!?!?!?!
			
			// Fetch the rectangle that represents the intersection of the items bounding boxes.
			// This is the only zone that needs to be drawn. The intersection() method may return 
			// rectangles with a dimension (width or height) that is smaller than a pixel. So, we 
			// need to make sure those are accouted for [using Math.ceil()]. This performs rounding 
			// by the same token
//			var intersect:Rectangle = item1BoundingBox.intersection(item2BoundingBox);
//			if (intersect.isEmpty()) return null; // THIS IS WEIRD !!!
//			intersect.width = Math.ceil(intersect.width);
//			intersect.height = Math.ceil(intersect.height);
//			
//			transMatrix1.tx = (item1GlobalRegistrationPoint.x - intersect.x);
//			transMatrix1.ty = (item1GlobalRegistrationPoint.y - intersect.y);
//			transMatrix2.tx = (item2GlobalRegistrationPoint.x - intersect.x);
//			transMatrix2.ty = (item2GlobalRegistrationPoint.y - intersect.y);
//			
//			bmd1 = new BitmapData(intersect.width, intersect.height, false, 0x00FF0000);  
//			bmd2 = new BitmapData(intersect.width, intersect.height, false, 0x0000FF00);
//			
//			bmd1.draw(item1, transMatrix1, item1.transform.colorTransform, null, null, true);
//			bmd2.draw(item2, transMatrix2, item2.transform.colorTransform, null, null, true);
//
//			addChild(new Bitmap(bmd1));
//			addChild(new Bitmap(bmd2));
			
			
			
			
			
			
			
			
			// Create transparent BitmapDatas for both items. We use the smallest since the
			bmd1 = new BitmapData(item1BoundingBox.width, item1BoundingBox.height, true, 0);  
			bmd2 = new BitmapData(item2BoundingBox.width, item2BoundingBox.height, true, 0);
			
			// Draw the items in their respective BitmapData objects while applying the 
			// transformation matrices and color transformations
			bmd1.draw(item1, transMatrix1, item1.transform.colorTransform, null, null, false);
			bmd2.draw(item2, transMatrix2, item2.transform.colorTransform, null, null, false);
			
			// Check if we have a pixel-level hit taking into account the minimum alpha threshold
			var recordedCollision:Collision = null;
			if(
				bmd1.hitTest(
					new Point(item1BoundingBox.x, item1BoundingBox.y), _alphaThreshold,
					bmd2, 
					new Point(item2BoundingBox.x, item2BoundingBox.y), _alphaThreshold
				)
			) {
				
				// If a singleTarget has been defined, put it first for convenience
				var output:Vector.<DisplayObject> = new <DisplayObject>[item1, item2];
				if (item2 == singleTarget) output.reverse();
				
				// Push items into collision array
				recordedCollision = new Collision(output);
			}
			
			// Properly free memory used be the BitmapDatas
			bmd1.dispose();
			bmd2.dispose();
			
			// Return collision (if found) or null otherwise
			return recordedCollision;
			
		}
		
		/** @private */
		protected function _findCollisionWithDetails(
			item1:DisplayObject, 
			item2:DisplayObject, 
			calculateAngles:Boolean = false,
			includeOverlapData:Boolean = false
		):Collision {
			
			var item1IsUsingAdvancedAntiAliasing:Boolean = false;
			var item2IsUsingAdvancedAntiAliasing:Boolean = false;
			var item1xDiff:Number;
			var item1yDiff:Number;
			
			// If the item is a Textfield and is using "advanced" anti-aliasing, switch it to
			// "normal" anti-aliasing while we perform detection
			if (item1 is TextField && (item1 as TextField).antiAliasType == AntiAliasType.ADVANCED) {
				item1IsUsingAdvancedAntiAliasing = true;
				(item1 as TextField).antiAliasType = AntiAliasType.NORMAL;
				
				//				item1IsUsingAdvancedAntiAliasing = ((item1 as TextField).antiAliasType == AntiAliasType.ADVANCED) ? true : false;
				//				(item1 as TextField).antiAliasType = ((item1 as TextField).antiAliasType == AntiAliasType.ADVANCED) ? AntiAliasType.NORMAL : (item1 as TextField).antiAliasType;
			}
			
			if (item2 is TextField && (item2 as TextField).antiAliasType == AntiAliasType.ADVANCED) {
				item2IsUsingAdvancedAntiAliasing = true;
				(item2 as TextField).antiAliasType = AntiAliasType.NORMAL;
			}
			
			//			if(item2 is TextField) {
			//				item2IsUsingAdvancedAntiAliasing = ((item2 as TextField).antiAliasType == "advanced") ? true : false;
			//				(item2 as TextField).antiAliasType = ((item2 as TextField).antiAliasType == "advanced") ? "normal" : (item2 as TextField).antiAliasType;
			//			}
			
			colorTransform1 = item1.transform.colorTransform;
			colorTransform2 = item2.transform.colorTransform;
			
			// We store 0,0 of the item in global coordinates
			item1GlobalRegistrationPoint = new Point();
			item2GlobalRegistrationPoint = new Point();
			item1GlobalRegistrationPoint = item1.localToGlobal(item1GlobalRegistrationPoint);
			item2GlobalRegistrationPoint = item2.localToGlobal(item2GlobalRegistrationPoint);
			
			// We create transparent BitmapDatas for both items
			bmd1 = new BitmapData(item1.width, item1.height, true, 0x00FFFFFF);  
			bmd2 = new BitmapData(item1.width, item1.height, true, 0x00FFFFFF);
			
			// we recuperate the transform matrix for object 1
			transMatrix1 = item1.transform.matrix;
			
			// Combine matrices of the object1 and all parents into one
			var currentObj:DisplayObject = item1;
			while (currentObj.parent != null) {
				transMatrix1.concat(currentObj.parent.transform.matrix);
				currentObj = currentObj.parent;
			}
			
			// Get bounds of item1 (accounting for parent movement if any)
			item1BoundingBox = item1.getBounds(currentObj);
			if (item1 != currentObj) {
				item1BoundingBox.x += currentObj.x;
				item1BoundingBox.y += currentObj.y;
			}
			
			// We take the global registration point and calculate a global translation point for the 
			// matrix
			transMatrix1.tx = item1xDiff = (item1GlobalRegistrationPoint.x - item1BoundingBox.left);
			transMatrix1.ty = item1yDiff = (item1GlobalRegistrationPoint.y - item1BoundingBox.top);
			
			// we recuperate the transform matrix for object 2
			transMatrix2 = item2.transform.matrix;
			
			// Combine matrices of the object2 and all parents into one
			currentObj = item2;
			while(currentObj.parent != null) {
				transMatrix2.concat(currentObj.parent.transform.matrix);
				currentObj = currentObj.parent;
			}
			
			transMatrix2.tx = (item2GlobalRegistrationPoint.x - item1BoundingBox.left);
			transMatrix2.ty = (item2GlobalRegistrationPoint.y - item1BoundingBox.top);
			
			// We finally draw
			bmd1.draw(item1, transMatrix1, colorTransform1, null, null, true);
			bmd2.draw(item2, transMatrix2, colorTransform2, null, null, true);
			
			pixels1 = bmd1.getPixels(new Rectangle(0, 0, bmd1.width, bmd1.height));
			pixels2 = bmd2.getPixels(new Rectangle(0, 0, bmd1.width, bmd1.height));	
			
			var k:uint = 0;
			var value1:uint = 0;
			var value2:uint = 0;
			var collisionPoint:Number = -1
			var overlap:Boolean = false;
			var overlapping:Vector.<Point> = new <Point>[];
			var locY:Number;
			var locX:Number;
			var locStage:Point;
			var hasColors:int = colorExclusionArray.length;
			
			pixels1.position = 0;
			pixels2.position = 0;
			
			var pixelLength:int = pixels1.length;
			while(k < pixelLength)
			{
				k = pixels1.position;
				
				try
				{
					value1 = pixels1.readUnsignedInt();
					value2 = pixels2.readUnsignedInt();
				}
				catch(e:EOFError)
				{
					break;
				}
				
				var alpha1:uint = value1 >> 24 & 0xFF;
				var alpha2:uint = value2 >> 24 & 0xFF;
				
				
				// Check if the alpha value of the pixel is higher than the threshold (more opaque)
				if(alpha1 >= _alphaThreshold && alpha2 >= _alphaThreshold)
				{	
					var colorFlag:Boolean = false;
					if(hasColors)
					{
						var red1:uint = value1 >> 16 & 0xFF, red2:uint = value2 >> 16 & 0xFF, green1:uint = value1 >> 8 & 0xFF, green2:uint = value2 >> 8 & 0xFF, blue1:uint = value1 & 0xFF, blue2:uint = value2 & 0xFF;
						
						var colorObj:Object, aPlus:uint, aMinus:uint, rPlus:uint, rMinus:uint, gPlus:uint, gMinus:uint, bPlus:uint, bMinus:uint, item1Flags:uint, item2Flags:uint;
						
						for(var n:uint = 0; n < hasColors; n++)
						{
							colorObj = Object(colorExclusionArray[n]);
							
							item1Flags = 0;
							item2Flags = 0;
							if((blue1 >= colorObj.bMinus) && (blue1 <= colorObj.bPlus))
							{
								item1Flags++;
							}
							if((blue2 >= colorObj.bMinus) && (blue2 <= colorObj.bPlus))
							{
								item2Flags++;
							}
							if((green1 >= colorObj.gMinus) && (green1 <= colorObj.gPlus))
							{
								item1Flags++;
							}
							if((green2 >= colorObj.gMinus) && (green2 <= colorObj.gPlus))
							{
								item2Flags++;
							}
							if((red1 >= colorObj.rMinus) && (red1 <= colorObj.rPlus))
							{
								item1Flags++;
							}
							if((red2 >= colorObj.rMinus) && (red2 <= colorObj.rPlus))
							{
								item2Flags++;
							}
							if((alpha1 >= colorObj.aMinus) && (alpha1 <= colorObj.aPlus))
							{
								item1Flags++;
							}
							if((alpha2 >= colorObj.aMinus) && (alpha2 <= colorObj.aPlus))
							{
								item2Flags++;
							}
							
							if((item1Flags == 4) || (item2Flags == 4)) colorFlag = true;
						}
					}
					
					if(!colorFlag)
					{
						overlap = true;
						
						if (includeOverlapData) {
							
							collisionPoint = k >> 2;
							
							locY = collisionPoint / bmd1.width, locX = collisionPoint % bmd1.width;
							
							locY -= item1yDiff;
							locX -= item1xDiff;
							
							locStage = item1.localToGlobal(new Point(locX, locY));
							overlapping.push(locStage);
						}
						
						
					}
				}
				
				
			}
			
			bmd1.dispose();
			bmd2.dispose();
			
			pixels1.clear();
			pixels2.clear();
			
			var recordedCollision:Collision = null;
			
			if (overlap) {
				var angle:Number = calculateAngles ? _findAngle(item1, item2) : NaN;
				
				// If a singleTarget has been defined, put it first
				var output:Vector.<DisplayObject> = new <DisplayObject>[item1, item2];
				if (item2 == singleTarget) output.reverse();
				
				recordedCollision = new Collision(output, angle, overlapping);
				objectCollisionArray.push(recordedCollision);
			}
			
			if(item1IsUsingAdvancedAntiAliasing) (item1 as TextField).antiAliasType = "advanced";
			
			if(item2IsUsingAdvancedAntiAliasing) (item2 as TextField).antiAliasType = "advanced";
			
			item1IsUsingAdvancedAntiAliasing = item2IsUsingAdvancedAntiAliasing = false;
			
			return recordedCollision;
			
		}
		
		/** @private */
		protected function _findAngle(item1:DisplayObject, item2:DisplayObject):Number {
			var center:Point = new Point((item1.width >> 1), (item1.height >> 1));
			var pixels:ByteArray = pixels2;
			transMatrix2.tx += center.x;
			transMatrix2.ty += center.y;
			bmdResample = new BitmapData(item1.width << 1, item1.height << 1, true, 0x00FFFFFF);
			bmdResample.draw(item2, transMatrix2, colorTransform2, null, null, true);
			pixels = bmdResample.getPixels(
				new Rectangle(0, 0, bmdResample.width, bmdResample.height)
			);
			
			center.x = bmdResample.width >> 1;
			center.y = bmdResample.height >> 1;
			
			var columnHeight:uint = Math.round(bmdResample.height);
			var rowWidth:uint = Math.round(bmdResample.width);
			bmdResample.dispose();
			
			var pixel:uint;
			var thisAlpha:uint;
			var lastAlpha:int;
			var edgeArray:Array = [];
			var hasColors:int = colorExclusionArray.length;
			
			for(var j:uint = 0; j < columnHeight; j++) {
				var k:uint = (j * rowWidth) << 2;
				pixels.position = k;
				lastAlpha = -1;
				var upperLimit:int = ((j + 1) * rowWidth) << 2;
				while(k < upperLimit) {
					k = pixels.position;
					
					try {
						pixel = pixels.readUnsignedInt();
					} catch(e:EOFError) {
						break;
					}
					
					thisAlpha = pixel >> 24 & 0xFF;
					
					if(lastAlpha == -1) {
						lastAlpha = thisAlpha;
					} else {
						
						if(thisAlpha > _alphaThreshold) {
							
							var colorFlag:Boolean = false;
							if(hasColors)
							{
								var red1:uint = pixel >> 16 & 0xFF, green1:uint = pixel >> 8 & 0xFF, blue1:uint = pixel & 0xFF;
								
								var colorObj:Object, a:uint, r:uint, g:uint, b:uint, item1Flags:uint;
								
								for(var n:uint = 0; n < hasColors; n++)
								{
									colorObj = Object(colorExclusionArray[n]);
									
									item1Flags = 0;
									if((blue1 >= colorObj.bMinus) && (blue1 <= colorObj.bPlus))
									{
										item1Flags++;
									}
									if((green1 >= colorObj.gMinus) && (green1 <= colorObj.gPlus))
									{
										item1Flags++;
									}
									if((red1 >= colorObj.rMinus) && (red1 <= colorObj.rPlus))
									{
										item1Flags++;
									}
									if((thisAlpha >= colorObj.aMinus) && (thisAlpha <= colorObj.aPlus))
									{
										item1Flags++;
									}									
									if(item1Flags == 4)
									{
										colorFlag = true;
									}
								}
							}
							
							if(!colorFlag) edgeArray.push(k >> 2);
						}
					}
				}
			}
			
			var edgePoint:int, numEdges:int = edgeArray.length;
			var slopeYAvg:Number = 0, slopeXAvg:Number = 0
			for(j = 0; j < numEdges; j++)
			{
				edgePoint = int(edgeArray[j]);
				
				slopeYAvg += center.y - (edgePoint / rowWidth);
				slopeXAvg += (edgePoint % rowWidth) - center.x;
			}
			
			var average:Number = -Math.atan2(slopeYAvg, slopeXAvg);
			
			return average;
		}
		
		/**
		 * Returns a string representation of the object. Useful mostly for debugging purposes.
		 */
		public override function toString():String {
			return 	'[' + getQualifiedClassName(this).match("[^:]*$")[0] + 
				' numObjects=' + numObjects + 
				', mode=' + ((mode ==  ONE_TO_MANY) ? 'ONE_TO_MANY' : 'MANY_TO_MANY') + 
				']';
		}
		
		/** 
		 * The number of objects currently in the detection list. This number includes the 
		 * <code>singleTarget</code> if it has been defined.
		 */
		public function get numObjects():uint {
			return objectArray.length;
		}
		
		/** 
		 * A <code>DisplayObject</code> against which all collision detection will exclusively take 
		 * place. Assigning a <code>singleTarget</code> changes the detection mode to ONE_TO_MANY 
		 * detection. This means that collisions will only be checked if they involve the 
		 * <code>singleTarget</code>. Other collisions amongst members of the detection list, 
		 * will be ignored.
		 * 
		 * <p>To unset the <code>singleTarget</code> and revert back to MANY_TO_MANY detection mode, 
		 * simply assign <code>null</code> to the <code>singleTarget</code> property.</p>
		 */
		public function get singleTarget():DisplayObject {
			
			if (_mode == ONE_TO_MANY) {
				return objectArray[0];
			} else {
				return null;
			}
			
		}
		
		/** @private */
		public function set singleTarget(target:DisplayObject):void {
			
			if (target) {
				if (_mode == MANY_TO_MANY) {
					_mode = ONE_TO_MANY;
					objectArray.unshift(target);
				} else {
					objectArray[0] = target;
				}
			} else {
				if (_mode == ONE_TO_MANY) {
					_mode = MANY_TO_MANY;
					objectArray.shift();
				}
			}
			
		}
		
		/** The detection mode currently in use. The value is <code>MANY_TO_MANY</code> when no 
		 * <code>singleTarget</code> has been defined and ONE_TO_MANY otherwise.
		 */
		public function get mode():String {
			return _mode;
		}
		
		/**
		 * The alpha threshold below which a collision will not be triggered. This property expects 
		 * a value between 0 and 1 inclusively. For example, a value of 0.25 means that pixels that 
		 * are less than 25% opaque will not trigger a collision.
		 * 
		 * @default 1/255 ≈ 0.004
		 */
		public function get alphaThreshold():Number {
			return _alphaThreshold / 255;
		}
		
		/** @private */
		public function set alphaThreshold(theAlpha:Number):void {
			if ((theAlpha <= 1) && (theAlpha >= 0)) {
				_alphaThreshold = Math.round(theAlpha * 255);
			} else {
				throw new RangeError(
					"The alphaThreshold property expects a value between 0 and 1 inclusively."
				);
			}
		}
		
		/**
		 * <code>Boolean</code> indicating if angles should be calculated and included in the 
		 * <code>Collision</code> objects. Leaving it <code>false</code> will improve performance.
		 * 
		 * @default false
		 */
		public function get calculateAngles():Boolean {
			return _calculateAngles;
		}
		
		/** @private */
		public function set calculateAngles(value:Boolean):void {
			_calculateAngles = value;
		}
		
		/**
		 * <code>Boolean</code> indicating if the vector of overlapping points should be calculated 
		 * and returned in the <code>Collision</code> objects. Leaving it false will improve 
		 * performance.
		 * 
		 * @default false
		 */
		public function get calculateOverlap():Boolean {
			return _calculateOverlap;
		}
		
		/** @private */
		public function set calculateOverlap(value:Boolean):void {
			_calculateOverlap = value;
		}
		
		/**
		 * <code>Boolean</code> indicating if parentless objects (those who are not on the display 
		 * list) should be ignored by the detection process. When set to <code>true</code>, objects 
		 * that are not on stage will not cause collisions.
		 *
		 * @default true 
		 */
		public function get ignoreParentless():Boolean {
			return _ignoreParentless;
		}
		
		/** @private */
		public function set ignoreParentless(value:Boolean):void {
			_ignoreParentless = value;
		}
		
		/**
		 * <code>Boolean</code> indicating if objects whose <code>visible</code> property are 
		 * <code>false</code> should be ignored by the detection process. 
		 * 
		 * @default true
		 */
		public function get ignoreInvisibles():Boolean {
			return _ignoreInvisibles;
		}
		
		/** @private */
		public function set ignoreInvisibles(value:Boolean):void {
			_ignoreInvisibles = value;
		}
		
		/** 
		 * The number of frames to skip when performing detection. By default, <code>AirBag</code>
		 * performs collision detection for each <code>ENTER_FRAME</code> event. This can be changed 
		 * by modifying the <code>skip</code> property. For example, if <code>skip</code> is set to 
		 * 3, <code>AirBag</code> will perform detection on the first <code>ENTER_FRAME</code> 
		 * event and skip the next 3 <code>ENTER_FRAME</code> events before performing detection 
		 * again. This is useful if you want to use a different frame rate for your application and
		 * for collision detection.
		 * 
		 * @default 0
		 * @since 1.0a rev1
		 */
		public function get skip():uint {
			return _skip;
		}
		
		/**
		 * @private
		 */
		public function set skip(value:uint):void {
			_skipCounter = 0;
			_skip = value;
		}
		
		
	}
	
}