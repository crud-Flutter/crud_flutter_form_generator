import 'package:analyzer/dart/element/element.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:code_builder/code_builder.dart';
import 'package:crud_generator/crud_generator.dart';
import 'package:source_gen/source_gen.dart';

import 'annotations.dart';

class FormStatelessFlutterGenerator
    extends GenerateFlutterWidgetForAnnotation<FormEntity> {
  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    name = '${element.name}FormPage';
    this.element = element;
    this.annotation = annotation;
    extend = refer('StatelessWidget');
    _declareField();
    _methodBuild();
    _methodSave();
    return "import 'package:rxdart/subjects.dart';"
            "import '${element.name.toLowerCase()}.bloc.dart';"
            "import 'package:flutter/services.dart';"
            "import 'package:intl/intl.dart';" +
        build();
  }

  _declareField() {
    declareField(refer('final'), '_formKey',
        assignment: Code('GlobalKey<FormState>()'));
    elementAsClass.fields.forEach((field) {
      if (field.type.name == 'DateTime') {
        declareField(refer('final'), '${field.name}Controller',
            assignment: Code('TextEditingController()'));
      }
    });
    declareField(refer('${element.name}Bloc'), '_bloc',
        assignment: Code('${element.name}Bloc()'));
    declareField(refer('BuildContext'), 'context');
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
      buildCode.add(Code('TextFormField('));
      if (field.type.name == 'int') {
        buildCode.add(Code('keyboardType: TextInputType.number,'));
        buildCode.add(Code(
            'inputFormatters: [WhitelistingTextInputFormatter.digitsOnly],'));
        buildCode.add(Code('onChanged: (text) {'));
        buildCode.add(Code('_bloc.set${field.name}(int.parse(text));'));
        buildCode.add(Code('},'));
      } else if (field.type.name == 'double') {
        buildCode.add(Code('keyboardType: TextInputType.number,'));
        buildCode.add(Code('onChanged: (text) {'));
        buildCode.add(Code('_bloc.set${field.name}(double.parse(text));'));
        buildCode.add(Code('},'));
      } else if (field.type.name == 'num') {
        buildCode.add(Code('keyboardType: TextInputType.number,'));
        buildCode.add(Code('onChanged: (text) {'));
        buildCode.add(Code('_bloc.set${field.name}(num.parse(text));'));
        buildCode.add(Code('},'));
      } else if (field.type.name == 'DateTime') {
        buildCode.add(Code('keyboardType: TextInputType.datetime,'));
        buildCode.add(Code('controller: ${field.name}Controller,'));
        buildCode.add(Code('onTap: () async {'));
        buildCode
            .add(Code('FocusScope.of(context).requestFocus(new FocusNode());'));
        buildCode.add(Code('var selectedDate = await showDatePicker('));
        buildCode.add(Code('context: context,'));
        buildCode.add(Code(
            'initialDate: (_bloc.outdateCreation as BehaviorSubject).value ?? DateTime.now(),'));
        buildCode.add(Code('firstDate: DateTime(2018),'));
        buildCode.add(Code('lastDate: DateTime(2030),'));
        buildCode.add(Code(');'));
        buildCode.add(Code('if(selectedDate != null) {'));
        buildCode.add(Code(
            'var initialTime = (_bloc.outdateCreation as BehaviorSubject).value;'));
        buildCode.add(Code('if (initialTime==null) {'));
        buildCode.add(Code('initialTime = TimeOfDay.now();'));
        buildCode.add(Code('} else {'));
        buildCode
            .add(Code('initialTime = TimeOfDay.fromDateTime(initialTime);'));
        buildCode.add(Code('}'));
        buildCode.add(Code('var selectedTime = await showTimePicker('));
        buildCode.add(Code('context: context,'));
        buildCode.add(Code('initialTime: initialTime,'));
        buildCode.add(Code(');'));
        buildCode.add(Code('if (selectedTime != null) {'));
        buildCode.add(Code(
            'var dateTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, selectedTime.hour, selectedTime.minute);'));
        buildCode.add(Code(
            '${field.name}Controller.text = DateFormat.yMMMMd(Localizations.localeOf(context).languageCode).add_Hm().format(dateTime);'));
        buildCode.add(Code('_bloc.set${field.name}(dateTime);'));
        buildCode.add(Code('}'));
        buildCode.add(Code('}'));
        buildCode.add(Code('},'));
      } else if (field.type.name == 'String') {
        buildCode.add(Code('onChanged: _bloc.set${field.name},'));
      }
      buildCode.add(Code('decoration: InputDecoration('));

      buildCode.add(Code(
          "hintText: '${field.name[0].toUpperCase()}${field.name.substring(1)}'"));
      buildCode.add(Code('),'));
      // buildCode.add(Code('controller: ${field.name}Controller'));
      buildCode.add(Code('),'));
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
