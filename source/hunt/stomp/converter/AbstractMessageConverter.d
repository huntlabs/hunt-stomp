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

module hunt.stomp.converter.AbstractMessageConverter;

import hunt.stomp.converter.ContentTypeResolver;
import hunt.stomp.converter.DefaultContentTypeResolver;
import hunt.stomp.converter.SmartMessageConverter;
import hunt.stomp.Message;
import hunt.stomp.MessageHeaders;
import hunt.stomp.support.GenericMessage;
import hunt.stomp.support.MessageBuilder;
import hunt.stomp.support.MessageHeaderAccessor;


import hunt.collection;
import hunt.util.MimeType;
import hunt.Exceptions;
import hunt.Nullable;
import hunt.logging;
import hunt.util.TypeUtils;

import std.array;


/**
 * Abstract base class for {@link SmartMessageConverter} implementations including
 * support for common properties and a partial implementation of the conversion methods,
 * mainly to check if the converter supports the conversion based on the payload class
 * and MIME type.
 *
 * @author Rossen Stoyanchev
 * @author Sebastien Deleuze
 * @author Juergen Hoeller
 * @since 4.0
 */
abstract class AbstractMessageConverter : SmartMessageConverter {

	private MimeType[] supportedMimeTypes;

	private ContentTypeResolver contentTypeResolver;

	private bool strictContentTypeMatch = false;

	// private Class<?> serializedPayloadClass = byte[].class;


	/**
	 * Construct an {@code AbstractMessageConverter} supporting a single MIME type.
	 * @param supportedMimeType the supported MIME type
	 */
	protected this(MimeType supportedMimeType) {
		assert(supportedMimeType, "supportedMimeType is required");
		this.supportedMimeTypes = [supportedMimeType];
		contentTypeResolver = new DefaultContentTypeResolver();
	}

	/**
	 * Construct an {@code AbstractMessageConverter} supporting multiple MIME types.
	 * @param supportedMimeTypes the supported MIME types
	 */
	protected this(MimeType[] supportedMimeTypes) {
		assert(supportedMimeTypes.length>0, "supportedMimeTypes must not be null");
		this.supportedMimeTypes = supportedMimeTypes;
		contentTypeResolver = new DefaultContentTypeResolver();
	}


	/**
	 * Return the supported MIME types.
	 */
	MimeType[] getSupportedMimeTypes() {
		return this.supportedMimeTypes;
	}

	/**
	 * Configure the {@link ContentTypeResolver} to use to resolve the content
	 * type of an input message.
	 * <p>Note that if no resolver is configured, then
	 * {@link #setStrictContentTypeMatch() strictContentTypeMatch} should
	 * be left as {@code false} (the default) or otherwise this converter will
	 * ignore all messages.
	 * <p>By default, a {@code DefaultContentTypeResolver} instance is used.
	 */
	void setContentTypeResolver(ContentTypeResolver resolver) {
		this.contentTypeResolver = resolver;
	}

	/**
	 * Return the configured {@link ContentTypeResolver}.
	 */
	
	ContentTypeResolver getContentTypeResolver() {
		return this.contentTypeResolver;
	}

	/**
	 * Whether this converter should convert messages for which no content type
	 * could be resolved through the configured
	 * {@link hunt.stomp.converter.ContentTypeResolver}.
	 * <p>A converter can configured to be strict only when a
	 * {@link #setContentTypeResolver contentTypeResolver} is configured and the
	 * list of {@link #getSupportedMimeTypes() supportedMimeTypes} is not be empty.
	 * <p>When this flag is set to {@code true}, {@link #supportsMimeType(MessageHeaders)}
	 * will return {@code false} if the {@link #setContentTypeResolver contentTypeResolver}
	 * is not defined or if no content-type header is present.
	 */
	void setStrictContentTypeMatch(bool strictContentTypeMatch) {
		if (strictContentTypeMatch) {
			// assert(getSupportedMimeTypes(), "Strict match requires non-empty list of supported mime types");
			// assert(getContentTypeResolver(), "Strict match requires ContentTypeResolver");
		}
		this.strictContentTypeMatch = strictContentTypeMatch;
	}

