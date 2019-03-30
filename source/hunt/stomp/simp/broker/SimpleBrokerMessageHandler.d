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

module hunt.stomp.simp.broker.SimpleBrokerMessageHandler;

import hunt.stomp.simp.broker.AbstractBrokerMessageHandler;
import hunt.stomp.simp.broker.DefaultSubscriptionRegistry;
import hunt.stomp.simp.broker.SubscriptionRegistry;

import hunt.stomp.Message;
import hunt.stomp.MessageChannel;
import hunt.stomp.MessageHeaders;
import hunt.stomp.simp.SimpMessageHeaderAccessor;
import hunt.stomp.simp.SimpMessageType;
import hunt.stomp.support.GenericMessage;
import hunt.stomp.support.MessageBuilder;
import hunt.stomp.support.MessageHeaderAccessor;

// import hunt.framework.task.TaskScheduler;

import hunt.collection;
import hunt.util.DateTime;
import hunt.util.Common;
import hunt.Exceptions;
import hunt.logging;
import hunt.text.PathMatcher;

// dfmt off
version(Have_hunt_security) {
    import hunt.security.Principal;
}
// dfmt on

import std.algorithm;
import std.conv;

/**
 * A "simple" message broker that recognizes the message types defined in
 * {@link SimpMessageType}, keeps track of subscriptions with the help of a
 * {@link SubscriptionRegistry} and sends messages to subscribers.
 *
 * @author Rossen Stoyanchev
 * @author Juergen Hoeller
 * @since 4.0
 */
class SimpleBrokerMessageHandler : AbstractBrokerMessageHandler {

	private enum byte[] EMPTY_PAYLOAD = [];

	private PathMatcher pathMatcher;
	
	private int cacheLimit;
	
	private string selectorHeaderName = "selector";
	
	// private TaskScheduler taskScheduler;
	
	private long[] heartbeatValue;
	
	private MessageHeaderInitializer headerInitializer;

	private SubscriptionRegistry subscriptionRegistry;

	private Map!(string, SessionInfo) sessions;

	
	// private ScheduledFuture<?> heartbeatFuture;


	/**
	 * Create a SimpleBrokerMessageHandler instance with the given message channels
	 * and destination prefixes.
	 * @param clientInboundChannel the channel for receiving messages from clients (e.g. WebSocket clients)
	 * @param clientOutboundChannel the channel for sending messages to clients (e.g. WebSocket clients)
	 * @param brokerChannel the channel for the application to send messages to the broker
	 * @param destinationPrefixes prefixes to use to filter out messages
	 */
	this(SubscribableChannel clientInboundChannel, MessageChannel clientOutboundChannel,
			SubscribableChannel brokerChannel, string[] destinationPrefixes) {

		super(clientInboundChannel, clientOutboundChannel, brokerChannel, destinationPrefixes);
		sessions = new HashMap!(string, SessionInfo)();
		this.subscriptionRegistry = new DefaultSubscriptionRegistry();
	}


	/**
	 * Configure a custom SubscriptionRegistry to use for storing subscriptions.
	 * <p><strong>Note</strong> that when a custom PathMatcher is configured via
	 * {@link #setPathMatcher}, if the custom registry is not an instance of
	 * {@link DefaultSubscriptionRegistry}, the provided PathMatcher is not used
	 * and must be configured directly on the custom registry.
	 */
	void setSubscriptionRegistry(SubscriptionRegistry subscriptionRegistry) {
		assert(subscriptionRegistry, "SubscriptionRegistry must not be null");
		this.subscriptionRegistry = subscriptionRegistry;
		initPathMatcherToUse();
		initCacheLimitToUse();
		initSelectorHeaderNameToUse();
	}

	SubscriptionRegistry getSubscriptionRegistry() {
		return this.subscriptionRegistry;
	}

	/**
	 * When configured, the given PathMatcher is passed down to the underlying
	 * SubscriptionRegistry to use for matching destination to subscriptions.
	 * <p>Default is a standard {@link hunt.framework.util.AntPathMatcher}.
	 * @since 4.1
	 * @see #setSubscriptionRegistry
	 * @see DefaultSubscriptionRegistry#setPathMatcher
	 * @see hunt.framework.util.AntPathMatcher
	 */
	void setPathMatcher(PathMatcher pathMatcher) {
		this.pathMatcher = pathMatcher;
		initPathMatcherToUse();
	}

