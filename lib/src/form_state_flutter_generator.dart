import 'package:analyzer/dart/element/element.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:code_builder/code_builder.dart';
import 'package:crud_generator/crud_generator.dart';
import 'package:source_gen/source_gen.dart';
import 'package:flutter_persistence_api/flutter_persistence_api.dart'
    as annotation;
import 'annotations.dart';

class FormStateFlutterGenerator
    extends GenerateFlutterWidgetForAnnotation<FormEntity> {
  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    init();
    name = '${element.name}FormPageState';
    this.element = element;
    this.annotation = annotation;
    extend = refer('State<${element.name}FormPage>');
    addImportPackage('${element.name.toLowerCase()}.form.stateful.dart');
    _declareField();
    _declareConstructor();
    _methodInitState();
    _methodBuild();
    _methodSave();
    _methodDateTimeFormat();
    return build();
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
    addImportPackage('package:intl/intl.dart');
  }

  _declareField() {
    declareField(refer('final'), '_formKey',
        assignment: Code('GlobalKey<FormState>()'));
    elementAsClass.fields.forEach((field) {
      if (field.type.name == 'DateTime' ||
          field.type.name == 'Date' ||
          field.type.name == 'Time') {
        addImportPackage(
            'package:flutter_datetime_formfield/flutter_datetime_formfield.dart');
        declareField(refer('DateTimeFormField'), '${field.name}Field');
      } else if (isManyToOneField(field)) {
        addImportPackage(
            '../${field.type.name.toLowerCase()}/${field.type.name.toLowerCase()}.entity.dart');
        declareField(refer('List<DropdownMenuItem<${field.type.name}Entity>>'),
            '${field.name}Items');
      } else {
        declareField(refer('final'), '${field.name}Controller',
            assignment: Code('TextEditingController()'));
        declareField(refer('TextFormField'), '${field.name}Field');
      }
    });
    addImportPackage('${element.name.toLowerCase()}.bloc.dart');
    declareField(refer('${element.name}Bloc'), '_bloc',
        assignment: Code('${element.name}Bloc()'));
    declareField(refer('BuildContext'), 'context');
    addImportPackage('${element.name.toLowerCase()}.entity.dart');
    declareField(refer('$entityClass'), '$entityInstance');
  }

  _declareConstructor() {
    declareConstructor(
      optionalParameters: [
        Parameter((b) => b
          ..name = 'this.${element.name.toLowerCase()}Entity'
          ..named = true)
      ],
    );
  }

  _methodInitState() {
    var initStateCode = [Code('super.initState();')];
    elementAsClass.fields.forEach((field) {
      if (field.type.name == 'String') {
        initStateCode.add(_variableTextField(field.name));
      } else if (field.type.name == 'DateTime') {
        var dateOnlyField = TypeChecker.fromRuntime(annotation.Date);
        var timeOnlyField = TypeChecker.fromRuntime(annotation.Time);
        var only = null;
        if (dateOnlyField.hasAnnotationOfExact(field)) {
          only = 'onlyDate: true,';
        } else if (timeOnlyField.hasAnnotationOfExact(field)) {
          only = 'onlyTime: true,';
        }
        initStateCode
            .add(_variableDateTimeField(field.name, onlyDateOrTime: only));
      } else if (!isManyToOneField(field)) {
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
      } else if (isManyToOneField(field)) {
        // initStateCode.add(Code('${field.name}Entity = $entityInstance.${field.name}Entity;'));
      }
    });
    initStateCode.add(Code('}'));
    var blockBuilder = BlockBuilder()..statements.addAll(initStateCode);
    declareMethod('initState', body: blockBuilder.build());
  }

  Code _variableManyToOne(String field, String type, String displayField) {
    var blockBuilder = BlockBuilder()
      ..statements.addAll([
        Code('StreamBuilder<List<${type}Entity>>('),
        Code('stream: _bloc.list${type}(),'),
        Code('builder: (context, snapshot) {'),
        Code('if (!snapshot.hasData)'),
        Code('return Center(child: CircularProgressIndicator());'),
        Code('if (${field}Items == null) {'),
        Code('${field}Items = snapshot.data'),
        Code('.map<DropdownMenuItem<${type}Entity>>('),
        Code('(${type}Entity ${field}Entity) { '),
        Code('_bloc.update${type}by${displayField}(${field}Entity);'),
        Code('return DropdownMenuItem('),
        Code('child: Text(${field}Entity.${displayField}),'),
        Code('value: ${field}Entity,'),
        Code(');}'),
        Code(').toList();'),
        Code('}'),
        Code('return DropdownButtonFormField<${type}Entity>('),
        Code('value: (_bloc.out${field}Entity as BehaviorSubject).value,'),
        Code('isExpanded: true,'),
        Code("hint: Text('${type}'),"),
        Code('items: ${field}Items,'),
        Code('onChanged: (${type}Entity ${field}Entity) {'),
        Code('setState((){'),
        Code('_bloc.set${field}Entity(${field}Entity);'),
        Code('});},'),
        Code(');'),
        Code('})')
      ]);
    return blockBuilder.build();
  }

  Code _variableDateTimeField(String name, {String onlyDateOrTime}) {
    var blockBuilder = BlockBuilder()
      ..statements.addAll([
        Code('${name}Field = DateTimeFormField('),
        Code(
            'initialValue: (_bloc.out$name as BehaviorSubject).value ?? DateTime.now(),'),
        Code(onlyDateOrTime ?? ''),
        // Code('formatter: DateFormat.yMMMMd().add_Hm(),'),
        Code("label: '$name',"),
        Code('onSaved: (DateTime dateTime) {'),
        Code('_bloc.set${name}(dateTime);'),
        Code('});')
      ]);
    addImportPackage('package:rxdart/subjects.dart');
    return blockBuilder.build();
  }

  Code _variableTextField(String name, {String type = 'String'}) {
    var textFieldCode = [
      Code('${name}Field = TextFormField('),
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
      Code('_formKey.currentState.save();'),
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
    var buildCode = [
      Code('body: SingleChildScrollView(child: '),
      Code('Form('),
      Code('key: _formKey,')
    ];
    buildCode.add(Code('child: Column('));
    buildCode.add(Code('children:  <Widget> ['));
    elementAsClass.fields.forEach((field) {
      if (isManyToOneField(field)) {
        buildCode.add(Code('${field.name}Builder(),'));
        declareMethod('${field.name}Builder',
            lambda: true,
            returns: refer('StreamBuilder<List<${field.type.name}Entity>>'),
            body: _variableManyToOne(field.name, field.type.name,
                getDisplayField(annotation.ManyToOne, field)));
      } else {
        buildCode.add(Code('${field.name}Field,'));
      }
    });
    buildCode.add(Code(']))),'));
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
