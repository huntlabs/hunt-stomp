/*
 * Copyright 2002-2018 the original author or authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

module hunt.stomp.support.ChannelInterceptorAdapter;


// import hunt.stomp.Message;
// import hunt.stomp.MessageChannel;

// /**
//  * A {@link ChannelInterceptor} base class with empty method implementations
//  * as a convenience.
//  *
//  * @author Mark Fisher
//  * @author Rossen Stoyanchev
//  * @since 4.0
//  * @deprecated as of 5.0.7 {@link ChannelInterceptor} has default methods (made
//  * possible by a Java 8 baseline) and can be implemented directly without the
//  * need for this no-op adapter
//  */
// @Deprecated
// abstract class ChannelInterceptorAdapter : ChannelInterceptor {

// 	override
// 	MessageBase preSend(MessageBase message, MessageChannel channel) {
// 		return message;
// 	}

// 	override
// 	void postSend(MessageBase message, MessageChannel channel,  sent) {
// 	}

// 	override
// 	void afterSendCompletion(MessageBase message, MessageChannel channel,  sent, Exception ex) {
// 	}

// 	 preReceive(MessageChannel channel) {
// 		return true;
// 	}

// 	override
// 	MessageBase postReceive(MessageBase message, MessageChannel channel) {
// 		return message;
// 	}

// 	override
// 	void afterReceiveCompletion(MessageBase message, MessageChannel channel, Exception ex) {
// 	}

// }
