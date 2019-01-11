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

module hunt.stomp.simp.stomp.StompDecoder;

import hunt.stomp.simp.stomp.StompHeaderAccessor;
import hunt.stomp.exception;
import hunt.stomp.Message;
import hunt.stomp.simp.stomp.StompCommand;
import hunt.stomp.simp.SimpMessageType;
import hunt.stomp.support.MessageHeaderAccessor;
import hunt.stomp.support.MessageBuilder;
import hunt.stomp.support.NativeMessageHeaderAccessor;

import hunt.collection;
import hunt.io.ByteArrayOutputStream;
import hunt.logging;
import hunt.Exceptions;
import hunt.Integer;
import hunt.Nullable;
import hunt.text.Common;
import hunt.text.StringBuilder;
import hunt.util.TypeUtils;

import std.conv;
import std.string;


/**
 * Decodes one or more STOMP frames contained in a {@link ByteBuffer}.
 *
 * <p>An attempt is made to read all complete STOMP frames from the buffer, which
 * could be zero, one, or more. If there is any left-over content, i.e. an incomplete
 * STOMP frame, at the end the buffer is reset to point to the beginning of the
 * partial content. The caller is then responsible for dealing with that
 * incomplete content by buffering until there is more input available.
 *
 * @author Andy Wilkinson
 * @author Rossen Stoyanchev
 * @since 4.0
 */
class StompDecoder {

	alias ByteMessage = Message!(byte[]);

	enum byte[] HEARTBEAT_PAYLOAD = ['\n'];

	private MessageHeaderInitializer headerInitializer;


	/**
	 * Configure a {@link MessageHeaderInitializer} to apply to the headers of
	 * {@link Message Messages} from decoded STOMP frames.
	 */
	void setHeaderInitializer(MessageHeaderInitializer headerInitializer) {
		this.headerInitializer = headerInitializer;
	}

	/**
	 * Return the configured {@code MessageHeaderInitializer}, if any.
	 */
	
	MessageHeaderInitializer getHeaderInitializer() {
		return this.headerInitializer;
	}


	/**
	 * Decodes one or more STOMP frames from the given {@code ByteBuffer} into a
	 * list of {@link Message Messages}. If the input buffer contains partial STOMP frame
	 * content, or additional content with a partial STOMP frame, the buffer is
	 * reset and {@code null} is returned.
	 * @param byteBuffer the buffer to decode the STOMP frame from
	 * @return the decoded messages, or an empty list if none
	 * @throws StompConversionException raised in case of decoding issues
	 */
	List!(ByteMessage) decode(ByteBuffer byteBuffer) {
		return decode(byteBuffer, null);
	}

	/**
	 * Decodes one or more STOMP frames from the given {@code buffer} and returns
	 * a list of {@link Message Messages}.
	 * <p>If the given ByteBuffer contains only partial STOMP frame content and no
	 * complete STOMP frames, an empty list is returned, and the buffer is reset to
	 * to where it was.
	 * <p>If the buffer contains one ore more STOMP frames, those are returned and
	 * the buffer reset to point to the beginning of the unused partial content.
	 * <p>The output partialMessageHeaders map is used to store successfully parsed
	 * headers in case of partial content. The caller can then check if a
	 * "content-length" header was read, which helps to determine how much more
	 * content is needed before the next attempt to decode.
	 * @param byteBuffer the buffer to decode the STOMP frame from
	 * @param partialMessageHeaders an empty output map that will store the last
	 * successfully parsed partialMessageHeaders in case of partial message content
	 * in cases where the partial buffer ended with a partial STOMP frame
	 * @return the decoded messages, or an empty list if none
	 * @throws StompConversionException raised in case of decoding issues
	 */
	List!(ByteMessage) decode(ByteBuffer byteBuffer,
			MultiStringsMap partialMessageHeaders) {
		
		version(HUNT_DEBUG) tracef("Decoding %s...", byteBuffer.toString());

		List!(ByteMessage) messages = new ArrayList!(ByteMessage)();
		while (byteBuffer.hasRemaining()) {
			ByteMessage message = decodeMessage(byteBuffer, partialMessageHeaders);
			if (message !is null) {
				version(HUNT_DEBUG) tracef("messages: %s", messages.toString());
				messages.add(message);
			} else {
				break;
			}
		}
		version(HUNT_DEBUG) tracef("Decoding done. Messages size: %d", messages.size());

		return messages;
	}

	/**
	 * Decode a single STOMP frame from the given {@code buffer} into a {@link Message}.
	 */
	
