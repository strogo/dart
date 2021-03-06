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

import 'package:code_builder/code_builder.dart';
import 'package:dart_code_gen/spine/options.pb.dart';
import 'package:dart_code_gen/src/type.dart';

import 'constraint_violation.dart';
import 'field_validator_factory.dart';
import 'validator_factory.dart';

/// A [FieldValidatorFactory] for `string` fields.
///
/// The only supported options is `(required)` and `(pattern)`.
///
class StringValidatorFactory extends SingularFieldValidatorFactory {

    StringValidatorFactory(ValidatorFactory validatorFactory, FieldDeclaration field)
        : super(validatorFactory, field);

    @override
    Iterable<Rule> rules() {
        var rules = <Rule>[];
        if (isRequired()) {
            rules.add(createRequiredRule());
        }
        field.findOption(Options.pattern).ifPresent((val) {
            Rule rule = _patternRule(val);
            rules.add(rule);
        });
        return rules;
    }

    @override
    LazyCondition notSetCondition() => (v) => v.property('isEmpty');

    /// Creates a validation rule which matches a string upon a regular expression.
    ///
    /// The whole string must match the regex. To check that, the generated code applies
    /// the `RegExp` to the string and compares the first match to the value of the initial string.
    /// If the values are identical, the check passes.
    ///
    Rule _patternRule(PatternOption pattern) {
        var rule = newRule((v) => refer('RegExp')
            .newInstance([literalString(pattern.regex, raw: true)])
            .property('stringMatch')
            .call([v])
            .notEqualTo(v),
                           (v) => _patternMismatch(pattern));
        return rule;
    }

    Expression _patternMismatch(PatternOption pattern) {
        var msgFormat = pattern.msgFormat;
        var message = msgFormat.isEmpty
            ? 'The string must match the regular expression `%s`.'
            : msgFormat;
        return violationRef.call([
                literalString(message),
                literalString(validatorFactory.fullTypeName),
                literalList([field.protoName])
            ], {paramsArg: literalList([literalString(pattern.regex, raw: true)])}
        );
  }
}
