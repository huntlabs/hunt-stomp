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

module hunt.stomp.core.MessageReceivingOperations;

import hunt.lang.Nullable;
import hunt.stomp.Message;
import hunt.stomp.MessagingException;

/**
 * Operations for receiving messages from a destination.
 *
 * @author Mark Fisher
 * @author Rossen Stoyanchev
 * @since 4.0
 * @param (T) the type of destination
 * @see GenericMessagingTemplate
 */
interface MessageReceivingOperations(T) {

	/**
	 * Receive a message from a default destination.
	 * @return the received message, possibly {@code null} if the message could not
	 * be received, for example due to a timeout
	 */
	
	Message!(T) receive();

	/**
	 * Receive a message from the given destination.
	 * @param destination the target destination
	 * @return the received message, possibly {@code null} if the message could not
	 * be received, for example due to a timeout
	 */
	
	Message!(T) receive(T destination);

	/**
	 * Receive a message from a default destination and convert its payload to the
	 * specified target class.
	 * @param targetClass the target class to convert the payload to
	 * @return the converted payload of the reply message, possibly {@code null} if
	 * the message could not be received, for example due to a timeout
	 */
	
	// <T> T receiveAndConvert(Class!(T) targetClass);

	/**
	 * Receive a message from the given destination and convert its payload to the
	 * specified target class.
	 * @param destination the target destination
	 * @param targetClass the target class to convert the payload to
	 * @return the converted payload of the reply message, possibly {@code null} if
	 * the message could not be received, for example due to a timeout
	 */
	
	// <T> T receiveAndConvert(T destination, Class!(T) targetClass);

}
