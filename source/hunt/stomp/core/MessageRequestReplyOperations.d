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

module hunt.stomp.core.MessageRequestReplyOperations;

import hunt.container.Map;


import hunt.stomp.Message;
import hunt.stomp.MessagingException;

/**
 * Operations for sending messages to and receiving the reply from a destination.
 *
 * @author Mark Fisher
 * @author Rossen Stoyanchev
 * @since 4.0
 * @param (T) the type of destination
 * @see GenericMessagingTemplate
 */
interface MessageRequestReplyOperations(T) {

	/**
	 * Send a request message and receive the reply from a default destination.
	 * @param requestMessage the message to send
	 * @return the reply, possibly {@code null} if the message could not be received,
	 * for example due to a timeout
	 */
	
	Message!(T) sendAndReceive(Message!(T) requestMessage);

	/**
	 * Send a request message and receive the reply from the given destination.
	 * @param destination the target destination
	 * @param requestMessage the message to send
	 * @return the reply, possibly {@code null} if the message could not be received,
	 * for example due to a timeout
	 */
	
	Message!(T) sendAndReceive(T destination, Message!(T) requestMessage);

	/**
	 * Convert the given request Object to serialized form, possibly using a
	 * {@link hunt.stomp.converter.MessageConverter}, send
	 * it as a {@link Message} to a default destination, receive the reply and convert
	 * its body of the specified target class.
	 * @param request payload for the request message to send
	 * @param targetClass the target type to convert the payload of the reply to
	 * @return the payload of the reply message, possibly {@code null} if the message
	 * could not be received, for example due to a timeout
	 */
	
	// <T> T convertSendAndReceive(Object request, Class!(T) targetClass);

	/**
	 * Convert the given request Object to serialized form, possibly using a
	 * {@link hunt.stomp.converter.MessageConverter}, send
	 * it as a {@link Message} to the given destination, receive the reply and convert
	 * its body of the specified target class.
	 * @param destination the target destination
	 * @param request payload for the request message to send
	 * @param targetClass the target type to convert the payload of the reply to
	 * @return the payload of the reply message, possibly {@code null} if the message
	 * could not be received, for example due to a timeout
	 */
	
	// <T> T convertSendAndReceive(T destination, Object request, Class!(T) targetClass);

	/**
	 * Convert the given request Object to serialized form, possibly using a
	 * {@link hunt.stomp.converter.MessageConverter}, send
	 * it as a {@link Message} with the given headers, to the specified destination,
	 * receive the reply and convert its body of the specified target class.
	 * @param destination the target destination
	 * @param request payload for the request message to send
	 * @param headers headers for the request message to send
	 * @param targetClass the target type to convert the payload of the reply to
	 * @return the payload of the reply message, possibly {@code null} if the message
	 * could not be received, for example due to a timeout
	 */
	
	// <T> T convertSendAndReceive(
	// 		T destination, Object request, Map!(string, Object) headers, Class!(T) targetClass);

	/**
	 * Convert the given request Object to serialized form, possibly using a
	 * {@link hunt.stomp.converter.MessageConverter},
	 * apply the given post processor and send the resulting {@link Message} to a
	 * default destination, receive the reply and convert its body of the given
	 * target class.
	 * @param request payload for the request message to send
	 * @param targetClass the target type to convert the payload of the reply to
	 * @param requestPostProcessor post process to apply to the request message
	 * @return the payload of the reply message, possibly {@code null} if the message
	 * could not be received, for example due to a timeout
	 */
	
	// <T> T convertSendAndReceive(
	// 		Object request, Class!(T) targetClass, MessagePostProcessor requestPostProcessor);

	/**
	 * Convert the given request Object to serialized form, possibly using a
	 * {@link hunt.stomp.converter.MessageConverter},
	 * apply the given post processor and send the resulting {@link Message} to the
	 * given destination, receive the reply and convert its body of the given
	 * target class.
	 * @param destination the target destination
	 * @param request payload for the request message to send
	 * @param targetClass the target type to convert the payload of the reply to
	 * @param requestPostProcessor post process to apply to the request message
	 * @return the payload of the reply message, possibly {@code null} if the message
	 * could not be received, for example due to a timeout
	 */
	
	// <T> T convertSendAndReceive(T destination, Object request, Class!(T) targetClass,
	// 		MessagePostProcessor requestPostProcessor);

	/**
	 * Convert the given request Object to serialized form, possibly using a
	 * {@link hunt.stomp.converter.MessageConverter},
	 * wrap it as a message with the given headers, apply the given post processor
	 * and send the resulting {@link Message} to the specified destination, receive
	 * the reply and convert its body of the given target class.
	 * @param destination the target destination
	 * @param request payload for the request message to send
	 * @param targetClass the target type to convert the payload of the reply to
	 * @param requestPostProcessor post process to apply to the request message
	 * @return the payload of the reply message, possibly {@code null} if the message
	 * could not be received, for example due to a timeout
	 */
	
	// <T> T convertSendAndReceive(
	// 		T destination, Object request, Map!(string, Object) headers, Class!(T) targetClass,
	// 		MessagePostProcessor requestPostProcessor);

}
