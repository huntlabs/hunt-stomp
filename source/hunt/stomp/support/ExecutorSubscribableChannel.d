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

module hunt.stomp.support.ExecutorSubscribableChannel;

import hunt.stomp.support.AbstractSubscribableChannel;
import hunt.stomp.support.ChannelInterceptor;
import hunt.stomp.support.ExecutorChannelInterceptor;

import hunt.stomp.Message;
import hunt.stomp.MessagingException;
import hunt.stomp.MessageChannel;

import hunt.collection.ArrayList;
import hunt.collection.List;
import hunt.Exceptions;
import hunt.util.Common;
import hunt.logging;

import std.conv;

// import hunt.concurrent.Executor;

/**
 * A {@link SubscribableChannel} that sends messages to each of its subscribers.
 *
 * @author Phillip Webb
 * @author Rossen Stoyanchev
 * @since 4.0
 */
class ExecutorSubscribableChannel : AbstractSubscribableChannel {

	private Executor executor;

	// private List!(ExecutorChannelInterceptor) executorInterceptors = new ArrayList<>(4);


	/**
	 * Create a new {@link ExecutorSubscribableChannel} instance
	 * where messages will be sent in the callers thread.
	 */
	this() {
		this(null);
	}

	/**
	 * Create a new {@link ExecutorSubscribableChannel} instance
	 * where messages will be sent via the specified executor.
	 * @param executor the executor used to send the message,
	 * or {@code null} to execute in the callers thread.
	 */
	this(Executor executor) {
		this.executor = executor;
	}
	
	Executor getExecutor() {
		return this.executor;
	}

	override
	void setInterceptors(ChannelInterceptor[] interceptors) {
		super.setInterceptors(interceptors);
		// this.executorInterceptors.clear();
		// interceptors.forEach(this::updateExecutorInterceptorsFor);
		foreach(ChannelInterceptor c; interceptors) {
			this.updateExecutorInterceptorsFor(c);
		}
	}

	override
	void addInterceptor(ChannelInterceptor interceptor) {
		super.addInterceptor(interceptor);
		updateExecutorInterceptorsFor(interceptor);
	}

	override
	void addInterceptor(int index, ChannelInterceptor interceptor) {
		super.addInterceptor(index, interceptor);
		updateExecutorInterceptorsFor(interceptor);
	}

	private void updateExecutorInterceptorsFor(ChannelInterceptor interceptor) {
		auto ec = cast(ExecutorChannelInterceptor) interceptor;
		if (ec !is null) {
			// this.executorInterceptors.add(ec);
			implementationMissing(false);
		}
	}


	override
	bool sendInternal(MessageBase message, long timeout) {
		version(HUNT_DEBUG) {
			trace("sending message: ", message.to!string());
		}
		foreach (MessageHandler handler ; getSubscribers()) {
			SendTask sendTask = new SendTask(message, handler);
			if (this.executor is null) {
				sendTask.run();
			} else {
				this.executor.execute(sendTask);
			}
		}
		return true;
	}


	/**
	 * Invoke a MessageHandler with ExecutorChannelInterceptors.
	 */
	private class SendTask : MessageHandlingRunnable {

		private MessageBase inputMessage;

		private MessageHandler messageHandler;

		private int interceptorIndex = -1;

		this(MessageBase message, MessageHandler handler) {
			version(HUNT_DEBUG) {
				tracef("creating SendTask for Message: %s, with handler: %s", 
					typeid(cast(Object)message), typeid(cast(Object)handler));
			}
			this.inputMessage = message;
			this.messageHandler = handler;
		}

		override
		MessageBase getMessage() {
			return this.inputMessage;
		}

		override
		MessageHandler getMessageHandler() {
			return this.messageHandler;
		}

		override
		void run() {
			MessageBase message = this.inputMessage;
			try {
				message = applyBeforeHandle(message);
				if (message is null)
					return;
				this.messageHandler.handleMessage(message);
				triggerAfterMessageHandled(message, null);
			}
			catch (Exception ex) {
				triggerAfterMessageHandled(message, ex);
				auto e = cast(MessagingException) ex;
				if (e !is null) {
					throw e;
				}
				string description = "Failed to handle " ~ message.to!string() ~ 
					" to " ~ this.toString() ~ " in " ~ this.messageHandler.to!string();
				throw new MessageDeliveryException(message, description, ex);
			}
			catch (Throwable err) {
				string description = "Failed to handle " ~ message.to!string() ~ 
					" to " ~ this.toString() ~ " in " ~ this.messageHandler.to!string();
				MessageDeliveryException ex2 = new MessageDeliveryException(message, description, err);
				triggerAfterMessageHandled(message, ex2);
				throw ex2;
			}
		}

		
		private MessageBase applyBeforeHandle(MessageBase message) {
			MessageBase messageToUse = message;
			// TODO: Tasks pending completion -@zxp at 11/13/2018, 2:17:10 PM
			// 
			// implementationMissing(false);
			// foreach (ExecutorChannelInterceptor interceptor ; executorInterceptors) {
			// 	messageToUse = interceptor.beforeHandle(messageToUse, ExecutorSubscribableChannel.this, this.messageHandler);
			// 	if (messageToUse is null) {
			// 		string name = interceptor.TypeUtils.getSimpleName(typeid(this));
			// 		version(HUNT_DEBUG) {
			// 			trace(name ~ " returned null from beforeHandle, i.e. precluding the send.");
			// 		}
			// 		triggerAfterMessageHandled(message, null);
			// 		return null;
			// 	}
			// 	this.interceptorIndex++;
			// }
			return messageToUse;
		}

		private void triggerAfterMessageHandled(MessageBase message, Exception ex) {
			// TODO: Tasks pending completion -@zxp at 11/13/2018, 2:17:31 PM
			// 
			// implementationMissing(false);
			for (int i = this.interceptorIndex; i >= 0; i--) {
				// ExecutorChannelInterceptor interceptor = executorInterceptors.get(i);
				// try {
				// 	interceptor.afterMessageHandled(message, this.outer, this.messageHandler, ex);
				// }
				// catch (Throwable ex2) {
				// 	errorf("Exception from afterMessageHandled in " ~ interceptor.to!string(), ex2);
				// }
			}
		}
	}

}
