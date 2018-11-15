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

module hunt.stomp.converter.ContentTypeResolver;

import hunt.stomp.MessageHeaders;
import hunt.util.MimeType;


/**
 * Resolve the content type for a message.
 *
 * @author Rossen Stoyanchev
 * @since 4.0
 */
// 
interface ContentTypeResolver {

	/**
	 * Determine the {@link MimeType} of a message from the given MessageHeaders.
	 * @param headers the headers to use for the resolution
	 * @return the resolved {@code MimeType}, or {@code null} if none found
	 * @throws InvalidMimeTypeException if the content type is a string that cannot be parsed
	 * @throws IllegalArgumentException if there is a content type but its type is unknown
	 */
	
	MimeType resolve(MessageHeaders headers);

}
