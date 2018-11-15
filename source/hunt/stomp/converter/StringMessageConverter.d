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

module hunt.stomp.converter.StringMessageConverter;

import hunt.stomp.converter.AbstractMessageConverter;
import hunt.stomp.Message;
import hunt.stomp.MessageHeaders;

import hunt.util.MimeType;

import hunt.lang.Charset;
import hunt.lang.exception;
import hunt.logging;

/**
 * A {@link MessageConverter} that supports MIME type "text/plain" with the
 * payload converted to and from a string.
 *
 * @author Rossen Stoyanchev
 * @since 4.0
 */
class StringMessageConverter : AbstractMessageConverter {

	private Charset defaultCharset;


	this() {
		this(StandardCharsets.UTF_8);
	}

	this(Charset defaultCharset) {
		super(new MimeType("text/plain", defaultCharset));
		assert(defaultCharset !is null, "Default Charset must not be null");
		this.defaultCharset = defaultCharset;
	}


	override
	protected bool supports(TypeInfo typeInfo) {
		// version(HUNT_DEBUG) tracef("checking message type, expected: %s, actual: %s", 
		// 	typeid(string), typeInfo);
		return (typeid(string) == typeInfo);
	}

	// override
	// protected Object convertFromInternal(MessageBase message, Class<?> targetClass, Object conversionHint) {
	// 	Charset charset = getContentTypeCharset(getMimeType(message.getHeaders()));
	// 	Object payload = message.getPayload();
	// 	return (payload instanceof string ? payload : new string((byte[]) payload, charset));
	// }

	// override
	// protected Object convertToInternal(
	// 		Object payload, MessageHeaders headers, Object conversionHint) {

	// 	// trace("xxxxxx=>", typeid(payload));
	// 	// TypeInfo rawType = cast(TypeInfo)conversionHint;

	// 	// if (byte[].class == getSerializedPayloadClass()) {
	// 	// 	Charset charset = getContentTypeCharset(getMimeType(headers));
	// 	// 	payload = ((string) payload).getBytes(charset);
	// 	// }
	// 	return payload;
	// }

	// private Charset getContentTypeCharset(MimeType mimeType) {
	// 	if (mimeType !is null && mimeType.getCharset() !is null) {
	// 		return mimeType.getCharset();
	// 	}
	// 	else {
	// 		return this.defaultCharset;
	// 	}
	// }

}
