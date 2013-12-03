package cc.cote.airbag
{
	import flash.events.Event;
	
	/** 
	 * An <code>AirBagEvent</code> object is dispatched by the <code>AirBag</code> object when it 
	 * performs its collision detection routine on <code>ENTER_FRAME</code>.
	 *  
	 * Please note that this object inherits properties and methods from 
	 * <code>flash.events.Event</code>. You will have to look up 
	 * <a href="http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/" target="blank">
	 * ActionScript's API documentation</a> for those inherited elements.
	 * 
	 * @see cc.cote.airbag.AirBag
	 * @see cc.cote.airbag.Collision
	 * @see http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/flash/events/Event.html ActionScript's Event Class Reference
	 * @since 1.0a rev1
	 */  
	public class AirBagEvent extends Event
	{
		
		/** 
		 * The <code>DETECTION</code> constant defines the value of the <code>type</code> property 
		 * of a <code>detection</code> event object.
		 * 
		 * @eventType detection
		 */
		public static const DETECTION:String = "detection";
		
		/** 
		 * The <code>COLLISION</code> constant defines the value of the <code>type</code> property 
		 * of a <code>collision</code> event object.
		 * 
		 * @eventType collision
		 */
		public static const COLLISION:String = "collision";
		
		/** @private */
		private var _collisions:Vector.<Collision>;
		
		/**
		 * Creates a new <code>AirBagEvent</code> object. <code>AirBagEvent</code> is, basically, a 
		 * standard <code>flash.events.Event</code> with the simple addition of the 
		 * <code>collisions</code> property which holds a <code>Vector</code> of 
		 * <code>Collision</code> objects (if appropriate).
		 * 
		 * @param type 			Type of the event. Can be <code>AirBagEvent.COLLISION</code> or
		 * 						<code>AirBagEvent.DETECTION</code>.
		 * @param bubbles		Determines whether the <code>Event</code> object participates in the 
		 * 						bubbling phase of the event flow.
		 * @param cancelable	Determines whether the <code>Event</code> object can be canceled.
		 * @param collisions 	A <code>Vector</code> of <code>Collision</code> objects for each
		 * 						detected collisions.
		 */
		public function AirBagEvent(
			type:String, 
			bubbles:Boolean = false, 
			cancelable:Boolean = false,
			collisions:Vector.<Collision> = null
		) {
			super(type, bubbles, cancelable);
			_collisions = collisions;
		}
		
		/** A vector of <code>Collision</code> objects representing each collision detected. */
		public function get collisions():Vector.<Collision> {
			return _collisions;
		}

	}
	
}