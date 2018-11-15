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

module hunt.stomp.simp.config.AbstractMessageBrokerConfiguration;

import hunt.stomp.simp.config.ChannelRegistration;
import hunt.stomp.simp.config.MessageBrokerRegistry;

// import hunt.framework.beans.BeanUtils;
// import hunt.framework.beans.factory.BeanInitializationException;
// import hunt.framework.context.ApplicationContext;
// import hunt.framework.context.ApplicationContextAware;
// import hunt.framework.context.annotation.Bean;
// import hunt.framework.context.event.SmartApplicationListener;


import hunt.stomp.converter.ByteArrayMessageConverter;
import hunt.stomp.converter.CompositeMessageConverter;
import hunt.stomp.converter.DefaultContentTypeResolver;
import hunt.stomp.converter.JsonMessageConverter;
import hunt.stomp.converter.MessageConverter;
import hunt.stomp.converter.StringMessageConverter;
// import hunt.stomp.handler.invocation.HandlerMethodArgumentResolver;
// import hunt.stomp.handler.invocation.HandlerMethodReturnValueHandler;

import hunt.stomp.simp.SimpMessagingTemplate;
import hunt.stomp.simp.annotation.SimpAnnotationMethodMessageHandler;
import hunt.stomp.simp.broker.AbstractBrokerMessageHandler;
import hunt.stomp.simp.broker.SimpleBrokerMessageHandler;
import hunt.stomp.simp.stomp.StompBrokerRelayMessageHandler;
// import hunt.stomp.simp.user.DefaultUserDestinationResolver;
// import hunt.stomp.simp.user.MultiServerUserRegistry;
// import hunt.stomp.simp.user.SimpUserRegistry;
// import hunt.stomp.simp.user.UserDestinationMessageHandler;
// import hunt.stomp.simp.user.UserDestinationResolver;
// import hunt.stomp.simp.user.UserRegistryMessageHandler;
import hunt.stomp.support.AbstractSubscribableChannel;
import hunt.stomp.support.ExecutorSubscribableChannel;
import hunt.stomp.support.ImmutableMessageChannelInterceptor;
// import hunt.framework.scheduling.concurrent.ThreadPoolTaskExecutor;
// import hunt.framework.scheduling.concurrent.ThreadPoolTaskScheduler;

import hunt.container;
import hunt.util.MimeType;
import hunt.lang.exception;
import hunt.string.PathMatcher;

import std.string;

/**
 * Provides essential configuration for handling messages with simple messaging
 * protocols such as STOMP.
 *
 * <p>{@link #clientInboundChannel()} and {@link #clientOutboundChannel()} deliver
 * messages to and from remote clients to several message handlers such as
 * <ul>
 * <li>{@link #simpAnnotationMethodMessageHandler()}</li>
 * <li>{@link #simpleBrokerMessageHandler()}</li>
 * <li>{@link #stompBrokerRelayMessageHandler()}</li>
 * <li>{@link #userDestinationMessageHandler()}</li>
 * </ul>
 * while {@link #brokerChannel()} delivers messages from within the application to the
 * the respective message handlers. {@link #brokerMessagingTemplate()} can be injected
 * into any application component to send messages.
 *
 * <p>Subclasses are responsible for the part of the configuration that feed messages
 * to and from the client inbound/outbound channels (e.g. STOMP over WebSocket).
 *
 * @author Rossen Stoyanchev
 * @author Brian Clozel
 * @since 4.0
 */
abstract class AbstractMessageBrokerConfiguration { // : ApplicationContextAware 

	private enum string MVC_VALIDATOR_NAME = "mvcValidator";

	// private static bool jackson2Present = ClassUtils.isPresent(
	// 		"com.fasterxml.jackson.databind.ObjectMapper", AbstractMessageBrokerConfiguration.class.getClassLoader());

	
	// protected ApplicationContext applicationContext;
	
	private ChannelRegistration clientInboundChannelRegistration;
	
	private ChannelRegistration clientOutboundChannelRegistration;
	
	private MessageBrokerRegistry brokerRegistry;


	/**
	 * Protected constructor.
	 */
	// protected this(ApplicationContext context) {
    //     this.applicationContext = context;
	// }

