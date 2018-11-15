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

module hunt.stomp.simp.annotation.SubscriptionMethodReturnValueHandler;

// import hunt.logging;

// import hunt.framework.core.MethodParameter;

// import hunt.stomp.Message;
// import hunt.stomp.MessageHeaders;
// import hunt.stomp.core.MessageSendingOperations;
// import hunt.stomp.handler.annotation.SendTo;
// import hunt.stomp.handler.invocation.HandlerMethodReturnValueHandler;
// 
// import hunt.stomp.simp.SimpMessageHeaderAccessor;
// import hunt.stomp.simp.SimpMessageType;
// import hunt.stomp.simp.SimpMessagingTemplate;
// import hunt.stomp.simp.annotation.SendToUser;
// import hunt.stomp.simp.annotation.SubscribeMapping;
// 


// /**
//  * {@code HandlerMethodReturnValueHandler} for replying directly to a
//  * subscription. It is supported on methods annotated with
//  * {@link hunt.stomp.simp.annotation.SubscribeMapping
//  * SubscribeMapping} such that the return value is treated as a response to be
//  * sent directly back on the session. This allows a client to implement
//  * a request-response pattern and use it for example to obtain some data upon
//  * initialization.
//  *
//  * <p>The value returned from the method is converted and turned into a
//  * {@link Message} that is then enriched with the sessionId, subscriptionId, and
//  * destination of the input message.
//  *
//  * <p><strong>Note:</strong> this default behavior for interpreting the return
//  * value from an {@code @SubscribeMapping} method can be overridden through use
//  * of the {@link SendTo} or {@link SendToUser} annotations in which case a
//  * message is prepared and sent to the broker instead.
//  *
//  * @author Rossen Stoyanchev
//  * @author Sebastien Deleuze
//  * @since 4.0
//  */
// class SubscriptionMethodReturnValueHandler : HandlerMethodReturnValueHandler {




// 	private final MessageSendingOperations!(string) messagingTemplate;

	
// 	private MessageHeaderInitializer headerInitializer;


// 	/**
// 	 * Construct a new SubscriptionMethodReturnValueHandler.
// 	 * @param template a messaging template to send messages to,
// 	 * most likely the "clientOutboundChannel" (must not be {@code null})
// 	 */
// 	this(MessageSendingOperations!(string) template) {
// 		assert(template, "messagingTemplate must not be null");
// 		this.messagingTemplate = template;
// 	}


// 	/**
// 	 * Configure a {@link MessageHeaderInitializer} to apply to the headers of all
// 	 * messages sent to the client outbound channel.
// 	 * <p>By default this property is not set.
// 	 */
// 	void setHeaderInitializer(MessageHeaderInitializer headerInitializer) {
// 		this.headerInitializer = headerInitializer;
// 	}

// 	/**
// 	 * Return the configured header initializer.
// 	 */
	
// 	MessageHeaderInitializer getHeaderInitializer() {
// 		return this.headerInitializer;
// 	}


// 	override
// 	bool supportsReturnType(MethodParameter returnType) {
// 		return (returnType.hasMethodAnnotation(SubscribeMapping.class) &&
// 				!returnType.hasMethodAnnotation(SendTo.class) &&
// 				!returnType.hasMethodAnnotation(SendToUser.class));
// 	}

// 	override
// 	void handleReturnValue(Object returnValue, MethodParameter returnType, MessageBase message)
// 			throws Exception {

// 		if (returnValue is null) {
// 			return;
// 		}

// 		MessageHeaders headers = message.getHeaders();
// 		string sessionId = SimpMessageHeaderAccessor.getSessionId(headers);
// 		string subscriptionId = SimpMessageHeaderAccessor.getSubscriptionId(headers);
// 		string destination = SimpMessageHeaderAccessor.getDestination(headers);

// 		if (subscriptionId is null) {
// 			throw new IllegalStateException("No simpSubscriptionId in " ~ message +
// 					" returned by: " ~ returnType.getMethod());
// 		}
// 		if (destination is null) {
// 			throw new IllegalStateException("No simpDestination in " ~ message +
// 					" returned by: " ~ returnType.getMethod());
// 		}

// 		version(HUNT_DEBUG) {
// 			trace("Reply to @SubscribeMapping: " ~ returnValue);
// 		}
// 		MessageHeaders headersToSend = createHeaders(sessionId, subscriptionId, returnType);
// 		this.messagingTemplate.convertAndSend(destination, returnValue, headersToSend);
// 	}

// 	private MessageHeaders createHeaders(string sessionId, string subscriptionId, MethodParameter returnType) {
// 		SimpMessageHeaderAccessor accessor = SimpMessageHeaderAccessor.create(SimpMessageType.MESSAGE);
// 		if (getHeaderInitializer() !is null) {
// 			getHeaderInitializer().initHeaders(accessor);
// 		}
// 		if (sessionId !is null) {
// 			accessor.setSessionId(sessionId);
// 		}
// 		accessor.setSubscriptionId(subscriptionId);
// 		accessor.setHeader(SimpMessagingTemplate.CONVERSION_HINT_HEADER, returnType);
// 		accessor.setLeaveMutable(true);
// 		return accessor.getMessageHeaders();
// 	}

// }
