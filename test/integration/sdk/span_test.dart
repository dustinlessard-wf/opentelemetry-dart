import 'package:opentelemetry/src/api/trace/span_status.dart';
import 'package:mockito/mockito.dart';
import 'package:opentelemetry/src/sdk/trace/span.dart';
import 'package:opentelemetry/src/sdk/trace/span_context.dart';
import 'package:opentelemetry/src/sdk/trace/trace_state.dart';
import 'package:opentelemetry/src/sdk/trace/tracer.dart';
import 'package:test/test.dart';

import '../../unit/mocks.dart';

void main() {
  test('span set and end time', () {
    final mockProcessor1 = MockSpanProcessor();
    final mockProcessor2 = MockSpanProcessor();
    final span = Span('foo', SpanContext([1, 2, 3], [7, 8, 9], TraceState()),
        [4, 5, 6], [mockProcessor1, mockProcessor2], Tracer('bar', []));

    expect(span.startTime, isNotNull);
    expect(span.endTime, isNull);
    expect(span.parentSpanId, [4, 5, 6]);
    expect(span.name, 'foo');

    verify(mockProcessor1.onStart()).called(1);
    verify(mockProcessor2.onStart()).called(1);
    verifyNever(mockProcessor1.onEnd(span));
    verifyNever(mockProcessor2.onEnd(span));

    span.end();
    expect(span.startTime, isNotNull);
    expect(span.endTime, isNotNull);
    expect(span.endTime, greaterThan(span.startTime));

    verify(mockProcessor1.onEnd(span)).called(1);
    verify(mockProcessor2.onEnd(span)).called(1);
  });

  test('span status', () {
    final span = Span('foo', SpanContext([1, 2, 3], [7, 8, 9], TraceState()),
        [4, 5, 6], [], Tracer('bar', []));

    // Verify span status' defaults.
    expect(span.status.code, equals(StatusCode.UNSET));
    expect(span.status.description, equals(null));

    // Verify that span status can be set to "Error".
    span.setStatus(StatusCode.ERROR, description: 'Something s\'ploded.');
    expect(span.status.code, equals(StatusCode.ERROR));
    expect(span.status.description, equals('Something s\'ploded.'));

    // Verify that multiple errors update the span to the most recently set.
    span.setStatus(StatusCode.ERROR, description: 'Another error happened.');
    expect(span.status.code, equals(StatusCode.ERROR));
    expect(span.status.description, equals('Another error happened.'));

    // Verify that span status cannot be set to "Unset" and that description
    // is ignored for statuses other than "Error".
    span.setStatus(StatusCode.UNSET,
        description: 'Oops.  Can we turn this back off?');
    expect(span.status.code, equals(StatusCode.ERROR));
    expect(span.status.description, equals('Another error happened.'));

    // Verify that span status can be set to "Ok" and that description is
    // ignored for statuses other than "Error".
    span.setStatus(StatusCode.OK, description: 'All done here.');
    expect(span.status.code, equals(StatusCode.OK));
    expect(span.status.description, equals('Another error happened.'));

    // Verify that span status cannot be changed once set to "Ok".
    span.setStatus(StatusCode.ERROR, description: 'Something else went wrong.');
    expect(span.status.code, equals(StatusCode.OK));
    expect(span.status.description, equals('Another error happened.'));
  });
}