	// override
	// void setApplicationContext(ApplicationContext applicationContext) {
	// 	this.applicationContext = applicationContext;
	// }

	
	// ApplicationContext getApplicationContext() {
	// 	return this.applicationContext;
	// }

	AbstractSubscribableChannel clientInboundChannel() {
		if(inboundChannel is null) {
			// ExecutorSubscribableChannel channel = new ExecutorSubscribableChannel(clientInboundChannelExecutor());
			inboundChannel = new ExecutorSubscribableChannel(null);
			// channel.setLogger(SimpLogging.forLog(channel.getLogger()));
			inboundChannel.id = "inbound";
			ChannelRegistration reg = getClientInboundChannelRegistration();
			if (reg.hasInterceptors()) {
				inboundChannel.setInterceptors(reg.getInterceptors());
			}
		}
		return inboundChannel;
	}
	private AbstractSubscribableChannel inboundChannel;

	
	// ThreadPoolTaskExecutor clientInboundChannelExecutor() {
	// 	TaskExecutorRegistration reg = getClientInboundChannelRegistration().taskExecutor();
	// 	ThreadPoolTaskExecutor executor = reg.getTaskExecutor();
	// 	executor.setThreadNamePrefix("clientInboundChannel-");
	// 	return executor;
	// }

	protected final ChannelRegistration getClientInboundChannelRegistration() {
		if (this.clientInboundChannelRegistration is null) {
			ChannelRegistration registration = new ChannelRegistration();
			configureClientInboundChannel(registration);
			registration.addInterceptors(new ImmutableMessageChannelInterceptor());
			this.clientInboundChannelRegistration = registration;
		}
		return this.clientInboundChannelRegistration;
	}

	/**
	 * A hook for subclasses to customize the message channel for inbound messages
	 * from WebSocket clients.
	 */
	protected void configureClientInboundChannel(ChannelRegistration registration) {
	}

	
	AbstractSubscribableChannel clientOutboundChannel() {
		if(outboundChannel is null) {
			// ExecutorSubscribableChannel channel = new ExecutorSubscribableChannel(clientOutboundChannelExecutor());
			outboundChannel = new ExecutorSubscribableChannel(null);
			outboundChannel.id = "outbound";
			ChannelRegistration reg = getClientOutboundChannelRegistration();
			if (reg.hasInterceptors()) {
				outboundChannel.setInterceptors(reg.getInterceptors());
			}
		}
		return outboundChannel;
	}
	private AbstractSubscribableChannel outboundChannel;

	
	// ThreadPoolTaskExecutor clientOutboundChannelExecutor() {
	// 	TaskExecutorRegistration reg = getClientOutboundChannelRegistration().taskExecutor();
	// 	ThreadPoolTaskExecutor executor = reg.getTaskExecutor();
	// 	executor.setThreadNamePrefix("clientOutboundChannel-");
	// 	return executor;
	// }

	protected final ChannelRegistration getClientOutboundChannelRegistration() {
		if (this.clientOutboundChannelRegistration is null) {
			ChannelRegistration registration = new ChannelRegistration();
			configureClientOutboundChannel(registration);
			registration.addInterceptors(new ImmutableMessageChannelInterceptor());
			this.clientOutboundChannelRegistration = registration;
		}
		return this.clientOutboundChannelRegistration;
	}