	private void initPathMatcherToUse() {
		auto s = cast(DefaultSubscriptionRegistry) this.subscriptionRegistry;
		if (this.pathMatcher !is null && s !is null) {
			s.setPathMatcher(this.pathMatcher);
		}
	}

	/**
	 * When configured, the specified cache limit is passed down to the
	 * underlying SubscriptionRegistry, overriding any default there.
	 * <p>With a standard {@link DefaultSubscriptionRegistry}, the default
	 * cache limit is 1024.
	 * @since 4.3.2
	 * @see #setSubscriptionRegistry
	 * @see DefaultSubscriptionRegistry#setCacheLimit
	 * @see DefaultSubscriptionRegistry#DEFAULT_CACHE_LIMIT
	 */
	void setCacheLimit(int cacheLimit) {
		this.cacheLimit = cacheLimit;
		initCacheLimitToUse();
	}

	private void initCacheLimitToUse() {
		auto s = cast(DefaultSubscriptionRegistry) this.subscriptionRegistry;
		if (s !is null) {
			s.setCacheLimit(this.cacheLimit);
		}
	}

	/**
	 * Configure the name of a header that a subscription message can have for
	 * the purpose of filtering messages matched to the subscription. The header
	 * value is expected to be a Spring EL  expression to be applied to
	 * the headers of messages matched to the subscription.
	 * <p>For example:
	 * <pre>
	 * headers.foo == 'bar'
	 * </pre>
	 * <p>By default this is set to "selector". You can set it to a different
	 * name, or to {@code null} to turn off support for a selector header.
	 * @param selectorHeaderName the name to use for a selector header
	 * @since 4.3.17
	 * @see #setSubscriptionRegistry
	 * @see DefaultSubscriptionRegistry#setSelectorHeaderName(string)
	 */
	void setSelectorHeaderName(string selectorHeaderName) {
		this.selectorHeaderName = selectorHeaderName;
		initSelectorHeaderNameToUse();
	}

	private void initSelectorHeaderNameToUse() {
		auto s = cast(DefaultSubscriptionRegistry) this.subscriptionRegistry;
		if (s !is null) {
			s.setSelectorHeaderName(this.selectorHeaderName);
		}
	}

	/**
	 * Configure the {@link hunt.framework.scheduling.TaskScheduler} to
	 * use for providing heartbeat support. Setting this property also sets the
	 * {@link #setHeartbeatValue heartbeatValue} to "10000, 10000".
	 * <p>By default this is not set.
	 * @since 4.2
	 */
	// void setTaskScheduler(TaskScheduler taskScheduler) {
	// 	this.taskScheduler = taskScheduler;
	// 	if (taskScheduler !is null && this.heartbeatValue is null) {
	// 		this.heartbeatValue = [10000, 10000];
	// 	}
	// }

	/**
	 * Return the configured TaskScheduler.
	 * @since 4.2
	 */
	
	// TaskScheduler getTaskScheduler() {
	// 	return this.taskScheduler;
	// }

	/**
	 * Configure the value for the heart-beat settings. The first number
	 * represents how often the server will write or send a heartbeat.
	 * The second is how often the client should write. 0 means no heartbeats.
	 * <p>By default this is set to "0, 0" unless the {@link #setTaskScheduler
	 * taskScheduler} in which case the default becomes "10000,10000"
	 * (in milliseconds).
	 * @since 4.2
	 */
	void setHeartbeatValue(long[] heartbeat) {
		if (heartbeat !is null && (heartbeat.length != 2 || heartbeat[0] < 0 || heartbeat[1] < 0)) {
			throw new IllegalArgumentException("Invalid heart-beat: " ~ heartbeat.to!string());
		}
		this.heartbeatValue = heartbeat;
	}

	/**
	 * The configured value for the heart-beat settings.
	 * @since 4.2
	 */
	
	long[] getHeartbeatValue() {
		return this.heartbeatValue;
	}

