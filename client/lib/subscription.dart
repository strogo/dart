/*
 * Copyright 2021, TeamDev. All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Redistribution and use in source and/or binary forms, with or without
 * modification, must retain the above copyright notice and the following
 * disclaimer.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import 'dart:async';

import 'package:protobuf/protobuf.dart';
import 'package:spine_client/firebase_client.dart';
import 'package:spine_client/spine/client/subscription.pb.dart' as pb;
import 'package:spine_client/spine/core/event.pb.dart';
import 'package:spine_client/spine/web/firebase/subscription/firebase_subscription.pb.dart';
import 'package:spine_client/src/any_packer.dart';
import 'package:spine_client/src/json.dart';

/// A subscription to updates from server.
class Subscription<T extends GeneratedMessage> {

    /// A future for the subscription message.
    ///
    /// Completes when the subscription is created.
    ///
    final Future<pb.Subscription> subscription;

    final Stream<T> _itemAdded;

    bool _closed;

    Subscription._(this.subscription, Stream<T> itemAdded)
        : _itemAdded = _checkBroadcast(itemAdded),
          _closed = false {
        subscription.catchError((e) => unsubscribe());
    }

    /// Shows if this subscription is still active or already closed.
    bool get closed => _closed;

    /// Closes this subscription.
    ///
    /// The server will stop reflecting the updates for the topic.
    ///
    void unsubscribe() {
        _closed = true;
    }
}

/// A subscription for entity state changes.
///
/// The [itemAdded], [itemChanged] and [itemRemoved] streams reflect the changes of a corresponding
/// entity type.
///
/// To stop receiving updates from the server, invoke [unsubscribe]. This will cancel the
/// subscription both on the client and on the server, stopping the changes from being reflected to
/// Firebase.
///
class StateSubscription<T extends GeneratedMessage> extends Subscription<T> {

    final Stream<T> itemChanged;
    final Stream<T> itemRemoved;

    Stream<T> get itemAdded => _itemAdded;

    bool _closed;

    StateSubscription._(Future<pb.Subscription> subscription,
                        Stream<T> itemAdded,
                        Stream<T> itemChanged,
                        Stream<T> itemRemoved):
            itemChanged = _checkBroadcast(itemChanged),
            itemRemoved = _checkBroadcast(itemRemoved),
            _closed = false,
            super._(subscription, itemAdded);

    /// Creates a new instance which broadcasts updates from under the given Firebase node.
    factory StateSubscription.of(Future<FirebaseSubscription> firebaseSubscription,
                                 BuilderInfo builderInfoForType,
                                 FirebaseClient database) {
        var subscription = firebaseSubscription.then((value) => value.subscription);
        var nodePath = _nodePath(firebaseSubscription);
        var itemAdded = _nodePathStream(nodePath)
            .asyncExpand((element) => database.childAdded(element))
            .map((json) => parseIntoNewInstance<T>(builderInfoForType, json));
        var itemChanged = _nodePathStream(nodePath)
            .asyncExpand((element) => database.childChanged(element))
            .map((json) => parseIntoNewInstance<T>(builderInfoForType, json));
        var itemRemoved = _nodePathStream(nodePath)
            .asyncExpand((element) => database.childRemoved(element))
            .map((json) => parseIntoNewInstance<T>(builderInfoForType, json));
        return StateSubscription._(subscription, itemAdded, itemChanged, itemRemoved);
    }
}

/// A subscription for events.
///
/// To consume unpacked typed event messages, use [eventMessages]. To use events with metadata,
/// use [events].
///
/// To stop receiving updates from the server, invoke [unsubscribe]. This will cancel the
/// subscription both on the client and on the server, stopping the changes from being reflected to
/// Firebase.
///
class EventSubscription<T extends GeneratedMessage> extends Subscription<Event> {

    static final BuilderInfo _eventBuilderInfo = Event.getDefault().info_;

    EventSubscription._(Future<pb.Subscription> subscription, Stream<Event> itemAdded) :
            super._(subscription, itemAdded);

    factory EventSubscription.of(Future<FirebaseSubscription> firebaseSubscription,
                                 FirebaseClient database) {
        var subscription = firebaseSubscription.then((value) => value.subscription);
        var itemAdded = _nodePathStream(_nodePath(firebaseSubscription))
            .asyncExpand((path) => database.childAdded(path))
            .map((json) => parseIntoNewInstance<Event>(_eventBuilderInfo, json));
        return EventSubscription._(subscription, itemAdded);
    }

    /// A stream of events along with their metadata, such as `EventContext`s.
    Stream<Event> get events => _itemAdded;

    /// A stream of typed event messages.
    Stream<T> get eventMessages => events
        .map((event) => unpack(event.message));
}

Future<String> _nodePath(Future<FirebaseSubscription> subscription) =>
    subscription
        .then((value) => value.nodePath.value);

Stream<String> _nodePathStream(Future<String> futureValue) =>
    futureValue.asStream().asBroadcastStream();


Stream<T> _checkBroadcast<T>(Stream<T> stream) {
    if (!stream.isBroadcast) {
        throw ArgumentError(
            'All streams passed to an `Subscription` instance should be broadcast.'
        );
    }
    return stream;
}
