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
    _declareField();
    _declareConstructor();
    _methodCreateState();
    return "import '${element.name.toLowerCase()}.form.state.dart';"
            "import '${element.name.toLowerCase()}.entity.dart';" +
        build();
  }

  _declareField() {
    declareField(
        refer('${element.name}Entity'), '${element.name.toLowerCase()}Entity',
        modifier: FieldModifier.final$);
  }

  _declareConstructor() {
    declareConstructor(optionalParameters: [
      Parameter((b) => b
        ..name = 'this.${element.name.toLowerCase()}Entity'
        ..named = true)
    ]);
  }

  void _methodCreateState() {
    declareMethod('createState',
        returns: refer('${element.name}FormPageState'),
        lambda: true,
        body: Code(
            '${element.name}FormPageState(${element.name.toLowerCase()}Entity: ${element.name.toLowerCase()}Entity)'));
  }
}