	/**
	 * Configure a {@link MessageHeaderInitializer} to apply to the headers
	 * of all messages sent to the client outbound channel.
	 * <p>By default this property is not set.
	 * @since 4.1
	 */
	void setHeaderInitializer(MessageHeaderInitializer headerInitializer) {
		this.headerInitializer = headerInitializer;
	}

	/**
	 * Return the configured header initializer.
	 * @since 4.1
	 */
	
	MessageHeaderInitializer getHeaderInitializer() {
		return this.headerInitializer;
	}


	override
	void startInternal() {
		publishBrokerAvailableEvent();
		// implementationMissing(false);
		// TODO: Tasks pending completion -@zxp at 11/13/2018, 3:18:33 PM
		// 
		// if (this.taskScheduler !is null) {
		// 	long interval = initHeartbeatTaskDelay();
		// 	if (interval > 0) {
		// 		// this.heartbeatFuture = this.taskScheduler.scheduleWithFixedDelay(new HeartbeatTask(), interval);
		// 		implementationMissing(false);
		// 	}
		// }
		// else {
		// 	assert(getHeartbeatValue() is null ||
		// 			(getHeartbeatValue()[0] == 0 && getHeartbeatValue()[1] == 0),
		// 			"Heartbeat values configured but no TaskScheduler provided");
		// }
	}

	private long initHeartbeatTaskDelay() {
		if (getHeartbeatValue() is null) {
			return 0;
		}
		else if (getHeartbeatValue()[0] > 0 && getHeartbeatValue()[1] > 0) {
			return min(getHeartbeatValue()[0], getHeartbeatValue()[1]);
		}
		else {
			return (getHeartbeatValue()[0] > 0 ? getHeartbeatValue()[0] : getHeartbeatValue()[1]);
		}
	}

	override
	void stopInternal() {
		publishBrokerUnavailableEvent();
		// if (this.heartbeatFuture !is null) {
		// 	this.heartbeatFuture.cancel(true);
		// }
	}

	override
	protected void handleMessageInternal(MessageBase message) {
		MessageHeaders headers = message.getHeaders();
		version(HUNT_DEBUG) {
			trace(headers.toString());
		}

		SimpMessageType messageType = SimpMessageHeaderAccessor.getMessageType(headers);
		string destination = SimpMessageHeaderAccessor.getDestination(headers);
		string sessionId = SimpMessageHeaderAccessor.getSessionId(headers);

		updateSessionReadTime(sessionId);

		if (!checkDestinationPrefix(destination)) {
			return;
		}

		if (SimpMessageType.MESSAGE == messageType) {
			logMessage(message);
			sendMessageToSubscribers(destination, message);
		}
		else if (SimpMessageType.CONNECT == messageType) {
			logMessage(message);
			if (sessionId !is null) {
				long[] heartbeatIn = SimpMessageHeaderAccessor.getHeartbeat(headers);
				long[] heartbeatOut = getHeartbeatValue();
				// TODO: Tasks pending completion -@zxp at 10/31/2018, 4:39:26 PM
				// 
				version(Have_hunt_security) {
					Principal user = null; // SimpMessageHeaderAccessor.getUser(headers);
				}
			
				MessageChannel outChannel = getClientOutboundChannelForSession(sessionId);

				version(Have_hunt_security) {
					this.sessions.put(sessionId, new SessionInfo(sessionId, user, outChannel, heartbeatIn, heartbeatOut));
				} else {
					this.sessions.put(sessionId, new SessionInfo(sessionId, outChannel, heartbeatIn, heartbeatOut));
				}
				
				SimpMessageHeaderAccessor connectAck = SimpMessageHeaderAccessor.create(SimpMessageType.CONNECT_ACK);
				initHeaders(connectAck);
				connectAck.setSessionId(sessionId);
				// if (user !is null) {
				// 	connectAck.setUser(user);
				// }
				connectAck.setHeader(SimpMessageHeaderAccessor.CONNECT_MESSAGE_HEADER, message);
				connectAck.setHeader(SimpMessageHeaderAccessor.HEART_BEAT_HEADER, heartbeatOut);
				MessageBase messageOut = MessageHelper.createMessage(EMPTY_PAYLOAD, connectAck.getMessageHeaders());
				info("responding ..........");
				getClientOutboundChannel().send(messageOut);
				info("responding ..........done");
			} else {
				warning("sessionId is null");
			}
		}
		else if (SimpMessageType.DISCONNECT == messageType) {
			logMessage(message);
			if (sessionId !is null) {
				// Principal user = SimpMessageHeaderAccessor.getUser(headers);

				version(Have_hunt_security) {
					handleDisconnect(sessionId, null, message);
				} else {
					handleDisconnect(sessionId, message);
				}
			}
		}
		else if (SimpMessageType.SUBSCRIBE == messageType) {
			logMessage(message);
			this.subscriptionRegistry.registerSubscription(message);
		}
		else if (SimpMessageType.UNSUBSCRIBE == messageType) {
			logMessage(message);
			this.subscriptionRegistry.unregisterSubscription(message);
		}
	}

