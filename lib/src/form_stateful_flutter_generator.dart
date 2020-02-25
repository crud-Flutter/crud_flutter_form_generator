import 'package:code_builder/code_builder.dart';
import 'package:crud_flutter_form_generator/crud_flutter_form_generator.dart';
import 'package:crud_generator/crud_generator.dart';

class FormStatefulFlutterGenerator
    extends GenerateFlutterWidgetForAnnotation<FormEntity> {
  @override
  String generateName() => '${element.name}${manyToManyPosFix}FormPage';
  @override
  void optionalClassInfo() {
    extend = refer('StatefulWidget');
    addImportPackage('package:flutter/material.dart');
  }

  void generateFields() {}

  generateConstructors() {
    var parameters = List<Parameter>();
    if (manyToMany) {
      parameters = [
        Parameter((b) => b
          ..name = 'collectionParent'
          ..type = refer('String')),
        Parameter((b) => b
          ..name = 'documentId'
          ..type = refer('String'))
      ];
    }
    declareConstructor(optionalParameters: parameters);
  }

  void generateMethods() {
    if (!manyToMany)
      addImportPackage('${element.name.toLowerCase()}.form.state.dart');

    declareMethod('createState',
        returns: refer('${element.name}${manyToManyPosFix}FormPageState'),
        lambda: true,
        body: Code('${element.name}${manyToManyPosFix}FormPageState()'));
  }

  @override
  GenerateClassForAnnotation instance() => FormStatefulFlutterGenerator()
    ..manyToMany = true
    ..generateImport = false;
}