	/**
	 * Whether content type resolution must produce a value that matches one of
	 * the supported MIME types.
	 */
	bool isStrictContentTypeMatch() {
		return this.strictContentTypeMatch;
	}


	/**
	 * Returns the default content type for the payload. Called when
	 * {@link #toMessage(Object, MessageHeaders)} is invoked without message headers or
	 * without a content type header.
	 * <p>By default, this returns the first element of the {@link #getSupportedMimeTypes()
	 * supportedMimeTypes}, if any. Can be overridden in sub-classes.
	 * @param payload the payload being converted to message
	 * @return the content type, or {@code null} if not known
	 */	
	protected MimeType getDefaultContentType(Object payload) {
		MimeType[] mimeTypes = getSupportedMimeTypes();
		return (mimeTypes.length >0 ? mimeTypes[0] : null);
	}

	final Object fromMessage(MessageBase message, TypeInfo targetClass) {
		return fromMessage(message, targetClass, null);
	}

	final Object fromMessage(MessageBase message, TypeInfo targetClass, TypeInfo conversionHint) {
		if (!canConvertFrom(message, targetClass)) {
			return null;
		}
		return convertFromInternal(message, targetClass, conversionHint);
	}

	protected bool canConvertFrom(MessageBase message, TypeInfo targetClass) {
		bool r = (supports(targetClass) && supportsMimeType(message.getHeaders()));
		version(HUNT_DEBUG) tracef("checking message, target: %s, converter: %s, result: %s", 
			targetClass, TypeUtils.getSimpleName(typeid(this)), r);
		return r;
	}

	override	
	final MessageBase toMessage(Object payload, MessageHeaders headers) {
		return toMessage(payload, headers, null);
	}

	override
	final MessageBase toMessage(Object payload, MessageHeaders headers, TypeInfo conversionHint) {
		version(HUNT_DEBUG) trace("converting message...");
		if (!canConvertTo(payload, headers, conversionHint)) {
			version(HUNT_DEBUG) warning("A message can't be converted.");
			return null;
		}
		
		version(HUNT_DEBUG) {
			if(conversionHint !is null)
				tracef("conversionHint: %s", conversionHint);
		}

		Object payloadToUse = convertToInternal(payload, headers, conversionHint);
		if (payloadToUse is null) {
			warningf("Can't convert payload: %s", typeid((cast(Object)payload)));
			return null;
		}

		MimeType mimeType = getDefaultContentType(payloadToUse);
		if (headers !is null) {
			MessageHeaderAccessor accessor = MessageHeaderAccessor.getAccessor!(MessageHeaderAccessor)(headers);
			if (accessor !is null && accessor.isMutable()) {
				if (mimeType !is null) {
					accessor.setHeaderIfAbsent(MessageHeaders.CONTENT_TYPE, mimeType);
				}

				if(conversionHint == typeid(TypeInfo_Class) || conversionHint == typeid(TypeInfo_Interface))
					return MessageHelper.createMessage!(Object)(payloadToUse, accessor.getMessageHeaders());
				else {
					INullable t = cast(INullable)payloadToUse;
					if(t is null)  {
						warningf("Can't handle: %s", typeid((cast(Object)payloadToUse)));
						return null;
					} else {
						// TODO: Tasks pending completion -@zxp at 11/12/2018, 3:02:11 PM
						// handle payload of byte[]
						return new GenericMessage!(string)(payloadToUse.toString(), 
							accessor.getMessageHeaders());
					}
				}
			}
		}

		if(conversionHint == typeid(TypeInfo_Class) || conversionHint == typeid(TypeInfo_Interface)) {
			MessageBuilder!Object builder = MessageHelper.withPayload(payloadToUse);
			if (headers !is null) {
				builder.copyHeaders(headers);
			}
			if (mimeType !is null) {
				builder.setHeaderIfAbsent(MessageHeaders.CONTENT_TYPE, mimeType);
			}
			return builder.build();
		} else {
			INullable t = cast(INullable)payloadToUse;
			if(t is null)  {
				warningf("Can't handle: %s", typeid((cast(Object)payloadToUse)));
				return null;
			} else {
				// TODO: Tasks pending completion -@zxp at 11/12/2018, 3:02:11 PM
				// handle payload of byte[]
				// MessageBuilder!(byte[]) builder = 
				// 	MessageHelper.withPayload!(byte[])(cast(byte[])payloadToUse.toString());
				MessageBuilder!(string) builder = 
					MessageHelper.withPayload!(string)(payloadToUse.toString());
				if (headers !is null) {
					builder.copyHeaders(headers);
				}
				if (mimeType !is null) {
					builder.setHeaderIfAbsent(MessageHeaders.CONTENT_TYPE, mimeType);
				}
				return builder.build();
			}
		}

	}

