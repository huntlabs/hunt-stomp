/*
 * Copyright 2002-2016 the original author or authors.
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

module hunt.stomp.converter.CompositeMessageConverter;

import hunt.stomp.converter.MessageConverter;
import hunt.stomp.converter.SmartMessageConverter;
import hunt.stomp.Message;
import hunt.stomp.MessageHeaders;

import hunt.collection;
import std.conv;


/**
 * A {@link MessageConverter} that delegates to a list of registered converters
 * to be invoked until one of them returns a non-null result.
 *
 * <p>As of 4.2.1, this composite converter implements {@link SmartMessageConverter}
 * in order to support the delegation of conversion hints.
 *
 * @author Rossen Stoyanchev
 * @author Juergen Hoeller
 * @since 4.0
 */
class CompositeMessageConverter : SmartMessageConverter {

	private MessageConverter[] converters;


	/**
	 * Create an instance with the given converters.
	 */
	this(MessageConverter[] converters) {
		assert(converters !is null, "Converters must not be empty");
		this.converters = converters;
	}


	override	
	Object fromMessage(MessageBase message, TypeInfo targetClass) {
		foreach (MessageConverter converter ; getConverters()) {
			Object result = converter.fromMessage(message, targetClass);
			if (result !is null) {
				return result;
			}
		}
		return null;
	}

	override
	Object fromMessage(MessageBase message, TypeInfo targetClass, TypeInfo conversionHint) {
		foreach (MessageConverter converter ; getConverters()) {
			auto smc = cast(SmartMessageConverter) converter;

			Object result = (smc is null ? converter.fromMessage(message, targetClass) :
				smc.fromMessage(message, targetClass, conversionHint));
			if (result !is null) {
				return result;
			}
		}
		return null;
	}

	override
	MessageBase toMessage(Object payload, MessageHeaders headers) {
		foreach (MessageConverter converter ; getConverters()) {
			MessageBase result = converter.toMessage(payload, headers);
			if (result !is null) {
				return result;
			}
		}
		return null;
	}

	override
	MessageBase toMessage(Object payload, MessageHeaders headers, TypeInfo conversionHint) {
		foreach (MessageConverter converter ; getConverters()) {
			auto smc = cast(SmartMessageConverter) converter;
			MessageBase result = (smc !is null ? smc.toMessage(payload, headers, conversionHint) :
					converter.toMessage(payload, headers));
			if (result !is null) {
				return result;
			}
		}
		return null;
	}


	/**
	 * Return the underlying list of delegate converters.
	 */
	MessageConverter[] getConverters() {
		return this.converters;
	}

	override
	string toString() {
		return "CompositeMessageConverter[converters=" ~ to!string(getConverters()) ~ "]";
	}

}
