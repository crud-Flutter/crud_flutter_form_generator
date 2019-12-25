import 'package:analyzer/dart/element/element.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:code_builder/code_builder.dart';
import 'package:crud_flutter_form_generator/crud_flutter_form_generator.dart';
import 'package:crud_generator/crud_generator.dart';
import 'package:source_gen/src/constants/reader.dart';

class FormStatefulFlutterGenerator
    extends GenerateFlutterWidgetForAnnotation<FormEntity> {
  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    name = '${element.name}FormPage';
    this.element = element;
    this.annotation = annotation;
    extend = refer('StatefulWidget');
    _methodCreateState();
    return "import '${element.name.toLowerCase()}.form.state.dart';"+build();
  }

  void _methodCreateState() {
    declareMethod('createState',
        returns: refer('${element.name}FormPageState'),
        lambda: true,
        body: Code('${element.name}FormPageState()'));
  }
}
