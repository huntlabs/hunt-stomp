/*
 * Copyright 2002-2017 the original author or authors.
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

module hunt.stomp.simp.SimpMessageHeaderAccessor;

import hunt.stomp.simp.SimpMessageType;

import hunt.stomp.Message;
import hunt.stomp.support.IdTimestampMessageHeaderInitializer;
import hunt.stomp.support.MessageHeaderAccessor;
import hunt.stomp.support.NativeMessageHeaderAccessor;

import hunt.collection.List;
import hunt.collection.Map;
import hunt.Nullable;
import hunt.text.Common;
import hunt.text.StringBuilder;

version(Have_hunt_security) {
    import hunt.security.Principal;
}

import std.conv;

/**
 * A base class for working with message headers in simple messaging protocols that
 * support basic messaging patterns. Provides uniform access to specific values common
 * across protocols such as a destination, message type (e.g. publish, subscribe, etc),
 * session id, and others.
 *
 * <p>Use one of the static factory method in this class, then call getters and setters,
 * and at the end if necessary call {@link #toMap()} to obtain the updated headers.
 *
 * @author Rossen Stoyanchev
 * @since 4.0
 */
class SimpMessageHeaderAccessor : NativeMessageHeaderAccessor {

	private __gshared IdTimestampMessageHeaderInitializer headerInitializer;

	shared static this() {
		headerInitializer = new IdTimestampMessageHeaderInitializer();
		headerInitializer.setDisableIdGeneration();
		headerInitializer.setEnableTimestamp(false);
	}

	// SIMP header names

	enum string DESTINATION_HEADER = "simpDestination";

	enum string MESSAGE_TYPE_HEADER = "simpMessageType";

	enum string SESSION_ID_HEADER = "simpSessionId";

	enum string SESSION_ATTRIBUTES = "simpSessionAttributes";

	enum string SUBSCRIPTION_ID_HEADER = "simpSubscriptionId";

	enum string USER_HEADER = "simpUser";

	enum string CONNECT_MESSAGE_HEADER = "simpConnectMessage";

	enum string DISCONNECT_MESSAGE_HEADER = "simpDisconnectMessage";

	enum string HEART_BEAT_HEADER = "simpHeartbeat";


	/**
	 * A header for internal use with "user" destinations where we need to
	 * restore the destination prior to sending messages to clients.
	 */
	enum string ORIGINAL_DESTINATION = "simpOrigDestination";

	/**
	 * A header that indicates to the broker that the sender will ignore errors.
	 * The header is simply checked for presence or absence.
	 */
	enum string IGNORE_ERROR = "simpIgnoreError";


	/**
	 * A constructor for creating new message headers.
	 * This constructor is protected. See factory methods in this and sub-classes.
	 */
	protected this(SimpMessageType messageType,
			Map!(string, List!string) externalSourceHeaders) {

		super(externalSourceHeaders);
		setHeader(MESSAGE_TYPE_HEADER, new Nullable!SimpMessageType(messageType));
		headerInitializer.initHeaders(this);
	}

	/**
	 * A constructor for accessing and modifying existing message headers. This
	 * constructor is protected. See factory methods in this and sub-classes.
	 */
	protected this(MessageBase message) {
		super(message);
		headerInitializer.initHeaders(this);
	}

	override
	protected MessageHeaderAccessor createAccessor(MessageBase message) {
		return wrap(message);
	}

	void setMessageTypeIfNotSet(SimpMessageType messageType) {
		if (getMessageType() is null) {
			setHeader(MESSAGE_TYPE_HEADER, new Nullable!SimpMessageType(messageType));
		}
	}

	Nullable!SimpMessageType getMessageType() {
		return cast(Nullable!SimpMessageType) getHeader(MESSAGE_TYPE_HEADER);
	}

	void setDestination(string destination) {
		setHeader(DESTINATION_HEADER, destination);
	}
	
	string getDestination() {
		return getHeaderAs!(string)(DESTINATION_HEADER);
	}

	void setSubscriptionId(string subscriptionId) {
		setHeader(SUBSCRIPTION_ID_HEADER, subscriptionId);
	}

	
	string getSubscriptionId() {
		return getHeaderAs!(string)(SUBSCRIPTION_ID_HEADER);
	}

	void setSessionId(int sessionId) {
		setHeader(SESSION_ID_HEADER, sessionId.to!string());
	}

	void setSessionId(string sessionId) {
		setHeader(SESSION_ID_HEADER, sessionId);
	}

	/**
	 * Return the id of the current session.
	 */
	
	string getSessionId() {
		return getHeaderAs!(string)(SESSION_ID_HEADER);
	}

