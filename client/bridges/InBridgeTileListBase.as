// Copyright 2011 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS-IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
package bridges
{
	import bridges.basket.BasketItem;
	
	import controls.list.PicnikTileList;
	
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.ui.Keyboard;
	
	import mx.events.ListEvent;

	// This a bridge specific tile list which uses the BridgeItem tile renderer and knows
	// how to generate bridge events. To use this, do the following:
	// 1. Include it in your bridge MXML
	// 2. Set the item renderer to "bridges.BridgeItem"
	// 3. Specify the dataProvider (use an array of ImageThumbs). use SmartUpdateDataProvider to set the data provider nicely.
	// 4. Listen for and react to BridgeItemEvents
	public class InBridgeTileListBase extends PicnikTileList {

		[Bindable] public var singleClickEdit:Boolean = false;
		
		private var _nSmallestMouseWheel:Number = NaN;
		
		// TileLists already scroll in rediculous big chunks then mousewheel
		// events introduce a multiplier. Back it off to something reasonable		
	    override protected function mouseWheelHandler(event:MouseEvent):void {
	    	var nAbsDelta:Number = Math.abs(event.delta);
	    	if (isNaN(_nSmallestMouseWheel)) {
	    		_nSmallestMouseWheel = nAbsDelta;
	    	} else if (nAbsDelta < _nSmallestMouseWheel) {
	    		_nSmallestMouseWheel = nAbsDelta;
	    	}
	    	if (Math.abs(event.delta) <= nAbsDelta && event.delta != 0) {
	    		event.delta = event.delta / nAbsDelta;
	    	} else {
		    	event.delta = int(event.delta / nAbsDelta);
		    }
	    	super.mouseWheelHandler(event);
	    }
	   
		public function get selectedBridgeItem(): BridgeItemBase {
			if (selectedIndex == -1) return null;
			return BridgeItemBase(indexToItemRenderer(selectedIndex));
		}
		
		protected override function initializationComplete(): void {
			super.initializationComplete();
				
			addEventListener(ListEvent.ITEM_DOUBLE_CLICK, OnTileListItemClickOrDoubleClick);
			addEventListener(ListEvent.ITEM_CLICK, OnTileListItemClickOrDoubleClick);
			addEventListener(KeyboardEvent.KEY_DOWN, OnKeyDown);
		}
		
		// Generate our own event when an item is clicked or double clicked.
		private function OnTileListItemClickOrDoubleClick(evt:ListEvent): void {
			var britm:BridgeItemBase = BridgeItemBase(evt.itemRenderer);
			
			// Interested parties can know when bridge items are clicked/double-clicked and can
			// prevent the usual behavior (adding/opening the item) from happening.
			var evtClick:BridgeItemEvent = new BridgeItemEvent(evt.type == ListEvent.ITEM_CLICK ?
					BridgeItemEvent.CLICK : BridgeItemEvent.DOUBLE_CLICK, britm, null, null, true, true);
			dispatchEvent(evtClick);
			if (evtClick.isDefaultPrevented())
				return;
			
			if (singleClickEdit == (evt.type == ListEvent.ITEM_CLICK)) {
				var addItemToGallery:Boolean = (evt.itemRenderer is BasketItem &&
						PicnikBase.app.activeDocument != null && PicnikBase.app.activeDocument is GalleryDocument);
				dispatchEvent(new BridgeItemEvent(BridgeItemEvent.ITEM_ACTION, britm,
						addItemToGallery ? Bridge.ADD_GALLERY_ITEM : Bridge.EDIT_ITEM));
			}
		}

		// Generate our own even whent enter is pressed
		protected function OnKeyDown(evt:KeyboardEvent): void {
			if (evt.keyCode == Keyboard.ENTER) {
				dispatchEvent(new BridgeItemEvent(BridgeItemEvent.ITEM_ACTION, selectedBridgeItem, Bridge.EDIT_ITEM));
			}
		}
	}
}