	private ByteMessage decodeMessage(ByteBuffer byteBuffer, MultiStringsMap headers) {

		version(HUNT_DEBUG) tracef("decoding buffer %s...", byteBuffer.toString());
			
		ByteMessage decodedMessage = null;
		skipLeadingEol(byteBuffer);

		// Explicit mark/reset access via Buffer base type for compatibility
		// with covariant return type on JDK 9's ByteBuffer...
		Buffer buffer = byteBuffer;
		buffer.mark();

		string command = readCommand(byteBuffer);
		version(HUNT_DEBUG) infof("command: %s", command);
		if (command.length > 0) {
			StompHeaderAccessor headerAccessor = null;
			Pair!(bool, byte[]) payload = makePair(false, cast(byte[])null);
			if (byteBuffer.remaining() > 0) {
				StompCommand stompCommand = StompCommand.valueOf(command);
				headerAccessor = StompHeaderAccessor.create(stompCommand);
				initHeaders(headerAccessor);
				readHeaders(byteBuffer, headerAccessor);
				payload = readPayload(byteBuffer, headerAccessor);
				version(HUNT_DEBUG) tracef("payload size(bytes): %d", payload.second.length);
			}

			if (payload.first) {
				byte[] payloadBuffer = payload.second;
				if (payloadBuffer.length > 0) {
					Nullable!StompCommand stompCommand = headerAccessor.getCommand();
					if (stompCommand !is null) {
						StompCommand cmd = stompCommand.value;
						if(!cmd.isBodyAllowed()) {
							string hs = "null";
							if(headers !is null) hs = headers.toString();
							throw new StompConversionException(stompCommand.toString() ~
									" shouldn't have a payload: length=" ~ 
									to!string(payloadBuffer.length) ~ ", headers=" ~ hs);
						}
					}
				}

				// if(headerAccessor !is null) {
					headerAccessor.updateSimpMessageHeadersFromStompHeaders();
					headerAccessor.setLeaveMutable(true);
					decodedMessage = cast(ByteMessage)MessageHelper.createMessage(payloadBuffer, headerAccessor.getMessageHeaders());
					version(HUNT_DEBUG) {
						trace("Decoded " ~ headerAccessor.getDetailedLogMessage(new Nullable!(byte[])(payloadBuffer)));
					}
				// } else {
				// 	version(HUNT_DEBUG) warning("Incomplete frame, resetting input buffer...");
				// 	buffer.reset();
				// }
			} else {
				version(HUNT_DEBUG) warning("Incomplete frame, resetting input buffer...");
				if (headers !is null && headerAccessor !is null) {
					string name = NativeMessageHeaderAccessor.NATIVE_HEADERS;
					
					MultiStringsMap map = cast(MultiStringsMap) headerAccessor.getHeader(name);
					if (map !is null) {
						headers.putAll(map);
					}
				}
				buffer.reset();
			}
		} else {
			StompHeaderAccessor headerAccessor = StompHeaderAccessor.createForHeartbeat();
			initHeaders(headerAccessor);
			headerAccessor.setLeaveMutable(true);
			decodedMessage = MessageHelper.createMessage(HEARTBEAT_PAYLOAD, headerAccessor.getMessageHeaders());
			version(HUNT_DEBUG) {
				trace("Decoded " ~ headerAccessor.getDetailedLogMessage(null));
			}
		}

		return decodedMessage;
	}

	private void initHeaders(StompHeaderAccessor headerAccessor) {
		MessageHeaderInitializer initializer = getHeaderInitializer();
		if (initializer !is null) {
			initializer.initHeaders(headerAccessor);
		}
	}

	/**
	 * Skip one ore more EOL characters at the start of the given ByteBuffer.
	 * Those are STOMP heartbeat frames.
	 */
	protected void skipLeadingEol(ByteBuffer byteBuffer) {
		while (true) {
			if (!tryConsumeEndOfLine(byteBuffer)) {
				break;
			}
		}
	}

	private string readCommand(ByteBuffer byteBuffer) {
		ByteArrayOutputStream command = new ByteArrayOutputStream(256);
		while (byteBuffer.remaining() > 0 && !tryConsumeEndOfLine(byteBuffer)) {
			command.write(byteBuffer.get());
		}
		return cast(string) (command.toByteArray());
	}

