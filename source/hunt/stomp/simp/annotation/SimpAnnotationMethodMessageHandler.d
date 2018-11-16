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

module hunt.stomp.simp.annotation.SimpAnnotationMethodMessageHandler;

import hunt.stomp.simp.annotation.AbstractMethodMessageHandler;

// import hunt.framework.beans.factory.config.ConfigurableBeanFactory;
// import hunt.framework.context.ApplicationContext;
import hunt.util.Lifecycle;
// import hunt.framework.context.ConfigurableApplicationContext;
// import hunt.framework.context.EmbeddedValueResolverAware;
// import hunt.framework.core.annotation.AnnotatedElementUtils;
// import hunt.framework.core.convert.ConversionService;
// import hunt.framework.format.support.DefaultFormattingConversionService;

import hunt.stomp.Message;
import hunt.stomp.MessageChannel;
import hunt.stomp.MessageHeaders;

import hunt.stomp.converter.AbstractMessageConverter;
import hunt.stomp.converter.ByteArrayMessageConverter;
import hunt.stomp.converter.CompositeMessageConverter;
import hunt.stomp.converter.MessageConverter;
import hunt.stomp.converter.StringMessageConverter;
import hunt.stomp.core.AbstractMessageSendingTemplate;
// import hunt.stomp.handler.DestinationPatternsMessageCondition;
// import hunt.stomp.handler.HandlerMethod;
// import hunt.stomp.handler.annotation.MessageMapping;
// import hunt.stomp.handler.annotation.support.AnnotationExceptionHandlerMethodResolver;
// import hunt.stomp.handler.annotation.support.DestinationVariableMethodArgumentResolver;
// import hunt.stomp.handler.annotation.support.HeaderMethodArgumentResolver;
// import hunt.stomp.handler.annotation.support.HeadersMethodArgumentResolver;
// import hunt.stomp.handler.annotation.support.MessageMethodArgumentResolver;
// import hunt.stomp.handler.annotation.support.PayloadArgumentResolver;
// import hunt.stomp.handler.invocation.AbstractExceptionHandlerMethodResolver;
// import hunt.stomp.handler.invocation.AbstractMethodMessageHandler;
// import hunt.stomp.handler.invocation.CompletableFutureReturnValueHandler;
// import hunt.stomp.handler.invocation.HandlerMethodArgumentResolver;
// import hunt.stomp.handler.invocation.HandlerMethodReturnValueHandler;
// import hunt.stomp.handler.invocation.HandlerMethodReturnValueHandlerComposite;
// import hunt.stomp.handler.invocation.ListenableFutureReturnValueHandler;
// import hunt.stomp.handler.invocation.ReactiveReturnValueHandler;
import hunt.stomp.simp.SimpAttributesContextHolder;
// 
import hunt.stomp.simp.SimpMessageHeaderAccessor;
import hunt.stomp.simp.SimpMessageMappingInfo;
import hunt.stomp.simp.SimpMessageSendingOperations;
import hunt.stomp.simp.SimpMessageType;
import hunt.stomp.simp.SimpMessageTypeMessageCondition;
import hunt.stomp.simp.SimpMessagingTemplate;
// import hunt.stomp.simp.annotation.SubscribeMapping;
import hunt.stomp.support.MessageHeaderAccessor;

// import hunt.framework.stereotype.Controller;
// import hunt.framework.util.AntPathMatcher;

// import hunt.framework.util.CollectionUtils;
import hunt.string.PathMatcher;
// import hunt.framework.util.StringValueResolver;
// import hunt.framework.validation.Validator;

import hunt.container;
import hunt.lang.common;
import hunt.lang.exception;
import hunt.logging;

import std.string;

/**
 * A handler for messages delegating to {@link MessageMapping @MessageMapping}
 * and {@link SubscribeMapping @SubscribeMapping} annotated methods.
 *
 * <p>Supports Ant-style path patterns with template variables.
 *
 * @author Rossen Stoyanchev
 * @author Brian Clozel
 * @author Juergen Hoeller
 * @since 4.0
 */
