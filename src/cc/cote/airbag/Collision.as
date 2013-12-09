package cc.cote.airbag
{
	
	import flash.display.DisplayObject;
	import flash.geom.Point;
	
	import avmplus.getQualifiedClassName;

	/**
	 * The <code>Collision</code> class contains information about a collision that occured between 
	 * two <code>DisplayObject</code>s. The <code>AirBag.detect()</code> method returns a 
	 * vector of such objects when performing collision detection.
	 * @see cc.cote.airbag.AirBag
	 */
	public class Collision
	{
		
		private var _objects:Vector.<DisplayObject>;
		private var _angle:Number;
		private var _overlapping:Vector.<Point>;
		
		/**
		 * Creates a <code>Collision</code> object. This object contains properties describing a
		 * collision that was detected between two objects (typically by the 
		 * <code>CollisionDetector</code> class).
		 * 
		 * @param objects 	A vector of the objects that collided. 
		 * @param angle 	The angle of collision (in radians)
		 * @param overlapping A vector of all overlapping points between the colliding objects
		 */
		public function Collision(
			objects:Vector.<DisplayObject>, 
			angle:Number = NaN, 
			overlapping:Vector.<Point> = null
		):void {
			
			_objects = objects;
			_angle = angle;
			
			if (overlapping && overlapping.length > 0) {
				_overlapping = overlapping;
			} else {
				_overlapping = null
			}
			
		}
		
		/**
		 * Returns a string representation of the object. Useful mostly for debugging purposes.
		 */
		public function toString():String {
			return 	'[' + 
						getQualifiedClassName(this).match("[^:]*$")[0] + 
						' angle="' + angle + 
						'" angleInDegrees="' + angleInDegrees + 
						'", overlapping ' + (overlapping ? 'enabled' : 'disabled') + 
					']';
		}
		
		/**
		 * A vector of the two <code>DisplayObject</code>s that collided. Note: the 
		 * <code>AirBag</code> class will always put the <code>singleTarget</code> (if one has been 
		 * defined) at index 0.
		 */
		public function get objects():Vector.<DisplayObject> {
			return _objects;
		}
		
		/** 
		 * Returns the angle (in degrees) of the collision between the two 
		 * <code>DisplayObject</code>s. If you need the angle in radians, simply use the 
		 * <code>angle</code> property.
		 */
		public function get angleInDegrees():Number {
			return _angle * 180 / Math.PI;
		}

		/**
		 * The angle of the collision (in radians) between the two <code>DisplayObject</code>s. It
		 * will return <code>NaN</code> if the angle calculation was not performed (for performance
		 * reasons). 
		 * 
		 * <p>If you need the angle in degrees, you can use the <code>angleInDegrees</code> 
		 * property.</p>
		 */
		public function get angle():Number {
			return _angle;
		}

		/**
		 * A vector of all the overlapping points during the collision (in stage coordinates). This
		 * could be <code>null</code> if the calculation was not performed (for performance 
		 * reasons).
		 */
		public function get overlapping():Vector.<Point> {
			return _overlapping;
		}

	}
	
}