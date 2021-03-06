package nme.app;

import nme.display.StageAlign;
import nme.display.StageDisplayState;
import nme.display.StageQuality;
import nme.display.StageScaleMode;

class Window 
{
   public var active(default, default):Bool;
   public var align(get, set):StageAlign;
   public var displayState(get, set):StageDisplayState;
   public var dpiScale(get, null):Float;
   public var isOpenGL(get, null):Bool;
   public var quality(get, set):StageQuality;
   public var scaleMode(get, set):StageScaleMode;
   public var x(get, null):Int;
   public var y(get, null):Int;
   public var height(get, null):Int;
   public var width(get, null):Int;
   public var autoClear:Bool;


   // Set this to handle events...
   public var appEventHandler:IAppEventHandler;


   public var nmeHandle(default,null):Dynamic;
   var enterFramePending:Bool;
   var invalidFramePending:Bool;

   public function new(inFrameHandle:Dynamic,inWidth:Int,inHeight:Int)
   {
      appEventHandler = null;
      active = true;
      invalidFramePending = false;
      autoClear = true;

      nmeHandle = nme_get_frame_stage(inFrameHandle);
      nme_set_stage_handler(nmeHandle, nmeProcessWindowEvent, inWidth, inHeight);
   }

   public function shouldRenderNow() : Bool
   {
      #if android
      nme_stage_request_render();
      return false;
      #else
      return true;
      #end
   }

   public function setBackground(inBackground:Null<Int>) : Void
   {
      if (inBackground == null)
         nme_display_object_set_bg(nmeHandle, 0);
      else
         nme_display_object_set_bg(nmeHandle, inBackground | 0xff000000);
   }


   public function onNewFrame():Void
   {
      if (shouldRenderNow())
      {
         beginRender();
         appEventHandler.onRender(RenderFrameReady);
         endRender();
      }
      else
      {
         // On android, we must wait for the redraw before rendering.
         // Set the flag se we don't have more enterframes than render
         enterFramePending = true;
      }
   }


   public function onInvalidFrame():Void
   {
      if (shouldRenderNow())
      {
         beginRender();
         appEventHandler.onRender(RenderInvalid);
         endRender();
      }
      else
      {
         // On android, we must wait for the redraw before rendering.
         // Set the flag se we don't have more enterframes than render
         invalidFramePending = true;
      }
   }


