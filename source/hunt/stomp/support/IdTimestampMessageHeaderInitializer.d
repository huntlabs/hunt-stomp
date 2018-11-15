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

module hunt.stomp.support.IdTimestampMessageHeaderInitializer;

import hunt.stomp.support.MessageHeaderAccessor;

import hunt.stomp.IdGenerator;
import hunt.stomp.MessageHeaders;

import std.uuid;

/**
 * A {@link hunt.stomp.support.MessageHeaderInitializer MessageHeaderInitializer}
 * to customize the strategy for ID and TIMESTAMP message header generation.
 *
 * @author Rossen Stoyanchev
 * @since 4.1
 */
class IdTimestampMessageHeaderInitializer : MessageHeaderInitializer {

	private __gshared IdGenerator ID_VALUE_NONE_GENERATOR;

	shared static this() {
		ID_VALUE_NONE_GENERATOR = new class IdGenerator {
			UUID generateId() {
				return MessageHeaders.ID_VALUE_NONE;
			}
		};
	}
	
	private IdGenerator idGenerator;

	private bool enableTimestamp;

	/**
	 * Configure the IdGenerator strategy to initialize {@code MessageHeaderAccessor}
	 * instances with.
	 * <p>By default this property is set to {@code null} in which case the default
	 * IdGenerator of {@link hunt.stomp.MessageHeaders} is used.
	 * <p>To have no ids generated at all, see {@link #setDisableIdGeneration()}.
	 */
	public void setIdGenerator(IdGenerator idGenerator) {
		this.idGenerator = idGenerator;
	}

	/**
	 * Return the configured {@code IdGenerator}, if any.
	 */
	
	public IdGenerator getIdGenerator() {
		return this.idGenerator;
	}

	/**
	 * A shortcut for calling {@link #setIdGenerator} with an id generation strategy
	 * to disable id generation completely.
	 */
	public void setDisableIdGeneration() {
		this.idGenerator = ID_VALUE_NONE_GENERATOR;
	}

	/**
	 * Whether to enable the automatic addition of the
	 * {@link hunt.stomp.MessageHeaders#TIMESTAMP} header on
	 * {@code MessageHeaderAccessor} instances being initialized.
	 * <p>By default this property is set to false.
	 */
	public void setEnableTimestamp(bool enableTimestamp) {
		this.enableTimestamp = enableTimestamp;
	}

	/**
	 * Return whether the timestamp header is enabled or not.
	 */
	public bool isEnableTimestamp() {
		return this.enableTimestamp;
	}


	override
	public void initHeaders(MessageHeaderAccessor headerAccessor) {
		IdGenerator idGenerator = getIdGenerator();
		if (idGenerator !is null) {
			headerAccessor.setIdGenerator(idGenerator);
		}
		headerAccessor.setEnableTimestamp(isEnableTimestamp());
	}

}
