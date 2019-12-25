import 'package:build/build.dart';
import 'package:crud_flutter_form_generator/src/form_state_flutter_generator.dart';
import 'package:crud_flutter_form_generator/src/form_stateful_flutter_generator.dart';
import 'package:source_gen/source_gen.dart';

Builder formStateFulFlutterBuilder(BuilderOptions options) =>
    LibraryBuilder(FormStatefulFlutterGenerator(),
        generatedExtension: '.form.stateful.dart');
Builder formStateFlutterBuilder(BuilderOptions options) =>
    LibraryBuilder(FormStateFlutterGenerator(),
        generatedExtension: '.form.state.dart');
