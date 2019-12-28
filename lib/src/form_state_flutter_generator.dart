import 'package:analyzer/dart/element/element.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:code_builder/code_builder.dart';
import 'package:crud_generator/crud_generator.dart';
import 'package:source_gen/source_gen.dart';

import 'annotations.dart';

class FormStateFlutterGenerator
    extends GenerateFlutterWidgetForAnnotation<FormEntity> {
  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    name = '${element.name}FormPageState';
    this.element = element;
    this.annotation = annotation;
    extend = refer('State<${element.name}FormPage>');
    _declareField();
    _declareConstructor();
    _methodInitState();
    _methodBuild();
    _methodSave();
    _methodDateTimeFormat();
    return "import 'package:rxdart/subjects.dart';"
            "import '${element.name.toLowerCase()}.bloc.dart';"
            "import '${element.name.toLowerCase()}.form.stateful.dart';"
            "import 'package:flutter/services.dart';"
            "import '${element.name.toLowerCase()}.entity.dart';"
            "import 'package:flutter_datetime_formfield/flutter_datetime_formfield.dart';"
            "import 'package:intl/intl.dart';" +
        build();
  }

  _methodDateTimeFormat() {
    var blockBuilder = BlockBuilder()
      ..statements.addAll([
        Code('var dateFormat;'),
        Code('if (context == null) {'),
        Code('dateFormat = DateFormat.yMMMMd();'),
        Code('}'),
        Code('else {'),
        Code(
            'dateFormat = DateFormat.yMMMMd(Localizations.localeOf(context).languageCode);'),
        Code('}'),
        Code('return dateFormat.add_Hm().format(dateTime);')
      ]);

    declareMethod('dateTimeFormat',
        returns: refer('String'),
        requiredParameters: [
          Parameter((b) => b
            ..name = 'dateTime'
            ..type = refer('DateTime'))
        ],
        body: blockBuilder.build());
  }

  _declareField() {
    declareField(refer('final'), '_formKey',
        assignment: Code('GlobalKey<FormState>()'));
    elementAsClass.fields.forEach((field) {
      declareField(refer('final'), '${field.name}Controller',
          assignment: Code('TextEditingController()'));
      if (field.type.name == 'DateTime') {
        declareField(refer('DateTimeFormField'), field.name);
      } else {
        declareField(refer('TextFormField'), field.name);
      }
    });
    declareField(refer('${element.name}Bloc'), '_bloc',
        assignment: Code('${element.name}Bloc()'));
    declareField(refer('BuildContext'), 'context');
    declareField(refer('$entityClass'), '$entityInstance');
  }

  _declareConstructor() {
    declareConstructor(
        optionalParameters: [
          Parameter((b) => b
            ..name = 'this.${element.name.toLowerCase()}Entity'
            ..named = true)
        ],
        body: Code(
            'if (this.${element.name.toLowerCase()}Entity !=null) {_bloc.set${element.name}Entity(this.${element.name.toLowerCase()}Entity);}'));
  }

  _methodInitState() {
    var initStateCode = [Code('super.initState();')];
    elementAsClass.fields.forEach((field) {
      if (field.type.name == 'String') {
        initStateCode.add(_variableTextField(field.name));
      } else if (field.type.name == 'DateTime') {
        print('DateTime');
        initStateCode.add(_variableDateTimeField(field.name));
      } else {
        initStateCode
            .add(_variableTextField(field.name, type: field.type.name));
      }
    });
    initStateCode.add(Code('if ($entityInstance != null) {'));
    initStateCode.add(Code('_bloc.set$entityClass($entityInstance);'));
    elementAsClass.fields.forEach((field) {
      if (field.type.name == 'String') {
        initStateCode.add(Code(
            '${field.name}Controller.text = $entityInstance.${field.name};'));
      } else if (field.type.name == 'int' ||
          field.type.name == 'double' ||
          field.type.name == 'num') {
        initStateCode.add(Code(
            '${field.name}Controller.text = $entityInstance.${field.name} as String;'));
      } else if (field.type.name == 'DateTime') {
        initStateCode.add(Code(
            '${field.name}Controller.text = dateTimeFormat($entityInstance.${field.name});'));
      }
    });
    initStateCode.add(Code('}'));
    var blockBuilder = BlockBuilder()..statements.addAll(initStateCode);
    declareMethod('initState', body: blockBuilder.build());
  }

  Code _variableDateTimeField(String name) {
    var blockBuilder = BlockBuilder()
      ..statements.addAll([
        Code('$name = DateTimeFormField('),
        Code(
            'initialValue: (_bloc.out$name as BehaviorSubject).value ?? DateTime.now(),'),
        Code('formatter: DateFormat.yMMMMd().add_Hm(),'),
        Code("label: '$name',"),
        Code('onSaved: (DateTime dateTime) {'),
        Code('${name}Controller.text = dateTimeFormat(dateTime);'),
        Code('_bloc.set${name}(dateTime);'),
        Code('});')
      ]);
    return blockBuilder.build();
  }

  Code _variableTextField(String name, {String type = 'String'}) {
    var textFieldCode = [
      Code('$name = TextFormField('),
      Code(
          "decoration: InputDecoration(hintText: '${name[0].toUpperCase()}${name.substring(1)}'),"),
      Code('controller: ${name}Controller,'),
    ];
    var onChanged = Code('onChanged: _bloc.set${name},');
    if (type == 'int' || type == 'num' || type == 'number') {
      textFieldCode.add(Code('keyboardType: TextInputType.number,'));
      if (type == 'int') {
        textFieldCode.add(Code(
            'inputFormatters: [WhitelistingTextInputFormatter.digitsOnly],'));
      }
      onChanged =
          Code('onChanged: (text) {_bloc.set${name}($type.parse(text));},');
    }
    textFieldCode.add(onChanged);
    textFieldCode.add(Code(');'));
    var blockBuilder = BlockBuilder()..statements.addAll(textFieldCode);
    return blockBuilder.build();
  }

  _methodSave() {
    var saveCode = [
      Code('if (_formKey.currentState.validate()) {'),
      Code('_bloc.insertOrUpdate().then((dynamic){'),
      Code('Navigator.pop(context);'),
      Code('});'),
      Code('}')
    ];
    var blockBuilder = BlockBuilder();
    blockBuilder.statements.addAll(saveCode);
    declareMethod('save', body: blockBuilder.build());
  }

  _methodBuild() {
    var titlePage = '${element.name}s';
    try {
      titlePage = getAnnotationValue('titlePage').stringValue;
    } catch (e) {}
    var buildCode = [Code('body: Form('), Code('key: _formKey,')];
    buildCode.add(Code('child: Column('));
    buildCode.add(Code('children:  <Widget> ['));
    elementAsClass.fields.forEach((field) {
      buildCode.add(Code('${field.name},'));
    });
    buildCode.add(Code('])),'));
    var blockBuilder = BlockBuilder();
    blockBuilder.statements.addAll(buildCode);
    var actionBarCode = [
      Code('actions: <Widget>['),
      Code('IconButton(icon: Icon(Icons.done),'),
      Code('onPressed: save,'),
      Code('),]')
    ];
    var actionBlockBuilder = BlockBuilder();
    actionBlockBuilder.statements.addAll(actionBarCode);
    var scaffold = instanceScaffold(titlePage,
        actionBar: actionBlockBuilder.build(), body: blockBuilder.build());
    var buildBlock = BlockBuilder()
      ..statements.addAll([Code('this.context=context;'), scaffold]);
    methodBuild(buildBlock.build());
  }
}