   function nmeProcessWindowEvent(inEvent:Dynamic)
   {
      if (appEventHandler==null)
          return;

      var event:AppEvent = inEvent;
      try
      {
         #if !(cpp && hxcpp_api_level>=311)
         inEvent.pollTime = haxe.Timer.stamp();
         #end

         switch(event.type)
         {
            case EventId.Poll:
               Application.pollClients(event.pollTime);
   
            case EventId.Char: // Ignore
   
            case EventId.KeyDown:
               appEventHandler.onKey(event, EventName.KEY_DOWN);
   
            case EventId.KeyUp:
               appEventHandler.onKey(event, EventName.KEY_UP);
   
            case EventId.MouseMove:
               appEventHandler.onMouse(event, EventName.MOUSE_MOVE, true);
   
            case EventId.MouseDown:
               appEventHandler.onMouse(event, EventName.MOUSE_DOWN, true);
   
            case EventId.MouseClick:
               appEventHandler.onMouse(event, EventName.CLICK, true);
   
            case EventId.MouseUp:
               appEventHandler.onMouse(event, EventName.MOUSE_UP, true);
   
            case EventId.Resize:
               appEventHandler.onResize(event.x, event.y);
               if (shouldRenderNow())
               {
                  beginRender();
                  appEventHandler.onRender(RenderDirty);
                  endRender();
               }
   
            case EventId.Quit:
               if (Application.onQuit != null)
                  Application.onQuit();
   
            case EventId.Focus:
               appEventHandler.onDisplayObjectFocus(event);
   
            case EventId.ShouldRotate:
               // Removed
   
            case EventId.Redraw:
               beginRender();
               if (invalidFramePending)
               {
                  invalidFramePending = false;
                  appEventHandler.onRender(RenderInvalid);
               }
               else if (enterFramePending)
               {
                  enterFramePending = false;
                  appEventHandler.onRender(RenderFrameReady);
               }
               else
               {
                  appEventHandler.onRender(RenderDirty);
               }
               endRender();
   
            case EventId.TouchBegin:
               appEventHandler.onTouch(event,EventName.TOUCH_BEGIN);
               if ((event.flags & 0x8000) > 0)
                  appEventHandler.onMouse(event, EventName.MOUSE_DOWN, false);
   
            case EventId.TouchMove:
               appEventHandler.onTouch(event,EventName.TOUCH_MOVE);
   
            case EventId.TouchEnd:
               appEventHandler.onTouch(event,EventName.TOUCH_END);
               if ((event.flags & 0x8000) > 0)
                  appEventHandler.onMouse(event, EventName.MOUSE_UP, false);
   
            case EventId.TouchTap:
               appEventHandler.onTouch(event,EventName.TOUCH_TAP);
   
            case EventId.Change:
               appEventHandler.onChange(event);
   
            case EventId.Activate:
               appEventHandler.onActive(true);
   
            case EventId.Deactivate:
               appEventHandler.onActive(false);
   
            case EventId.GotInputFocus:
               appEventHandler.onInputFocus(true);
   
            case EventId.LostInputFocus:
               appEventHandler.onInputFocus(false);
   
            case EventId.JoyAxisMove:
               appEventHandler.onJoystick(event, EventName.AXIS_MOVE);
   
            case EventId.JoyBallMove:
               appEventHandler.onJoystick(event, EventName.BALL_MOVE);
   
            case EventId.JoyHatMove:
               appEventHandler.onJoystick(event, EventName.HAT_MOVE);
   
            case EventId.JoyButtonDown:
               appEventHandler.onJoystick(event, EventName.BUTTON_DOWN);
   
            case EventId.JoyButtonUp:
               appEventHandler.onJoystick(event, EventName.BUTTON_UP);
   
            case EventId.SysWM:
               appEventHandler.onSysMessage(event);
   
            case EventId.RenderContextLost:
               appEventHandler.onContextLost();
         }


         var nextWake = Application.getNextWake(event.pollTime);
         #if (cpp && hxcpp_api_level>=311)
         event.pollTime = nextWake;
         #else
         nme_stage_set_next_wake(nmeHandle,nextWake);
         #end
      }
      catch(e:Dynamic)
      {
        var stack = haxe.CallStack.exceptionStack();
        trace(e);
        trace(haxe.CallStack.toString(stack));
        event.pollTime = 0;
        throw(e);
      }
   }

   function beginRender() nme_stage_begin_render(nmeHandle,autoClear);
   function endRender() nme_stage_end_render(nmeHandle);


   public function get_align():StageAlign 
   {
      var i:Int = nme_stage_get_align(nmeHandle);
      return Type.createEnumIndex(StageAlign, i);
   }

   public function set_align(inMode:StageAlign):StageAlign 
   {
      nme_stage_set_align(nmeHandle, Type.enumIndex(inMode));
      return inMode;
   }

   public function get_displayState():StageDisplayState 
   {
      var i:Int = nme_stage_get_display_state(nmeHandle);
      return Type.createEnumIndex(StageDisplayState, i);
   }

   public function set_displayState(inState:StageDisplayState):StageDisplayState 
   {
      nme_stage_set_display_state(nmeHandle, Type.enumIndex(inState));
      return inState;
   }

   public function get_dpiScale():Float 
   {
      return nme_stage_get_dpi_scale(nmeHandle);
   }



   public function get_isOpenGL():Bool 
   {
      return nme_stage_is_opengl(nmeHandle);
   }

   public function get_quality():StageQuality 
   {
      var i:Int = nme_stage_get_quality(nmeHandle);
      return Type.createEnumIndex(StageQuality, i);
   }