	/**
	 * A static alternative for access to the session attributes header.
	 */
	void setSessionAttributes(Map!(string, Object) attributes) {
		setHeader(SESSION_ATTRIBUTES, attributes);
	}

	/**
	 * Return the attributes associated with the current session.
	 */
	Map!(string, Object) getSessionAttributes() {
		return cast(Map!(string, Object)) getHeader(SESSION_ATTRIBUTES);
	}

	// void setUser(Principal principal) {
	// 	setHeader(USER_HEADER, principal);
	// }

	/**
	 * Return the user associated with the current session.
	 */
	
	// Principal getUser() {
	// 	return (Principal) getHeader(USER_HEADER);
	// }

	override
	string getShortLogMessage(Object payload) {
		if (getMessageType() is null) {
			return super.getDetailedLogMessage(payload);
		}
		StringBuilder sb = getBaseLogMessage();
		Map!(string, Object) map = getSessionAttributes();
		if (map !is null  && !map.isEmpty()) {
			sb.append(" attributes[").append(map.size()).append("]");
		}
		sb.append(getShortPayloadLogMessage(payload));
		return sb.toString();
	}

	
	override
	string getDetailedLogMessage(Object payload) {
		if (getMessageType() is null) {
			return super.getDetailedLogMessage(payload);
		}
		StringBuilder sb = getBaseLogMessage();
		auto map = getSessionAttributes();
		if (map !is null && !map.isEmpty()) {
			sb.append(" attributes=").append(map.toString());
		}

		auto m = cast(Map!(string, List!string)) getHeader(NATIVE_HEADERS);
		if (m !is null && !m.isEmpty()) {
			sb.append(" nativeHeaders=").append(m.toString());
		}
		sb.append(getDetailedPayloadLogMessage(payload));
		return sb.toString();
	}

	private StringBuilder getBaseLogMessage() {
		StringBuilder sb = new StringBuilder();
		auto messageType = getMessageType();
		sb.append(messageType !is null ? messageType.to!string() : to!string(SimpMessageType.OTHER));
		string destination = getDestination();
		if (destination !is null) {
			sb.append(" destination=").append(destination);
		}
		string subscriptionId = getSubscriptionId();
		if (subscriptionId !is null) {
			sb.append(" subscriptionId=").append(subscriptionId);
		}
		sb.append(" session=").append(getSessionId());

		// Principal user = getUser();
		// if (user !is null) {
		// 	sb.append(" user=").append(user.getName());
		// }

		return sb;
	}


	// Static factory methods and accessors

	/**
	 * Create an instance with
	 * {@link hunt.stomp.simp.SimpMessageType} {@code MESSAGE}.
	 */
	static SimpMessageHeaderAccessor create() {
		return new SimpMessageHeaderAccessor(SimpMessageType.MESSAGE, null);
	}

	/**
	 * Create an instance with the given
	 * {@link hunt.stomp.simp.SimpMessageType}.
	 */
	static SimpMessageHeaderAccessor create(SimpMessageType messageType) {
		return new SimpMessageHeaderAccessor(messageType, null);
	}

	/**
	 * Create an instance from the payload and headers of the given Message.
	 */
	static SimpMessageHeaderAccessor wrap(MessageBase message) {
		return new SimpMessageHeaderAccessor(message);
	}
	
	static Nullable!SimpMessageType getMessageType(Map!(string, Object) headers) {
		auto h = cast(Nullable!SimpMessageType)headers.get(MESSAGE_TYPE_HEADER);
		return h;
	}

	
	static string getDestination(Map!(string, Object) headers) {
		auto h = cast(Nullable!string)headers.get(DESTINATION_HEADER);
		if(h is null)
			return null;
		else
			return cast(string) h;
	}

	
	static string getSubscriptionId(Map!(string, Object) headers) {
		auto h = cast(Nullable!string)headers.get(SUBSCRIPTION_ID_HEADER);
		if(h is null)
			return null;
		else
			return cast(string) h;
	}

	
	static string getSessionId(Map!(string, Object) headers) {
		auto h = cast(Nullable!string)headers.get(SESSION_ID_HEADER);
		if(h is null)
			return null;
		else
			return cast(string) h;
	}

	
	static Map!(string, Object) getSessionAttributes(Map!(string, Object) headers) {
		return cast(Map!(string, Object)) headers.get(SESSION_ATTRIBUTES);
	}

	
	// static Principal getUser(Map!(string, Object) headers) {
	// 	return cast(Principal) headers.get(USER_HEADER);
	// }

	
	static long[] getHeartbeat(Map!(string, Object) headers) {
		auto h = cast(Nullable!(long[]))headers.get(HEART_BEAT_HEADER);
		if(h is null)
			return null;
		else
			return cast(long[]) h;
	}

}
