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

module hunt.stomp.support.NativeMessageHeaderAccessor;

import hunt.stomp.support.MessageHeaderAccessor;
import hunt.stomp.Message;

import hunt.collection;
import hunt.util.ObjectUtils;

// 
// import hunt.framework.util.CollectionUtils;
// import hunt.framework.util.LinkedMultiValueMap;
// import hunt.framework.util.MultiValueMap;
// import hunt.util.ObjectUtils;




/**
 * An extension of {@link MessageHeaderAccessor} that also stores and provides read/write
 * access to message headers from an external source -- e.g. a Spring {@link Message}
 * created to represent a STOMP message received from a STOMP client or message broker.
 * Native message headers are kept in a {@code MultiStringsMap} under the key
 * {@link #NATIVE_HEADERS}.
 *
 * <p>This class is not intended for direct use but is rather expected to be used
 * indirectly through protocol-specific sub-classes such as
 * {@link hunt.stomp.simp.stomp.StompHeaderAccessor StompHeaderAccessor}.
 * Such sub-classes may provide factory methods to translate message headers from
 * an external messaging source (e.g. STOMP) to Spring {@link Message} headers and
 * reversely to translate Spring {@link Message} headers to a message to send to an
 * external source.
 *
 * @author Rossen Stoyanchev
 * @since 4.0
 */
class NativeMessageHeaderAccessor : MessageHeaderAccessor {

	/**
	 * The header name used to store native headers.
	 */
	enum string NATIVE_HEADERS = "nativeHeaders";


	/**
	 * A protected constructor to create new headers.
	 */
	protected this() {
		this(cast(MultiStringsMap) null);
	}

	/**
	 * A protected constructor to create new headers.
	 * @param nativeHeaders native headers to create the message with (may be {@code null})
	 */
	protected this(MultiStringsMap nativeHeaders) {
		if (nativeHeaders !is null && nativeHeaders.size() > 0) {
			setHeader(NATIVE_HEADERS, new LinkedMultiValueMap!(string, string)(nativeHeaders));
		}
	}

	/**
	 * A protected constructor accepting the headers of an existing message to copy.
	 */
	protected this(MessageBase message) {
		super(message);
		if (message !is null) {
			
			MultiStringsMap map = cast(MultiStringsMap) getHeader(NATIVE_HEADERS);
			if (map !is null) {
				// Force removal since setHeader checks for equality
				removeHeader(NATIVE_HEADERS);
				setHeader(NATIVE_HEADERS, new LinkedMultiValueMap!(string, string)(map));
			}
		}
	}

	
	
	protected MultiStringsMap getNativeHeaders() {
		return cast(MultiStringsMap) getHeader(NATIVE_HEADERS);
	}

	/**
	 * Return a copy of the native header values or an empty map.
	 */
	MultiStringsMap toNativeHeaderMap() {
		MultiStringsMap map = getNativeHeaders();
		return (map !is null ? new LinkedMultiValueMap!(string, string)(map) : 
			Collections.emptyMap!(string, List!(string))());
	}

	override
	void setImmutable() {
		if (isMutable()) {
			MultiStringsMap map = getNativeHeaders();
			if (map !is null) {
				// Force removal since setHeader checks for equality
				removeHeader(NATIVE_HEADERS);
				setHeader(NATIVE_HEADERS, cast(Object)map);
				// setHeader(NATIVE_HEADERS, Collections.unmodifiableMap(map));
			}
			super.setImmutable();
		}
	}

	/**
	 * Whether the native header map contains the give header name.
	 */
	bool containsNativeHeader(string headerName) {
		MultiStringsMap map = getNativeHeaders();
		return (map !is null && map.containsKey(headerName));
	}

	/**
	 * Return all values for the specified native header.
	 * or {@code null} if none.
	 */
	
	List!(string) getNativeHeader(string headerName) {
		MultiStringsMap map = getNativeHeaders();
		return (map !is null ? map.get(headerName) : null);
	}

	/**
	 * Return the first value for the specified native header,
	 * or {@code null} if none.
	 */
	
	string getFirstNativeHeader(string headerName) {
		MultiStringsMap map = getNativeHeaders();
		if (map !is null) {
			List!(string) values = map.get(headerName);
			if (values !is null) {
				return values.get(0);
			}
		}
		return null;
	}

	/**
	 * Set the specified native header value replacing existing values.
	 */
	void setNativeHeader(string name, string value) {
		assert(isMutable(), "Already immutable");
		MultiStringsMap map = getNativeHeaders();
		if (value is null) {
			if (map !is null && map.get(name) !is null) {
				setModified(true);
				map.remove(name);
			}
			return;
		}
		if (map is null) {
			map = new LinkedMultiValueMap!(string, string)(4);
			setHeader(NATIVE_HEADERS, cast(Object)map);
		}
		List!(string) values = new LinkedList!(string)();
		values.add(value);
		if (!ObjectUtils.nullSafeEquals(cast(Object)values, getHeader(name))) {
			setModified(true);
			map.put(name, values);
		}
	}

	/**
	 * Add the specified native header value to existing values.
	 */
	void addNativeHeader(string name, string value) {
		assert(isMutable(), "Already immutable");
		if (value is null) {
			return;
		}
		MultiStringsMap nativeHeaders = getNativeHeaders();
		if (nativeHeaders is null) {
			nativeHeaders = new LinkedMultiValueMap!(string, string)(4);
			setHeader(NATIVE_HEADERS, cast(Object)nativeHeaders);
		}
		List!(string) values = nativeHeaders.computeIfAbsent(name, k => new LinkedList!(string)());
		values.add(value);
		setModified(true);
	}

	void addNativeHeaders(MultiValueMap!(string, string) headers) {
		if (headers is null) {
			return;
		}
        foreach(string key, List!(string) values; headers) {
            foreach(string value; values) {
                addNativeHeader(key, value);
            }
        }
	}

	
	List!(string) removeNativeHeader(string name) {
		assert(isMutable(), "Already immutable");
		MultiStringsMap nativeHeaders = getNativeHeaders();
		if (nativeHeaders is null) {
			return null;
		}
		return nativeHeaders.remove(name);
	}

	
	
	static string getFirstNativeHeader(string headerName, Map!(string, Object) headers) {
		MultiStringsMap map = cast(MultiStringsMap) headers.get(NATIVE_HEADERS);
		if (map !is null) {
			List!(string) values = map.get(headerName);
			if (values !is null) {
				return values.get(0);
			}
		}
		return null;
	}

}