   public function set_quality(inQuality:StageQuality):StageQuality 
   {
      nme_stage_set_quality(nmeHandle, Type.enumIndex(inQuality));
      return inQuality;
   }

   public function get_scaleMode():StageScaleMode 
   {
      var i:Int = nme_stage_get_scale_mode(nmeHandle);
      return Type.createEnumIndex(StageScaleMode, i);
   }

   public function set_scaleMode(inMode:StageScaleMode):StageScaleMode 
   {
      nme_stage_set_scale_mode(nmeHandle, Type.enumIndex(inMode));
      return inMode;
   }

   public function get_x():Int 
   {
      return nme_stage_get_window_x(nmeHandle);
   }

   public function get_y():Int 
   {
      return nme_stage_get_window_y(nmeHandle);
   }



   public function get_height():Int 
   {
      return Std.int(cast(nme_stage_get_stage_height(nmeHandle), Float));
   }

   public function get_width():Int 
   {
      return Std.int(cast(nme_stage_get_stage_width(nmeHandle), Float));
   }


   public function resize(width:Int, height:Int):Void
   {
      nme_stage_resize_window(nmeHandle, width, height);
   }


   public function setPosition(x:Int, y:Int):Void
   {
      nme_stage_set_window_position(nmeHandle, x, y);
   }



   private static var nme_stage_resize_window = Loader.load("nme_stage_resize_window", 3);
   private static var nme_stage_is_opengl = Loader.load("nme_stage_is_opengl", 1);
   private static var nme_stage_get_stage_width = Loader.load("nme_stage_get_stage_width", 1);
   private static var nme_stage_get_stage_height = Loader.load("nme_stage_get_stage_height", 1);
   private static var nme_stage_get_dpi_scale = Loader.load("nme_stage_get_dpi_scale", 1);
   private static var nme_stage_get_scale_mode = Loader.load("nme_stage_get_scale_mode", 1);
   private static var nme_stage_set_scale_mode = Loader.load("nme_stage_set_scale_mode", 2);
   private static var nme_stage_get_align = Loader.load("nme_stage_get_align", 1);
   private static var nme_stage_set_align = Loader.load("nme_stage_set_align", 2);
   private static var nme_stage_get_quality = Loader.load("nme_stage_get_quality", 1);
   private static var nme_stage_set_quality = Loader.load("nme_stage_set_quality", 2);
   private static var nme_stage_get_display_state = Loader.load("nme_stage_get_display_state", 1);
   private static var nme_stage_set_display_state = Loader.load("nme_stage_set_display_state", 2);
   private static var nme_stage_show_cursor = Loader.load("nme_stage_show_cursor", 2);
   private static var nme_stage_set_fixed_orientation = Loader.load("nme_stage_set_fixed_orientation", 1);
   private static var nme_stage_get_orientation = Loader.load("nme_stage_get_orientation", 0);
   private static var nme_stage_get_normal_orientation = Loader.load("nme_stage_get_normal_orientation", 0);
   private static var nme_stage_set_window_position = Loader.load("nme_stage_set_window_position", 3);
   private static var nme_stage_get_window_x = Loader.load("nme_stage_get_window_x", 1);
   private static var nme_stage_get_window_y = Loader.load("nme_stage_get_window_y", 1);
   private static var nme_stage_set_next_wake = Loader.load("nme_stage_set_next_wake", 2);
   private static var nme_stage_begin_render = Loader.load("nme_stage_begin_render", 2);
   private static var nme_stage_end_render = Loader.load("nme_stage_end_render", 1);

   private static var nme_get_frame_stage = Loader.load("nme_get_frame_stage", 1);
   private static var nme_display_object_set_bg = Loader.load("nme_display_object_set_bg", 2);

   #if android
   private static var nme_stage_request_render = Loader.load("nme_stage_request_render", 0);
   #end
   #if (cpp && hxcpp_api_level>=311)
   private static var nme_set_stage_handler = Loader.load("nme_set_stage_handler_native", 4);
   #else
   private static var nme_set_stage_handler = Loader.load("nme_set_stage_handler", 4);
   #end
}


