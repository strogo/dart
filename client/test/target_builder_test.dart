/*
 * Copyright 2020, TeamDev. All rights reserved.
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

import 'package:spine_client/src/known_types.dart';
import 'package:spine_client/target_builder.dart';
import 'package:test/test.dart';

import 'google/protobuf/empty.pb.dart';
import 'google/protobuf/timestamp.pb.dart';
import 'types.dart' as types;

void main() {
    group('Target builder should', () {

        setUpAll(() {
            theKnownTypes.register(types.types());
        });

        test('build "all" targets', () {
            var target = targetAll(Empty.getDefault());
            expect(target, isNotNull);
            expect(target.type, equals('type.googleapis.com/google.protobuf.Empty'));
            expect(target.includeAll, equals(true));
        });

        test('convert raw IDs to Any', () {
            var ids = [42, 314, 271];
            var target = targetByIds(Timestamp.getDefault(), ids);
            expect(target, isNotNull);
            expect(target.type, equals('type.googleapis.com/google.protobuf.Timestamp'));
            expect(target.filters.idFilter.id, hasLength(equals(ids.length)));
        });

        test('not allow generic IDs', () {
            var ids = [StringBuffer().writeln('this is not allowed')];
            expect(() => targetByIds(Empty.getDefault(), ids), throwsA(isA<ArgumentError>()));
        });
    });
}
