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
module hunt.stomp.simp.stomp.StompReactorNettyCodec;

// import java.nio.ByteBuffer;
// import java.util.List;

// import hunt.stomp.Message;
// import hunt.stomp.tcp.reactor.AbstractNioBufferReactorNettyCodec;

// /**
//  * Simple delegation to StompDecoder and StompEncoder.
//  *
//  * @author Rossen Stoyanchev
//  * @since 5.0
//  */
// public class StompReactorNettyCodec : AbstractNioBufferReactorNettyCodec!(byte[]) {

// 	private final StompDecoder decoder;

// 	private final StompEncoder encoder;


// 	public StompReactorNettyCodec() {
// 		this(new StompDecoder());
// 	}

// 	public StompReactorNettyCodec(StompDecoder decoder) {
// 		this(decoder, new StompEncoder());
// 	}

// 	public StompReactorNettyCodec(StompDecoder decoder, StompEncoder encoder) {
// 		this.decoder = decoder;
// 		this.encoder = encoder;
// 	}


// 	override
// 	protected List!(Message!(byte[])) decodeInternal(ByteBuffer nioBuffer) {
// 		return this.decoder.decode(nioBuffer);
// 	}

// 	protected ByteBuffer encodeInternal(Message!(byte[]) message) {
// 		return ByteBuffer.wrap(this.encoder.encode(message));
// 	}

// }