	private void readHeaders(ByteBuffer byteBuffer, StompHeaderAccessor headerAccessor) {
		while (true) {
			ByteArrayOutputStream headerStream = new ByteArrayOutputStream(256);
			bool headerComplete = false;
			while (byteBuffer.hasRemaining()) {
				if (tryConsumeEndOfLine(byteBuffer)) {
					headerComplete = true;
					break;
				}
				headerStream.write(byteBuffer.get());
			}
			if (headerStream.size() > 0 && headerComplete) {
				string header = cast(string)(headerStream.toByteArray());
				int colonIndex = cast(int)header.indexOf(":");
				if (colonIndex <= 0) {
					if (byteBuffer.remaining() > 0) {
						throw new StompConversionException("Illegal header: '" ~ header ~
								"'. A header must be of the form <name>:[<value>].");
					}
				}
				else {
					string headerName = unescape(header.substring(0, colonIndex));
					string headerValue = unescape(header.substring(colonIndex + 1));
					version(HUNT_DEBUG) tracef("header: name=%s, value=%s", headerName, headerValue);
					try {
						headerAccessor.addNativeHeader(headerName, headerValue);
					}
					catch (InvalidMimeTypeException ex) {
						if (byteBuffer.remaining() > 0) {
							throw ex;
						}
					}
				}
			}
			else {
				break;
			}
		}
	}

	/**
	 * See STOMP Spec 1.2:
	 * <a href="http://stomp.github.io/stomp-specification-1.2.html#Value_Encoding">"Value Encoding"</a>.
	 */
	private string unescape(string inString) {
		StringBuilder sb = new StringBuilder(inString.length);
		int pos = 0;  // position in the old string
		int index = cast(int)inString.indexOf("\\");

		while (index >= 0) {
			sb.append(inString.substring(pos, index));
			if (index + 1 >= inString.length) {
				throw new StompConversionException("Illegal escape sequence at index " ~ 
					index.to!string() ~ ": " ~ inString);
			}
			char c = inString[index + 1];
			if (c == 'r') {
				sb.append('\r');
			}
			else if (c == 'n') {
				sb.append('\n');
			}
			else if (c == 'c') {
				sb.append(':');
			}
			else if (c == '\\') {
				sb.append('\\');
			}
			else {
				// should never happen
				throw new StompConversionException("Illegal escape sequence at index " ~ 
					index.to!string() ~ ": " ~ inString);
			}
			pos = index + 2;
			index = cast(int)inString.indexOf("\\", pos);
		}

		sb.append(inString.substring(pos));
		return sb.toString();
	}

	
	private Pair!(bool, byte[]) readPayload(ByteBuffer byteBuffer, StompHeaderAccessor headerAccessor) {
		Integer contentLength;
		try {
			contentLength = headerAccessor.getContentLength();
		}
		catch (NumberFormatException ex) {
			version(HUNT_DEBUG) {
				trace("Ignoring invalid content-length: '" ~ headerAccessor.toString());
			}
			contentLength = null;
		}

		if (contentLength !is null && contentLength >= 0) {
			if (byteBuffer.remaining() > contentLength) {
				byte[] payload = new byte[contentLength.value];
				byteBuffer.get(payload);
				if (byteBuffer.get() != 0) {
					throw new StompConversionException("Frame must be terminated with a null octet");
				}
				return makePair(true, payload);
			}
			else {
				return makePair(false, cast(byte[])null); // null;
			}
		} else {
			ByteArrayOutputStream payload = new ByteArrayOutputStream(256);
			while (byteBuffer.remaining() > 0) {
				byte b = byteBuffer.get();
				if (b == 0) {
					return makePair(true, payload.toByteArray()); // payload.toByteArray();
				}
				else {
					payload.write(b);
				}
			}
		}
		return makePair(false, cast(byte[])null); // null;
	}

	/**
	 * Try to read an EOL incrementing the buffer position if successful.
	 * @return whether an EOL was consumed
	 */
	private bool tryConsumeEndOfLine(ByteBuffer byteBuffer) {
		if (byteBuffer.remaining() > 0) {
			byte b = byteBuffer.get();
			if (b == '\n') {
				return true;
			}
			else if (b == '\r') {
				if (byteBuffer.remaining() > 0 && byteBuffer.get() == '\n') {
					return true;
				}
				else {
					throw new StompConversionException("'\\r' must be followed by '\\n'");
				}
			}
			// Explicit cast for compatibility with covariant return type on JDK 9's ByteBuffer
			(cast(Buffer) byteBuffer).position(byteBuffer.position() - 1);
		}
		return false;
	}

}
