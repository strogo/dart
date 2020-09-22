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

import 'package:code_builder/code_builder.dart';
import 'package:dart_code_gen/src/immutable_type_factory.dart';
import 'package:dart_style/dart_style.dart';

import 'google/protobuf/descriptor.pb.dart';
import 'src/type.dart';

const String _generatedBySpine =
'''

// The code beneath is added by the Spine Dart code generation tool.
// Please do not edit this manually.

''';

const _BUILT_VALUE = 'package:built_value/built_value.dart';

String renameClasses(String generatedCode, String fileName, FileDescriptorSet descriptors) {
    var file = descriptors.file.firstWhere(
            (file) => file.name == fileName,
            orElse: () => throw Exception('File `$fileName` is not in the descriptor set.')
    );
    var types = TypeSet.fromFile(file);
    for (var type in types.messageTypes) {
        var pattern = RegExp('\b${type.dartClassName}\b');
        generatedCode.replaceAll(pattern, type.dartMutableClassName);
    }
    return generatedCode;
}

List<PrebuiltFile> generate(FileDescriptorSet descriptors) {
    var files = List<PrebuiltFile>();
    var knownTypes = TypeSet.of(descriptors);
    var substitutions = Map<String, String>();
    for (MessageType type in knownTypes.messageTypes) {
        substitutions[type.dartClassName] = type.dartMutableClassName;
    }
    for (var file in descriptors.file) {
        var types = TypeSet.fromFile(file).messageTypes;
        if (types.isNotEmpty) {
            var classes = types.map((t) => _generate(t, knownTypes));
            var library = Library((lib) {
                lib.directives
                    ..add(Directive.import(_BUILT_VALUE))
                    ..add(Directive.part('${types.first.fileNameNoExtension}.pb.g.dart'));
                lib.body.addAll(classes);
            });
            var content = _generatedBySpine + _emit(library);
            files.add(PrebuiltFile(types.first.dartFilePath, content, substitutions));
        }
    }
    return files;
}

String _emit(Library lib) {
    var emitter = DartEmitter(Allocator.simplePrefixing());
    var formatter = DartFormatter();
    var code = lib.accept(emitter).toString();
    var content = formatter.format(code);
    return content;
}

Class _generate(MessageType type, TypeSet knownTypes) {
    var factory = ImmutableTypeFactory(type, knownTypes);
    var cls = factory.generate();
    return cls;
}

class PrebuiltFile {

    final String name;
    final String additions;
    final Map<String, String> substitutions;

    PrebuiltFile(this.name, this.additions, this.substitutions);
}
