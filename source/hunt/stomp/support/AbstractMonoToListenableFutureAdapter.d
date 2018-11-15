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

module hunt.stomp.support.AbstractMonoToListenableFutureAdapter;

// import java.time.Duration;
// import java.util.concurrent.ExecutionException;
// import java.util.concurrent.TimeUnit;
// import java.util.concurrent.TimeoutException;

// import reactor.core.publisher.Mono;
// import reactor.core.publisher.MonoProcessor;


// 
// import hunt.framework.util.concurrent.FailureCallback;
// import hunt.framework.util.concurrent.ListenableFuture;
// import hunt.framework.util.concurrent.ListenableFutureCallback;
// import hunt.framework.util.concurrent.ListenableFutureCallbackRegistry;
// import hunt.framework.util.concurrent.SuccessCallback;

// /**
//  * Adapts {@link Mono} to {@link ListenableFuture} optionally converting the
//  * result Object type {@code <S>} to the expected target type {@code !(T)}.
//  *
//  * @author Rossen Stoyanchev
//  * @since 5.0
//  * @param <S> the type of object expected from the {@link Mono}
//  * @param (T) the type of object expected from the {@link ListenableFuture}
//  */
// abstract class AbstractMonoToListenableFutureAdapter!(S, T) implements ListenableFuture!(T) {

// 	private final MonoProcessor!(S) monoProcessor;

// 	private final ListenableFutureCallbackRegistry!(T) registry = new ListenableFutureCallbackRegistry<>();


// 	protected AbstractMonoToListenableFutureAdapter(Mono!(S) mono) {
// 		assert(mono, "Mono must not be null");
// 		this.monoProcessor = mono
// 				.doOnSuccess(result -> {
// 					T adapted;
// 					try {
// 						adapted = adapt(result);
// 					}
// 					catch (Throwable ex) {
// 						this.registry.failure(ex);
// 						return;
// 					}
// 					this.registry.success(adapted);
// 				})
// 				.doOnError(this.registry::failure)
// 				.toProcessor();
// 	}


// 	override
	
// 	public T get() throws InterruptedException {
// 		S result = this.monoProcessor.block();
// 		return adapt(result);
// 	}

// 	override
	
// 	public T get(long timeout, TimeUnit unit) throws InterruptedException, ExecutionException, TimeoutException {
// 		assert(unit, "TimeUnit must not be null");
// 		Duration duration = Duration.ofMillis(TimeUnit.MILLISECONDS.convert(timeout, unit));
// 		S result = this.monoProcessor.block(duration);
// 		return adapt(result);
// 	}

// 	override
// 	bool cancel( mayInterruptIfRunning) {
// 		if (isCancelled()) {
// 			return false;
// 		}
// 		this.monoProcessor.cancel();
// 		return true;
// 	}

// 	override
// 	bool isCancelled() {
// 		return this.monoProcessor.isCancelled();
// 	}

// 	override
// 	bool isDone() {
// 		return this.monoProcessor.isTerminated();
// 	}

// 	override
// 	public void addCallback(ListenableFutureCallback<? super T> callback) {
// 		this.registry.addCallback(callback);
// 	}

// 	override
// 	public void addCallback(SuccessCallback<? super T> successCallback, FailureCallback failureCallback) {
// 		this.registry.addSuccessCallback(successCallback);
// 		this.registry.addFailureCallback(failureCallback);
// 	}


	
// 	protected abstract T adapt(S result);

// }