	/**
	 * A hook for subclasses to customize the message channel for messages from
	 * the application or message broker to WebSocket clients.
	 */
	protected void configureClientOutboundChannel(ChannelRegistration registration) {
	}

	
	AbstractSubscribableChannel brokerChannel() {
		if(_brokerChannel is null) {
			ChannelRegistration reg = getBrokerRegistry().getBrokerChannelRegistration();
			_brokerChannel = (reg.hasTaskExecutor() ?
					new ExecutorSubscribableChannel(null) : new ExecutorSubscribableChannel());
			_brokerChannel.id = "brokerChannel";

			// ExecutorSubscribableChannel channel = (reg.hasTaskExecutor() ?
			// 		new ExecutorSubscribableChannel(brokerChannelExecutor()) : new ExecutorSubscribableChannel());
			reg.addInterceptors(new ImmutableMessageChannelInterceptor());
			// channel.setLogger(SimpLogging.forLog(channel.getLogger()));
			_brokerChannel.setInterceptors(reg.getInterceptors());
		}
		return _brokerChannel;
	}
	private AbstractSubscribableChannel _brokerChannel;

	
	// ThreadPoolTaskExecutor brokerChannelExecutor() {
	// 	ChannelRegistration reg = getBrokerRegistry().getBrokerChannelRegistration();
	// 	ThreadPoolTaskExecutor executor;
	// 	if (reg.hasTaskExecutor()) {
	// 		executor = reg.taskExecutor().getTaskExecutor();
	// 	}
	// 	else {
	// 		// Should never be used
	// 		executor = new ThreadPoolTaskExecutor();
	// 		executor.setCorePoolSize(0);
	// 		executor.setMaxPoolSize(1);
	// 		executor.setQueueCapacity(0);
	// 	}
	// 	executor.setThreadNamePrefix("brokerChannel-");
	// 	return executor;
	// }

	/**
	 * An accessor for the {@link MessageBrokerRegistry} that ensures its one-time creation
	 * and initialization through {@link #configureMessageBroker(MessageBrokerRegistry)}.
	 */
	protected final MessageBrokerRegistry getBrokerRegistry() {
		if (this.brokerRegistry is null) {
			MessageBrokerRegistry registry = new 
                MessageBrokerRegistry(clientInboundChannel(), clientOutboundChannel());
			configureMessageBroker(registry);
			this.brokerRegistry = registry;
		}
		return this.brokerRegistry;
	}

	/**
	 * A hook for subclasses to customize message broker configuration through the
	 * provided {@link MessageBrokerRegistry} instance.
	 */
	protected void configureMessageBroker(MessageBrokerRegistry registry) {
	}

	/**
	 * Provide access to the configured PatchMatcher for access from other
	 * configuration classes.
	 */
	
	final PathMatcher getPathMatcher() {
		return getBrokerRegistry().getPathMatcher();
	}

	
	SimpAnnotationMethodMessageHandler simpAnnotationMethodMessageHandler() {
		SimpAnnotationMethodMessageHandler handler = createAnnotationMethodMessageHandler();
		handler.setDestinationPrefixes(getBrokerRegistry().getApplicationDestinationPrefixes());
		handler.setMessageConverter(brokerMessageConverter());
		// handler.setValidator(simpValidator());

		// List!(HandlerMethodArgumentResolver) argumentResolvers = 
        //     new ArrayList!HandlerMethodArgumentResolver();
		// addArgumentResolvers(argumentResolvers);
		// handler.setCustomArgumentResolvers(argumentResolvers);

		// List!(HandlerMethodReturnValueHandler) returnValueHandlers = 
        //     new ArrayList!(HandlerMethodReturnValueHandler)();
		// addReturnValueHandlers(returnValueHandlers);
		// handler.setCustomReturnValueHandlers(returnValueHandlers);

		PathMatcher pathMatcher = getBrokerRegistry().getPathMatcher();
		if (pathMatcher !is null) {
			handler.setPathMatcher(pathMatcher);
		}
		return handler;
	}

	/**
	 * Protected method for plugging in a custom subclass of
	 * {@link hunt.stomp.simp.annotation.SimpAnnotationMethodMessageHandler
	 * SimpAnnotationMethodMessageHandler}.
	 * @since 4.2
	 */
	protected SimpAnnotationMethodMessageHandler createAnnotationMethodMessageHandler() {
		return new SimpAnnotationMethodMessageHandler(clientInboundChannel(),
				clientOutboundChannel(), brokerMessagingTemplate()); 
	}

	// protected void addArgumentResolvers(List!(HandlerMethodArgumentResolver) argumentResolvers) {
	// }

	// protected void addReturnValueHandlers(List!(HandlerMethodReturnValueHandler) returnValueHandlers) {
	// }

	
	