	protected bool canConvertTo(Object payload, MessageHeaders headers, TypeInfo conversionHint) {
		bool r = false;
		if(conversionHint !is null) {
			r = (supports(conversionHint) && supportsMimeType(headers));
			version(HUNT_DEBUG) tracef("checking payload, type: %s, converter: %s, result: %s", 
				conversionHint, TypeUtils.getSimpleName(typeid(this)), r);
		} else {
			r = (supports(typeid(payload)) && supportsMimeType(headers));
			version(HUNT_DEBUG) tracef("checking payload, type: %s, converter: %s, result: %s", 
				typeid(payload), TypeUtils.getSimpleName(typeid(this)), r);
		}
		return r;
	}

	protected bool supportsMimeType(MessageHeaders headers) {
		if (getSupportedMimeTypes().empty()) {
			return true;
		}
		MimeType mimeType = getMimeType(headers);
		if (mimeType is null) {
			return !isStrictContentTypeMatch();
		}
		MimeType mimeTypeBaseType = mimeType.getBaseType();
		string mimeTypeName = mimeTypeBaseType.asString();

		foreach (MimeType current ; getSupportedMimeTypes()) {
			MimeType currentBaseType = current.getBaseType();
			if(currentBaseType.isSame(mimeTypeName))
				return true;
		}
		return false;
	}

	
	protected MimeType getMimeType(MessageHeaders headers) {
		return (headers !is null && this.contentTypeResolver !is null ? 
			this.contentTypeResolver.resolve(headers) : null);
	}


	/**
	 * Whether the given class is supported by this converter.
	 * @param clazz the class to test for support
	 * @return {@code true} if supported; {@code false} otherwise
	 */
	protected abstract bool supports(TypeInfo typeInfo);

	/**
	 * Convert the message payload from serialized form to an Object.
	 * @param message the input message
	 * @param targetClass the target class for the conversion
	 * @param conversionHint an extra object passed to the {@link MessageConverter},
	 * e.g. the associated {@code MethodParameter} (may be {@code null}}
	 * @return the result of the conversion, or {@code null} if the converter cannot
	 * perform the conversion
	 * @since 4.2
	 */
	
	protected Object convertFromInternal(
			MessageBase message, TypeInfo targetClass, TypeInfo conversionHint) {
		
		auto m = cast(GenericMessage!(byte[]))message;
		if(targetClass == typeid(string)) {
			return new Nullable!string(cast(string) m.getPayload());
		} else {
            warningf("Can't handle message for type: %s", targetClass);
        }

		return null;
	}

	/**
	 * Convert the payload object to serialized form.
	 * @param payload the Object to convert
	 * @param headers optional headers for the message (may be {@code null})
	 * @param conversionHint an extra object passed to the {@link MessageConverter},
	 * e.g. the associated {@code MethodParameter} (may be {@code null}}
	 * @return the resulting payload for the message, or {@code null} if the converter
	 * cannot perform the conversion
	 * @since 4.2
	 */
	
	protected Object convertToInternal(
			Object payload, MessageHeaders headers, TypeInfo conversionHint) {
				
		return payload;
	}

}