class SimpAnnotationMethodMessageHandler : 
	AbstractMethodMessageHandler!(SimpMessageMappingInfo), SmartLifecycle {
		 // EmbeddedValueResolverAware
	private SubscribableChannel clientInboundChannel;

	private SimpMessageSendingOperations clientMessagingTemplate;

	private SimpMessageSendingOperations brokerTemplate;

	private MessageConverter messageConverter;

	// private ConversionService conversionService = new DefaultFormattingConversionService();

	private PathMatcher pathMatcher;

	private bool slashPathSeparator = true;
	
	// private Validator validator;

	// private StringValueResolver valueResolver;
	
	private MessageHeaderInitializer headerInitializer;

	private bool running = false;

	private Object lifecycleMonitor;


	/**
	 * Create an instance of SimpAnnotationMethodMessageHandler with the given
	 * message channels and broker messaging template.
	 * @param clientInboundChannel the channel for receiving messages from clients (e.g. WebSocket clients)
	 * @param clientOutboundChannel the channel for messages to clients (e.g. WebSocket clients)
	 * @param brokerTemplate a messaging template to send application messages to the broker
	 */
	this(SubscribableChannel clientInboundChannel,
			MessageChannel clientOutboundChannel, SimpMessageSendingOperations brokerTemplate) {

		assert(clientInboundChannel, "clientInboundChannel must not be null");
		assert(clientOutboundChannel, "clientOutboundChannel must not be null");
		// assert(brokerTemplate, "brokerTemplate must not be null");

		pathMatcher = new AntPathMatcher();
		lifecycleMonitor = new Object();
		this.clientInboundChannel = clientInboundChannel;
		this.clientMessagingTemplate = new SimpMessagingTemplate(clientOutboundChannel);
		this.brokerTemplate = brokerTemplate;

		MessageConverter[] converters = [
			new StringMessageConverter(),
			new ByteArrayMessageConverter()
		];
		
		this.messageConverter = new CompositeMessageConverter(converters);
	}


	/**
	 * {@inheritDoc}
	 * <p>Destination prefixes are expected to be slash-separated Strings and
	 * therefore a slash is automatically appended where missing to ensure a
	 * proper prefix-based match (i.e. matching complete segments).
	 * <p>Note however that the remaining portion of a destination after the
	 * prefix may use a different separator (e.g. commonly "." in messaging)
	 * depending on the configured {@code PathMatcher}.
	 */
	override
	void setDestinationPrefixes(string[] prefixes) {
		super.setDestinationPrefixes(appendSlashes(prefixes));
	}

	private static string[] appendSlashes(string[] prefixes) {
		if (prefixes.length == 0) 
			return prefixes;
		string[] result;
		foreach (string prefix ; prefixes) {
			if (!prefix.endsWith("/")) {
				prefix = prefix ~ "/";
			}
			result ~= prefix;
		}
		return result;
	}

	/**
	 * Configure a {@link MessageConverter} to use to convert the payload of a message from
	 * its serialized form with a specific MIME type to an Object matching the target method
	 * parameter. The converter is also used when sending a message to the message broker.
	 * @see CompositeMessageConverter
	 */
	void setMessageConverter(MessageConverter converter) {
		this.messageConverter = converter;
		(cast(AbstractMessageSendingTemplate!string) this.clientMessagingTemplate).setMessageConverter(converter);
	}

	/**
	 * Return the configured {@link MessageConverter}.
	 */
	MessageConverter getMessageConverter() {
		return this.messageConverter;
	}

	/**
	 * Configure a {@link ConversionService} to use when resolving method arguments,
	 * for example message header values.
	 * <p>By default, {@link DefaultFormattingConversionService} is used.
	 */
	// void setConversionService(ConversionService conversionService) {
	// 	this.conversionService = conversionService;
	// }

	/**
	 * Return the configured {@link ConversionService}.
	 */
	// ConversionService getConversionService() {
	// 	return this.conversionService;
	// }

	/**
	 * Set the PathMatcher implementation to use for matching destinations
	 * against configured destination patterns.
	 * <p>By default, {@link AntPathMatcher} is used.
	 */
	void setPathMatcher(PathMatcher pathMatcher) {
		assert(pathMatcher, "PathMatcher must not be null");
		this.pathMatcher = pathMatcher;
		this.slashPathSeparator = this.pathMatcher.combine("a", "a") == ("a/a");
	}

	/**
	 * Return the PathMatcher implementation to use for matching destinations.
	 */
	PathMatcher getPathMatcher() {
		return this.pathMatcher;
	}

	/**
	 * Return the configured Validator instance.
	 */
	
	// Validator getValidator() {
	// 	return this.validator;
	// }

	/**
	 * Set the Validator instance used for validating {@code @Payload} arguments.
	 * @see hunt.framework.validation.annotation.Validated
	 * @see PayloadArgumentResolver
	 */
	// void setValidator(Validator validator) {
	// 	this.validator = validator;
	// }

	// override
	// void setEmbeddedValueResolver(StringValueResolver resolver) {
	// 	this.valueResolver = resolver;
	// }

	/**
	 * Configure a {@link MessageHeaderInitializer} to pass on to
	 * {@link HandlerMethodReturnValueHandler HandlerMethodReturnValueHandlers}
	 * that send messages from controller return values.
	 * <p>By default, this property is not set.
	 */
	void setHeaderInitializer(MessageHeaderInitializer headerInitializer) {
		this.headerInitializer = headerInitializer;
	}

	/**
	 * Return the configured header initializer.
	 */
	
	MessageHeaderInitializer getHeaderInitializer() {
		return this.headerInitializer;
	}

	bool isAutoStartup() {
		return true;
	}

	int getPhase() {
		return int.max;
	}

	// override
	final void start() {
		synchronized (this.lifecycleMonitor) {
			this.clientInboundChannel.subscribe(this);
			this.running = true;
		}
	}

	// override
	final void stop() {
		synchronized (this.lifecycleMonitor) {
			this.running = false;
			this.clientInboundChannel.unsubscribe(this);
		}
	}

	// override
	final void stop(Runnable callback) {
		synchronized (this.lifecycleMonitor) {
			stop();
			callback.run();
		}
	}

	// override
	bool isRunning() {
		return this.running;
	}

	// protected List!(HandlerMethodArgumentResolver) initArgumentResolvers() {
	// 	ApplicationContext context = getApplicationContext();
	// 	ConfigurableBeanFactory beanFactory = (context instanceof ConfigurableApplicationContext ?
	// 			((ConfigurableApplicationContext) context).getBeanFactory() : null);

	// 	List!(HandlerMethodArgumentResolver) resolvers = new ArrayList<>();

	// 	// Annotation-based argument resolution
	// 	resolvers.add(new HeaderMethodArgumentResolver(this.conversionService, beanFactory));
	// 	resolvers.add(new HeadersMethodArgumentResolver());
	// 	resolvers.add(new DestinationVariableMethodArgumentResolver(this.conversionService));

	// 	// Type-based argument resolution
	// 	resolvers.add(new PrincipalMethodArgumentResolver());
	// 	resolvers.add(new MessageMethodArgumentResolver(this.messageConverter));

	// 	resolvers.addAll(getCustomArgumentResolvers());
	// 	resolvers.add(new PayloadArgumentResolver(this.messageConverter, this.validator));

	// 	return resolvers;
	// }

	// override
	// protected List!(HandlerMethodReturnValueHandler) initReturnValueHandlers() {
	// 	List!(HandlerMethodReturnValueHandler) handlers = new ArrayList<>();

	// 	// Single-purpose return value types

	// 	handlers.add(new ListenableFutureReturnValueHandler());
	// 	handlers.add(new CompletableFutureReturnValueHandler());
	// 	handlers.add(new ReactiveReturnValueHandler());

	// 	// Annotation-based return value types

	// 	SendToMethodReturnValueHandler sendToHandler =
	// 			new SendToMethodReturnValueHandler(this.brokerTemplate, true);
	// 	sendToHandler.setHeaderInitializer(this.headerInitializer);
	// 	handlers.add(sendToHandler);

	// 	SubscriptionMethodReturnValueHandler subscriptionHandler =
	// 			new SubscriptionMethodReturnValueHandler(this.clientMessagingTemplate);
	// 	subscriptionHandler.setHeaderInitializer(this.headerInitializer);
	// 	handlers.add(subscriptionHandler);

	// 	// Custom return value types

	// 	handlers.addAll(getCustomReturnValueHandlers());

	// 	// Catch-all

	// 	sendToHandler = new SendToMethodReturnValueHandler(this.brokerTemplate, false);
	// 	sendToHandler.setHeaderInitializer(this.headerInitializer);
	// 	handlers.add(sendToHandler);

	// 	return handlers;
	// }

	// override
	// protected bool isHandler(Class<?> beanType) {
	// 	return AnnotatedElementUtils.hasAnnotation(beanType, Controller.class);
	// }

	// override
	
	// protected SimpMessageMappingInfo getMappingForMethod(Method method, Class<?> handlerType) {
	// 	MessageMapping messageAnn = AnnotatedElementUtils.findMergedAnnotation(method, MessageMapping.class);
	// 	if (messageAnn !is null) {
	// 		MessageMapping typeAnn = AnnotatedElementUtils.findMergedAnnotation(handlerType, MessageMapping.class);
	// 		// Only actually register it if there are destinations specified;
	// 		// otherwise @MessageMapping is just being used as a (meta-annotation) marker.
	// 		if (messageAnn.value().length > 0 || (typeAnn !is null && typeAnn.value().length > 0)) {
	// 			SimpMessageMappingInfo result = createMessageMappingCondition(messageAnn.value());
	// 			if (typeAnn !is null) {
	// 				result = createMessageMappingCondition(typeAnn.value()).combine(result);
	// 			}
	// 			return result;
	// 		}
	// 	}

	// 	SubscribeMapping subscribeAnn = AnnotatedElementUtils.findMergedAnnotation(method, SubscribeMapping.class);
	// 	if (subscribeAnn !is null) {
	// 		MessageMapping typeAnn = AnnotatedElementUtils.findMergedAnnotation(handlerType, MessageMapping.class);
	// 		// Only actually register it if there are destinations specified;
	// 		// otherwise @SubscribeMapping is just being used as a (meta-annotation) marker.
	// 		if (subscribeAnn.value().length > 0 || (typeAnn !is null && typeAnn.value().length > 0)) {
	// 			SimpMessageMappingInfo result = createSubscribeMappingCondition(subscribeAnn.value());
	// 			if (typeAnn !is null) {
	// 				result = createMessageMappingCondition(typeAnn.value()).combine(result);
	// 			}
	// 			return result;
	// 		}
	// 	}

	// 	return null;
	// }

	// private SimpMessageMappingInfo createMessageMappingCondition(string[] destinations) {
	// 	string[] resolvedDestinations = resolveEmbeddedValuesInDestinations(destinations);
	// 	return new SimpMessageMappingInfo(SimpMessageTypeMessageCondition.MESSAGE,
	// 			new DestinationPatternsMessageCondition(resolvedDestinations, this.pathMatcher));
	// }

	// private SimpMessageMappingInfo createSubscribeMappingCondition(string[] destinations) {
	// 	string[] resolvedDestinations = resolveEmbeddedValuesInDestinations(destinations);
	// 	return new SimpMessageMappingInfo(SimpMessageTypeMessageCondition.SUBSCRIBE,
	// 			new DestinationPatternsMessageCondition(resolvedDestinations, this.pathMatcher));
	// }

	/**
	 * Resolve placeholder values in the given array of destinations.
	 * @return a new array with updated destinations
	 * @since 4.2
	 */
	// protected string[] resolveEmbeddedValuesInDestinations(string[] destinations) {
	// 	if (this.valueResolver is null) {
	// 		return destinations;
	// 	}
	// 	string[] result = new string[destinations.length];
	// 	for (int i = 0; i < destinations.length; i++) {
	// 		result[i] = this.valueResolver.resolveStringValue(destinations[i]);
	// 	}
	// 	return result;
	// }

	// override
	// protected Set!(string) getDirectLookupDestinations(SimpMessageMappingInfo mapping) {
	// 	Set!(string) result = new LinkedHashSet<>();
	// 	for (string pattern : mapping.getDestinationConditions().getPatterns()) {
	// 		if (!this.pathMatcher.isPattern(pattern)) {
	// 			result.add(pattern);
	// 		}
	// 	}
	// 	return result;
	// }

	override
	protected string getDestination(MessageBase message) {
		return SimpMessageHeaderAccessor.getDestination(message.getHeaders());
	}

	override
	protected string getLookupDestination(string destination) {
		if (destination is null) {
			return null;
		}
		string[] prefixes = getDestinationPrefixes();
		if (prefixes.length == 0) {
			return destination;
		}
		foreach (string prefix ; prefixes) {
			if (destination.startsWith(prefix)) {
				size_t pos = prefix.length;
				if (this.slashPathSeparator) 
					pos = pos - 1;
				return destination[pos .. $];
			}
		}
		return null;
	}

	override protected void handleReturnValue(Object returnValue, TypeInfo returnType, 
			MessageBase message, string[] destinations) {
		MessageHeaders headers = message.getHeaders();
		string sessionId = SimpMessageHeaderAccessor.getSessionId(headers);
		version(HUNT_DEBUG) tracef("raw return type: %s", returnType);
		MessageHeaders hs = createHeaders(sessionId, returnType);
		foreach (string destination ; destinations) {
			version(HUNT_DEBUG) trace("handling destination: ", destination);
			this.brokerTemplate.convertAndSend(destination, returnValue, hs);
		}
	}

	private MessageHeaders createHeaders(string sessionId, TypeInfo returnType) {
		SimpMessageHeaderAccessor headerAccessor = SimpMessageHeaderAccessor.create(SimpMessageType.MESSAGE);
		if (getHeaderInitializer() !is null) {
			getHeaderInitializer().initHeaders(headerAccessor);
		}

		if (!sessionId.empty) {
			headerAccessor.setSessionId(sessionId);
		}
		headerAccessor.setHeader(SimpMessagingTemplate.CONVERSION_HINT_HEADER, returnType);
		headerAccessor.setLeaveMutable(true);
		return headerAccessor.getMessageHeaders();
	}

	// override
	// protected SimpMessageMappingInfo getMatchingMapping(SimpMessageMappingInfo mapping, MessageBase message) {
	// 	return mapping.getMatchingCondition(message);

	// }

	// override
	// protected Comparator!(SimpMessageMappingInfo) getMappingComparator(final MessageBase message) {
	// 	return (info1, info2) -> info1.compareTo(info2, message);
	// }

	// override
	// protected void handleMatch(SimpMessageMappingInfo mapping, HandlerMethod handlerMethod,
	// 		string lookupDestination, MessageBase message) {

	// 	Set!(string) patterns = mapping.getDestinationConditions().getPatterns();
	// 	if (!CollectionUtils.isEmpty(patterns)) {
	// 		string pattern = patterns.iterator().next();
	// 		Map!(string, string) vars = getPathMatcher().extractUriTemplateVariables(pattern, lookupDestination);
	// 		if (!CollectionUtils.isEmpty(vars)) {
	// 			MessageHeaderAccessor mha = MessageHeaderAccessor.getAccessor(message, MessageHeaderAccessor.class);
	// 			assert(mha !is null && mha.isMutable(), "Mutable MessageHeaderAccessor required");
	// 			mha.setHeader(DestinationVariableMethodArgumentResolver.DESTINATION_TEMPLATE_VARIABLES_HEADER, vars);
	// 		}
	// 	}

	// 	try {
	// 		SimpAttributesContextHolder.setAttributesFromMessage(message);
	// 		super.handleMatch(mapping, handlerMethod, lookupDestination, message);
	// 	}
	// 	finally {
	// 		SimpAttributesContextHolder.resetAttributes();
	// 	}
	// }

	// override
	// protected AbstractExceptionHandlerMethodResolver createExceptionHandlerMethodResolverFor(Class<?> beanType) {
	// 	return new AnnotationExceptionHandlerMethodResolver(beanType);
	// }

}