	AbstractBrokerMessageHandler simpleBrokerMessageHandler() {
		SimpleBrokerMessageHandler handler = getBrokerRegistry().getSimpleBroker(brokerChannel());
		if (handler is null) {
			return null;
		}
		updateUserDestinationResolver(handler);
		return handler;
	}

	private void updateUserDestinationResolver(AbstractBrokerMessageHandler handler) {
		string[] prefixes = handler.getDestinationPrefixes();
		// if (!prefixes.isEmpty() && !prefixes.iterator().next().startsWith("/")) {
        if(prefixes.length > 0 && !prefixes[0].startsWith("/")) {
			// (cast(DefaultUserDestinationResolver) userDestinationResolver()).setRemoveLeadingSlash(true);
		}
	}

	AbstractBrokerMessageHandler stompBrokerRelayMessageHandler() {

		// implementationMissing(false);
		return null;
		// TODO: Tasks pending completion -@zxp at 10/31/2018, 5:39:16 PM
		// 		
		// StompBrokerRelayMessageHandler handler = getBrokerRegistry().getStompBrokerRelay(brokerChannel());
		// if (handler is null) {
		// 	return null;
		// }

		// Map!(string, MessageHandler) subscriptions = new HashMap!(string, MessageHandler)(4);
		// string destination = getBrokerRegistry().getUserDestinationBroadcast();
		// if (destination !is null) {
		// 	subscriptions.put(destination, userDestinationMessageHandler());
		// }
		// destination = getBrokerRegistry().getUserRegistryBroadcast();
		// if (destination !is null) {
		// 	subscriptions.put(destination, userRegistryMessageHandler());
		// }
		// handler.setSystemSubscriptions(subscriptions);
		// updateUserDestinationResolver(handler);
		// return handler;
	}

	
	// UserDestinationMessageHandler userDestinationMessageHandler() {
	// 	UserDestinationMessageHandler handler = new UserDestinationMessageHandler(clientInboundChannel(),
	// 			brokerChannel(), userDestinationResolver());
	// 	string destination = getBrokerRegistry().getUserDestinationBroadcast();
	// 	if (destination !is null) {
	// 		handler.setBroadcastDestination(destination);
	// 	}
	// 	return handler;
	// }
	
	
	// MessageHandler userRegistryMessageHandler() {
	// 	if (getBrokerRegistry().getUserRegistryBroadcast() is null) {
	// 		return null;
	// 	}
	// 	SimpUserRegistry userRegistry = userRegistry();
	// 	Assert.isInstanceOf(MultiServerUserRegistry.class, userRegistry, "MultiServerUserRegistry required");
	// 	return new UserRegistryMessageHandler((MultiServerUserRegistry) userRegistry,
	// 			brokerMessagingTemplate(), getBrokerRegistry().getUserRegistryBroadcast(),
	// 			messageBrokerTaskScheduler());
	// }

	// Expose alias for 4.1 compatibility
	// ThreadPoolTaskScheduler messageBrokerTaskScheduler() {
	// 	ThreadPoolTaskScheduler scheduler = new ThreadPoolTaskScheduler();
	// 	scheduler.setThreadNamePrefix("MessageBroker-");
	// 	scheduler.setPoolSize(Runtime.getRuntime().availableProcessors());
	// 	scheduler.setRemoveOnCancelPolicy(true);
	// 	return scheduler;
	// }

	
	SimpMessagingTemplate brokerMessagingTemplate() {
		SimpMessagingTemplate t = new SimpMessagingTemplate(brokerChannel());
		string prefix = getBrokerRegistry().getUserDestinationPrefix();
		if (prefix !is null) {
			t.setUserDestinationPrefix(prefix);
		}
		t.setMessageConverter(brokerMessageConverter());
		return t;
	}

	
	CompositeMessageConverter brokerMessageConverter() {
		MessageConverter[] converters;
		bool registerDefaults = configureMessageConverters(converters);
		if (registerDefaults) {
			converters ~= new StringMessageConverter();
			converters ~= new ByteArrayMessageConverter();
			converters ~= createJsonConverter();
			// if (jackson2Present) {
			// 	converters.add(createJacksonConverter());
			// }
		}
		return new CompositeMessageConverter(converters);
	}