	private void updateSessionReadTime(string sessionId) {
		if (sessionId !is null) {
			SessionInfo info = this.sessions.get(sessionId);
			if (info !is null) {
				info.setLastReadTime(DateTimeHelper.currentTimeMillis);
			}
		}
	}

	private void logMessage(MessageBase message) {
		version(HUNT_DEBUG) {
			SimpMessageHeaderAccessor accessor = MessageHeaderAccessor.getAccessor!SimpMessageHeaderAccessor(message);
			accessor = (accessor !is null ? accessor : SimpMessageHeaderAccessor.wrap(message));
			import hunt.stomp.support.GenericMessage;
			import hunt.Nullable;
			GenericMessage!(byte[]) gm = cast(GenericMessage!(byte[]))message;
			if(gm is null) 
				trace("Processing " ~ typeid(cast(Object)message).name);
			else
				trace("Processing " ~ accessor.getShortLogMessage(new Nullable!(byte[])(gm.getPayload())));
		}
	}

	private void initHeaders(SimpMessageHeaderAccessor accessor) {
		if (getHeaderInitializer() !is null) {
			getHeaderInitializer().initHeaders(accessor);
		}
	}

	private void handleDisconnect(string sessionId, MessageBase origMessage) {
		this.sessions.remove(sessionId);
		this.subscriptionRegistry.unregisterAllSubscriptions(sessionId);
		SimpMessageHeaderAccessor accessor = SimpMessageHeaderAccessor.create(SimpMessageType.DISCONNECT_ACK);
		accessor.setSessionId(sessionId);
		// if (user !is null) {
		// 	accessor.setUser(user);
		// }
		if (origMessage !is null) {
			accessor.setHeader(SimpMessageHeaderAccessor.DISCONNECT_MESSAGE_HEADER, origMessage);
		}
		initHeaders(accessor);
		MessageBase message = MessageHelper.createMessage(EMPTY_PAYLOAD, accessor.getMessageHeaders());
		getClientOutboundChannel().send(message);
	}

	protected void sendMessageToSubscribers(string destination, MessageBase message) {
		MultiValueMap!(string,string) subscriptions = this.subscriptionRegistry.findSubscriptions(message);
		version(HUNT_DEBUG) {
			if (!subscriptions.isEmpty()) {
				trace("Broadcasting to " ~ subscriptions.size().to!string() ~ " sessions.");
			}
		}
		long now = DateTimeHelper.currentTimeMillis();
		foreach(string sessionId, List!string subscriptionIds; subscriptions) {
			foreach (string subscriptionId ; subscriptionIds) {
				SimpMessageHeaderAccessor headerAccessor = SimpMessageHeaderAccessor.create(SimpMessageType.MESSAGE);
				initHeaders(headerAccessor);
				headerAccessor.setSessionId(sessionId);
				headerAccessor.setSubscriptionId(subscriptionId);
				headerAccessor.copyHeadersIfAbsent(message.getHeaders());
				headerAccessor.setLeaveMutable(true);
				// warning(message.payloadType);
				auto gm = cast(GenericMessage!(string))message;
				if(gm is null) {
					warning("Can't cast message: %s", typeid(message));
					continue;
				}
				string payload = gm.getPayload();
				MessageBase reply = MessageHelper.createMessage(cast(byte[])payload, headerAccessor.getMessageHeaders());
				SessionInfo info = this.sessions.get(sessionId);
				if (info !is null) {
					try {
						info.getClientOutboundChannel().send(reply);
					}
					catch (Throwable ex) {
						errorf("Failed to send " ~ message.to!string()  ~ ": \n%s", ex.msg);
					}
					finally {
						info.setLastWriteTime(now);
					}
				}
			}
		}
	}


