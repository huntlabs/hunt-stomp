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

module hunt.stomp.support.ImmutableMessageChannelInterceptor;

import hunt.stomp.support.ChannelInterceptor;
import hunt.stomp.support.MessageHeaderAccessor;

import hunt.stomp.Message;
import hunt.stomp.MessageChannel;

/**
 * A simpler interceptor that calls {@link MessageHeaderAccessor#setImmutable()}
 * on the headers of messages passed through the preSend method.
 *
 * <p>When configured as the last interceptor in a chain, it allows the component
 * sending the message to leave headers mutable for interceptors to modify prior
 * to the message actually being sent and exposed to concurrent access.
 *
 * @author Rossen Stoyanchev
 * @since 4.1.2
 */
class ImmutableMessageChannelInterceptor : ChannelInterceptor {

	override
	MessageBase preSend(MessageBase message, MessageChannel channel) {
		MessageHeaderAccessor accessor = MessageHeaderAccessor.getAccessor!(MessageHeaderAccessor)(message);
		if (accessor !is null && accessor.isMutable()) {
			accessor.setImmutable();
		}
		return message;
	}

}