	protected JsonMessageConverter createJsonConverter() {
		DefaultContentTypeResolver resolver = new DefaultContentTypeResolver();
		resolver.setDefaultMimeType(MimeType.APPLICATION_JSON);

		JsonMessageConverter converter = new JsonMessageConverter();
		converter.setContentTypeResolver(resolver);
		
		return converter;
	}

	/**
	 * Override this method to add custom message converters.
	 * @param messageConverters the list to add converters to, initially empty
	 * @return {@code true} if default message converters should be added to list,
	 * {@code false} if no more converters should be added.
	 */
	protected bool configureMessageConverters(MessageConverter[] messageConverters) {
		return true;
	}

	
	// UserDestinationResolver userDestinationResolver() {
	// 	DefaultUserDestinationResolver resolver = new DefaultUserDestinationResolver(userRegistry());
	// 	string prefix = getBrokerRegistry().getUserDestinationPrefix();
	// 	if (prefix !is null) {
	// 		resolver.setUserDestinationPrefix(prefix);
	// 	}
	// 	return resolver;
	// }

	
	
	// SimpUserRegistry userRegistry() {
	// 	SimpUserRegistry registry = createLocalUserRegistry();
	// 	if (registry is null) {
	// 		registry = createLocalUserRegistry(getBrokerRegistry().getUserRegistryOrder());
	// 	}
	// 	 broadcast = getBrokerRegistry().getUserRegistryBroadcast() !is null;
	// 	return (broadcast ? new MultiServerUserRegistry(registry) : registry);
	// }

	/**
	 * Create the user registry that provides access to local users.
	 * @deprecated as of 5.1 in favor of {@link #createLocalUserRegistry(int)}
	 */
	// @Deprecated
	// protected SimpUserRegistry createLocalUserRegistry() {
	// 	return null;
	// }

	/**
	 * Create the user registry that provides access to local users.
	 * @param order the order to use as a {@link SmartApplicationListener}.
	 * @since 5.1
	 */
	// protected abstract SimpUserRegistry createLocalUserRegistry(int order);

	/**
	 * Return a {@link hunt.framework.validation.Validator
	 * hunt.framework.validation.Validators} instance for validating
	 * {@code @Payload} method arguments.
	 * <p>In order, this method tries to get a Validator instance:
	 * <ul>
	 * <li>delegating to getValidator() first</li>
	 * <li>if none returned, getting an existing instance with its well-known name "mvcValidator",
	 * created by an MVC configuration</li>
	 * <li>if none returned, checking the classpath for the presence of a JSR-303 implementation
	 * before creating a {@code OptionalValidatorFactoryBean}</li>
	 * <li>returning a no-op Validator instance</li>
	 * </ul>
	 */
	// protected Validator simpValidator() {
	// 	Validator validator = getValidator();
	// 	if (validator is null) {
	// 		if (this.applicationContext !is null && this.applicationContext.containsBean(MVC_VALIDATOR_NAME)) {
	// 			validator = this.applicationContext.getBean(MVC_VALIDATOR_NAME, Validator.class);
	// 		}
	// 		else if (ClassUtils.isPresent("javax.validation.Validator", getClass().getClassLoader())) {
	// 			Class<?> clazz;
	// 			try {
	// 				string className = "hunt.framework.validation.beanvalidation.OptionalValidatorFactoryBean";
	// 				clazz = ClassUtils.forName(className, AbstractMessageBrokerConfiguration.class.getClassLoader());
	// 			}
	// 			catch (Throwable ex) {
	// 				throw new BeanInitializationException("Could not find default validator class", ex);
	// 			}
	// 			validator = (Validator) BeanUtils.instantiateClass(clazz);
	// 		}
	// 		else {
	// 			validator = new Validator() {
	// 				override
	// 				bool supports(Class<?> clazz) {
	// 					return false;
	// 				}
	// 				override
	// 				void validate(Object target, Errors errors) {
	// 				}
	// 			};
	// 		}
	// 	}
	// 	return validator;
	// }

	/**
	 * Override this method to provide a custom {@link Validator}.
	 * @since 4.0.1
	 */
	
	// Validator getValidator() {
	// 	return null;
	// }

}