	int opCmp(MessageHandler o) {
		implementationMissing(false);
		return 0;
	}


	override
	string toString() {
		return "SimpleBrokerMessageHandler [" ~ this.subscriptionRegistry.to!string() ~ "]";
	}


	private class HeartbeatTask : Runnable {

		override
		void run() {
			long now =DateTimeHelper.currentTimeMillis();
			foreach (SessionInfo info ; sessions.values()) {
				if (info.getReadInterval() > 0 && (now - info.getLastReadTime()) > info.getReadInterval()) {

					version(Have_hunt_security) {
						handleDisconnect(info.getSessionId(), null, null); // info.getUser()
					} else {
						handleDisconnect(info.getSessionId(), null); // info.getUser()
					}

				}
				if (info.getWriteInterval() > 0 && (now - info.getLastWriteTime()) > info.getWriteInterval()) {
					SimpMessageHeaderAccessor accessor = SimpMessageHeaderAccessor.create(SimpMessageType.HEARTBEAT);
					accessor.setSessionId(info.getSessionId());
					// TODO: Tasks pending completion -@zxp at 10/31/2018, 4:39:51 PM
					// 
					// Principal user = info.getUser();
					// if (user !is null) {
					// 	accessor.setUser(user);
					// }
					initHeaders(accessor);
					accessor.setLeaveMutable(true);
					MessageHeaders headers = accessor.getMessageHeaders();
					info.getClientOutboundChannel().send(MessageHelper.createMessage(EMPTY_PAYLOAD, headers));
				}
			}
		}
	}

}



private static class SessionInfo {

	/* STOMP spec: receiver SHOULD take into account an error margin */
	private enum long HEARTBEAT_MULTIPLIER = 3;

	private string sessionId;

	// private Principal user;

	private MessageChannel clientOutboundChannel;

	private long readInterval;

	private long writeInterval;

	private long lastReadTime;

	private long lastWriteTime;

	this(string sessionId, MessageChannel outboundChannel,
			long[] clientHeartbeat, long[] serverHeartbeat) { // Principal user, 

		this.sessionId = sessionId;
		// this.user = user;
		this.clientOutboundChannel = outboundChannel;
		if (clientHeartbeat !is null && serverHeartbeat !is null) {
			this.readInterval = (clientHeartbeat[0] > 0 && serverHeartbeat[1] > 0 ?
					max(clientHeartbeat[0], serverHeartbeat[1]) * HEARTBEAT_MULTIPLIER : 0);
			this.writeInterval = (clientHeartbeat[1] > 0 && serverHeartbeat[0] > 0 ?
					max(clientHeartbeat[1], serverHeartbeat[0]) : 0);
		}
		else {
			this.readInterval = 0;
			this.writeInterval = 0;
		}
		this.lastReadTime = this.lastWriteTime =DateTimeHelper.currentTimeMillis();
	}

	string getSessionId() {
		return this.sessionId;
	}

	
	// Principal getUser() {
	// 	return this.user;
	// }

	MessageChannel getClientOutboundChannel() {
		return this.clientOutboundChannel;
	}

	long getReadInterval() {
		return this.readInterval;
	}

	long getWriteInterval() {
		return this.writeInterval;
	}

	long getLastReadTime() {
		return this.lastReadTime;
	}

	void setLastReadTime(long lastReadTime) {
		this.lastReadTime = lastReadTime;
	}

	long getLastWriteTime() {
		return this.lastWriteTime;
	}

	void setLastWriteTime(long lastWriteTime) {
		this.lastWriteTime = lastWriteTime;
	}
}

