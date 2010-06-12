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

#import "MumbleAppDelegate.h"
#import <MumbleKit/MKAudio.h>

@implementation MumbleAppDelegate

@synthesize window;

- (void) applicationDidFinishLaunching:(NSNotification *)aNotification {
	[MKAudio initializeAudio];

	_globalShortcut = [[GlobalShortcut alloc] init];

	[_connectButton setTarget:self];
	[_connectButton setAction:@selector(connectClicked:)];
}

- (void) connectClicked:(id)sender {
	NSString *hostName = [_hostNameField stringValue];
	NSString *portNumber = [_portField stringValue];

	if (_connection && _serverModel) {
		[self log:[NSString stringWithFormat:@"Disconnecting...", hostName, portNumber]];

		[_connection closeStreams];
		[_serverModel release];
		[_connection release];
		_connection = nil;
		_serverModel = nil;

		[[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:@"MKUserTalkStateChanged"];

		[_connectButton setTitle:@"Connect!"];
	} else {
		_connection = [[MKConnection alloc] init];
		[_connection setDelegate:self];
		_serverModel = [[MKServerModel alloc] initWithConnection:_connection];
		[_connection connectToHost:hostName port:[portNumber intValue]];
		[_serverModel addDelegate:self];

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userTalkStateChanged:) name:@"MKUserTalkStateChanged" object:nil];

		[self log:[NSString stringWithFormat:@"Connecting to %@:%@...", hostName, portNumber]];
		[_connectButton setTitle:@"Disconnect!"];
	}
}

- (void) log:(NSString *)text {
	[_logView scrollRangeToVisible:NSMakeRange([[_logView string] length], 0)];
	NSDate *date = [NSDate date];
	[_logView insertText:[NSString stringWithFormat:@"[%@] ", [date description]]];
	[_logView insertText:text];
	[_logView insertText:@"\n"];
}

#pragma mark -
#pragma mark MKUserTalkStateChanged

- (void) userTalkStateChanged:(NSNotification *)notification {
	[self log:@"talkStateChanged"];
}

#pragma mark -
#pragma mark MKConnection delegate

//
// The server rejected our connection.
//
- (void) connection:(MKConnection *)conn rejectedWithReason:(MKRejectReason)reason explanation:(NSString *)explanation {
	NSString *msg = nil;

	switch (reason) {
		case MKRejectReasonNone:
			msg = @"No reason";
			break;
		case MKRejectReasonWrongVersion:
			msg = @"Version mismatch between client and server.";
			break;
		case MKRejectReasonInvalidUsername:
			msg = @"Invalid username";
			break;
		case MKRejectReasonWrongUserPassword:
			msg = @"Wrong user password";
			break;
		case MKRejectReasonWrongServerPassword:
			msg = @"Wrong server password";
			break;
		case MKRejectReasonUsernameInUse:
			msg = @"Username already in use";
			break;
		case MKRejectReasonServerIsFull:
			msg = @"Server is full";
			break;
		case MKRejectReasonNoCertificate:
			msg = @"A certificate is needed to connect to this server";
			break;
	}

	[self log:[NSString stringWithFormat:@"Error: %@", msg]];
}

//
// An SSL connection has been opened to the server.  We should authenticate ourselves.
//
- (void) connectionOpened:(MKConnection *)conn {
	NSString *userName = [_userNameField stringValue];
	NSString *passWord = [[_passWordField stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	if ([passWord isEqualTo:@""])
		passWord = nil;
	[conn authenticateWithUsername:userName password:passWord];
}

#pragma mark -
#pragma mark MKServerModel delegate

//
// We've successfuly joined the server.
//
- (void) serverModel:(MKServerModel *)server joinedServerAsUser:(MKUser *)user {
	[self log:@"joinedServerAsUser"];
}

//
// A user joined the server.
//
- (void) serverModel:(MKServerModel *)server userJoined:(MKUser *)user {
	[self log:@"userJoined"];
}

//
// A user left the server.
//
- (void) serverModel:(MKServerModel *)server userLeft:(MKUser *)user {
	[self log:@"userLeft"];
}

//
// A user moved channel
//
- (void) serverModel:(MKServerModel *)server userMoved:(MKUser *)user toChannel:(MKChannel *)chan byUser:(MKUser *)mover {
	[self log:@"userMoved"];
}

//
// A channel was added.
//
- (void) serverModel:(MKServerModel *)server channelAdded:(MKChannel *)channel {
	[self log:@"channelAdded"];
}

//
// A channel was removed.
//
- (void) serverModel:(MKServerModel *)server channelRemoved:(MKChannel *)channel {
	[self log:@"channelRemoved"];
}

@end
