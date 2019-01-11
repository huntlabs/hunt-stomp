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

module hunt.stomp.simp.broker.OrderedMessageSender;

import hunt.stomp.support.ChannelInterceptor;

import hunt.collection;
import hunt.util.Common;
import hunt.Exceptions;
import hunt.logging;

import hunt.stomp.Message;
import hunt.stomp.MessageChannel;
import hunt.stomp.simp.SimpMessageHeaderAccessor;
import hunt.stomp.support.ExecutorChannelInterceptor;
import hunt.stomp.support.ExecutorSubscribableChannel;
import hunt.stomp.support.MessageHeaderAccessor;

import core.atomic;
import std.conv;
import std.container.dlist;

/**
 * Submit messages to an {@link ExecutorSubscribableChannel}, one at a time.
 * The channel must have been configured with {@link #configureOutboundChannel}.
 *
 * @author Rossen Stoyanchev
 * @since 5.1
 */
class OrderedMessageSender : MessageChannel {

	enum string COMPLETION_TASK_HEADER = "simpSendCompletionTask";

	private MessageChannel channel;

	// private Queue!(MessageBase) messages;
	private DList!(MessageBase) messages;

	private shared bool sendInProgress = false;


	this(MessageChannel channel) {
		this.channel = channel;
	}

	private void initlize() {
		// messages = new ConcurrentLinkedQueue<>();
		// messages = new LinkedQueue!(MessageBase)();
	}

	// bool send(MessageBase message) {
	// 	return send(message, -1);
	// }

	override
	bool send(MessageBase message, long timeout) {
		this.messages.insertBack(message);
		trySend();
		return true;
	}

	private void trySend() {
		// Take sendInProgress flag only if queue is not empty
		if (this.messages.empty) {
			return;
		}

		if (cas(&this.sendInProgress, false, true)) {
			sendNextMessage();
		}
	}

	private void sendNextMessage() {
		for (;;) {
			MessageBase message = this.messages.front;
			this.messages.removeFront();
			if (message !is null) {
				try {
					addCompletionCallback(message);
					if (this.channel.send(message)) {
						return;
					}
				}
				catch (Throwable ex) {
					version(HUNT_DEBUG) {
						error("Failed to send " ~ message.to!string(), ex);
					}
				}
			}
			else {
				// We ran out of messages..
				this.sendInProgress = false;
				trySend();
				break;
			}
		}
	}

	private void addCompletionCallback(MessageBase msg) {
		implementationMissing(false);
		// SimpMessageHeaderAccessor accessor = MessageHeaderAccessor.getAccessor(msg, SimpMessageHeaderAccessor.class);
		// assert(accessor !is null && accessor.isMutable(), "Expected mutable SimpMessageHeaderAccessor");
		// accessor.setHeader(COMPLETION_TASK_HEADER, &this.sendNextMessage);
	}


	/**
	 * Install or remove an {@link ExecutorChannelInterceptor} that invokes a
	 * completion task once the message is handled.
	 * @param channel the channel to configure
	 * @param preservePublishOrder whether preserve order is on or off based on
	 * which an interceptor is either added or removed.
	 */
	static void configureOutboundChannel(MessageChannel channel, bool preservePublishOrder) {
		if (preservePublishOrder) {
			ExecutorSubscribableChannel execChannel = cast(ExecutorSubscribableChannel) channel;
			assert(execChannel !is null, 
				"An ExecutorSubscribableChannel is required for `preservePublishOrder`");
			implementationMissing(false);
			// if (execChannel.getInterceptors().stream().noneMatch(i -> i instanceof CallbackInterceptor)) {
			// 	execChannel.addInterceptor(0, new CallbackInterceptor());
			// }
		}
		else {
			ExecutorSubscribableChannel execChannel = cast(ExecutorSubscribableChannel) channel;
			if(execChannel !is null) {
				foreach(ChannelInterceptor i; execChannel.getInterceptors()) {
					CallbackInterceptor ci = cast(CallbackInterceptor)i;
					if(ci !is null)	{
						execChannel.removeInterceptor(ci);
						break;
					}
				}
			}
		}
	}

}



private class CallbackInterceptor : ExecutorChannelInterceptor {

	override
	void afterMessageHandled(
			MessageBase msg, MessageChannel ch, MessageHandler handler, Exception ex) {

		Runnable task = cast(Runnable) msg.getHeaders().get(OrderedMessageSender.COMPLETION_TASK_HEADER);
		if (task !is null) {
			task.run();
		}
	}
}