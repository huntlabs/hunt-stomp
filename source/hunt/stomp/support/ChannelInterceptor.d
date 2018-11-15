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

module hunt.stomp.support.ChannelInterceptor;

import hunt.stomp.Message;
import hunt.stomp.MessageChannel;

/**
 * Interface for interceptors that are able to view and/or modify the
 * {@link Message Messages} being sent-to and/or received-from a
 * {@link MessageChannel}.
 *
 * @author Mark Fisher
 * @author Rossen Stoyanchev
 * @since 4.0
 * @see Message
 * @see MessageChannel
 */
abstract class ChannelInterceptor {

	/**
	 * Invoked before the Message is actually sent to the channel.
	 * This allows for modification of the Message if necessary.
	 * If this method returns {@code null} then the actual
	 * send invocation will not occur.
	 */
	
	MessageBase preSend(MessageBase message, MessageChannel channel) {
		return message;
	}

	/**
	 * Invoked immediately after the send invocation. The 
	 * value argument represents the return value of that invocation.
	 */
	void postSend(MessageBase message, MessageChannel channel, bool sent) {
	}

	/**
	 * Invoked after the completion of a send regardless of any exception that
	 * have been raised thus allowing for proper resource cleanup.
	 * <p>Note that this will be invoked only if {@link #preSend} successfully
	 * completed and returned a Message, i.e. it did not return {@code null}.
	 * @since 4.1
	 */
	void afterSendCompletion(
			MessageBase message, MessageChannel channel, bool sent, Exception ex) {
	}

	/**
	 * Invoked as soon as receive is called and before a Message is
	 * actually retrieved. If the return value is 'false', then no
	 * Message will be retrieved. This only applies to PollableChannels.
	 */
	bool preReceive(MessageChannel channel) {
		return true;
	}

	/**
	 * Invoked immediately after a Message has been retrieved but before
	 * it is returned to the caller. The Message may be modified if
	 * necessary; {@code null} aborts further interceptor invocations.
	 * This only applies to PollableChannels.
	 */
	
	MessageBase postReceive(MessageBase message, MessageChannel channel) {
		return message;
	}

	/**
	 * Invoked after the completion of a receive regardless of any exception that
	 * have been raised thus allowing for proper resource cleanup.
	 * <p>Note that this will be invoked only if {@link #preReceive} successfully
	 * completed and returned {@code true}.
	 * @since 4.1
	 */
	void afterReceiveCompletion(MessageBase message, MessageChannel channel,
			Exception ex) {
	}

}
