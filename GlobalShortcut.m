/* Copyright (C) 2010 Mikkel Krautz <mikkel@krautz.dk>

   All rights reserved.

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions
   are met:

   - Redistributions of source code must retain the above copyright notice,
     this list of conditions and the following disclaimer.
   - Redistributions in binary form must reproduce the above copyright notice,
     this list of conditions and the following disclaimer in the documentation
     and/or other materials provided with the distribution.
   - Neither the name of the Mumble Developers nor the names of its
     contributors may be used to endorse or promote products derived from this
     software without specific prior written permission.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
   ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
   A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE FOUNDATION OR
   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
   EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
   PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
   LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
   NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "GlobalShortcut.h"

#import <MumbleKit/MKAudioInput.h>

#define MOUSE_OFFSET 0x1000

static CGEventRef GlobalShortcutCallback(CGEventTapProxy proxy, CGEventType type,
										 CGEventRef event, void *udata) {
	GlobalShortcut *gs = (GlobalShortcut *) udata;
	unsigned int keycode;
	BOOL down = NO;
	BOOL repeat = NO;
	
	switch (type) {
		case kCGEventLeftMouseDown:
		case kCGEventRightMouseDown:
		case kCGEventOtherMouseDown:
			down = YES;
		case kCGEventLeftMouseUp:
		case kCGEventRightMouseUp:
		case kCGEventOtherMouseUp:
			keycode = (unsigned int)(CGEventGetIntegerValueField(event, kCGMouseEventButtonNumber));
			[gs handleButton:MOUSE_OFFSET+keycode down:down];
			break;
		case kCGEventKeyDown:
			down = YES;
		case kCGEventKeyUp:
			repeat = CGEventGetIntegerValueField(event, kCGKeyboardEventAutorepeat);
			if (! repeat) {
				keycode = (unsigned int)(CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode));
				[gs handleButton:keycode down:down];
			}
			break;
		case kCGEventTapDisabledByTimeout:
			CGEventTapEnable([gs eventTap], YES);
			break;
	}

	return event;
}

@implementation GlobalShortcut

- (id) init {
	self = [super init];
	if (self == nil)
		return self;

	const CGEventType evmask = CGEventMaskBit(kCGEventLeftMouseDown) |
							   CGEventMaskBit(kCGEventLeftMouseUp) |
							   CGEventMaskBit(kCGEventRightMouseDown) |
							   CGEventMaskBit(kCGEventRightMouseUp) |
							   CGEventMaskBit(kCGEventOtherMouseDown) |
							   CGEventMaskBit(kCGEventOtherMouseUp) |
							   CGEventMaskBit(kCGEventKeyDown) |
							   CGEventMaskBit(kCGEventKeyUp) |
							   CGEventMaskBit(kCGEventFlagsChanged) |
							   CGEventMaskBit(kCGEventTapDisabledByTimeout) |
							   CGEventMaskBit(kCGEventTapDisabledByUserInput);

	_port = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap, 0, evmask, GlobalShortcutCallback, self);
	if (_port == NULL) {
		NSLog(@"Unable to create event tap.");
		return nil;
	}

	CFRunLoopRef loop = CFRunLoopGetCurrent();
	CFRunLoopSourceRef src = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, _port, 0);
	CFRunLoopAddSource(loop, src, kCFRunLoopCommonModes);

	return self;
}

- (void) dealloc {
	[super dealloc];
}

- (CFMachPortRef) eventTap {
	return _port;
}

- (void) handleButton:(unsigned int)keyCode down:(BOOL)flag {
	NSLog(@"handleButton %u %u", keyCode, flag);
	
	// Mouse 0 button
	if (MOUSE_OFFSET + 0) {
		MKAudioInput *audioInput = [MKAudio audioInput];
		[audioInput setForceTransmit:flag];
	}
}

@end
