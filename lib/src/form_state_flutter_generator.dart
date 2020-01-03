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
    _methodManyToOneBuilder();
    _methodOneToManyBuilder();
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
      } else if (isOneToManyField(field)) {
        var type = (getGenericTypes(field.type).first.element as ClassElement)
            .getField(getDisplayField(annotation.OneToMany, field))
            .type
            .name;
        declareField(refer('Map<$type, bool>'), '${field.name}Items');
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
      } else if (!isManyToOneField(field) && !isOneToManyField(field)) {
        initStateCode
            .add(_variableTextField(field.name, type: field.type.name));
      }
    });
    var blockBuilder = BlockBuilder()..statements.addAll(initStateCode);
    declareMethod('initState', body: blockBuilder.build());
  }

  void _methodManyToOneBuilder() {
    elementAsClass.fields.forEach((field) {
      if (isManyToOneField(field)) {
        var displayField = getDisplayField(annotation.ManyToOne, field);
        declareMethod('${field.name}Builder',
            lambda: true,
            returns: refer('StreamBuilder<List<${field.type.name}Entity>>'),
            body: Code('StreamBuilder<List<${field.type.name}Entity>>('
                'stream: _bloc.list${field.type.name}(),'
                'builder: (context, snapshot) {'
                'if (!snapshot.hasData)'
                'return Center(child: CircularProgressIndicator());'
                'if (${field.name}Items == null) {'
                '${field.name}Items = snapshot.data'
                '.map<DropdownMenuItem<${field.type.name}Entity>>('
                '(${field.type.name}Entity ${field.name}Entity) { '
                '_bloc.update${field.type.name}by$displayField(${field.name}Entity);'
                'return DropdownMenuItem('
                'child: Text(${field.name}Entity.$displayField),'
                'value: ${field.name}Entity,'
                ');}'
                ').toList();'
                '}'
                'return DropdownButtonFormField<${field.type.name}Entity>('
                'value: (_bloc.out${field.name} as BehaviorSubject).value,'
                'isExpanded: true,'
                "hint: Text('${field.type.name}'),"
                'items: ${field.name}Items,'
                'onChanged: (${field.type.name}Entity ${field.name}Entity) {'
                'setState((){'
                '_bloc.set${field.name}(${field.name}Entity);'
                '});},'
                ');'
                '}'
                ')'));
      }
    });
  }

  void _methodOneToManyBuilder() {
    elementAsClass.fields.forEach((field) {
      if (isOneToManyField(field)) {
        var type = getGenericTypes(field.type).first.name;
        var displayField = getDisplayField(annotation.OneToMany, field);
        addImportPackage(
            '../${type.toLowerCase()}/${type.toLowerCase()}.entity.dart');
        addImportPackage('../${type.toLowerCase()}/${type.toLowerCase()}.dart');
        Code code = Code('StreamBuilder<List<${type}Entity>>('
            'stream: _bloc.list$type(),'
            'builder: (build, snapshot) {'
            'if (!snapshot.hasData)'
            'return Center(child: CircularProgressIndicator());'
            'if (${field.name}Items == null) {'
            '${field.name}Items = {};'
            'snapshot.data.forEach((${field.name}) {'
            'var value = false;'
            'if ($entityInstance != null && $entityInstance.${field.name} != null)'
            'value = $entityInstance.${field.name}'
            '.where((${field.name}Where) => ${field.name}Where.$displayField == ${field.name}.$displayField)'
            '.length > 0;'
            '${field.name}Items[${field.name}.${displayField}] = value;'
            '});'
            '}'
            'var checkBox = List<Widget>();'
            '${field.name}Items.forEach((index, value){'
            'checkBox.add(SwitchListTile('
            'title: Text(index),'
            'value: value,'
            'onChanged: (bool value) {'
            'if (value) {'
            'if ((_bloc.out${field.name} as BehaviorSubject).value == null) {'
            '_bloc.set${field.name}([$type()..$displayField = index]);'
            '} else {'
            'if ((_bloc.out${field.name} as BehaviorSubject).value'
            '.where((${field.name}) => ${field.name}.$displayField == index)'
            '.length <=0) {'
            '(_bloc.out${field.name} as BehaviorSubject).value.add($type()..$displayField = index);'
            '}'
            '}'
            '} else if ((_bloc.out${field.name} as BehaviorSubject).value!=null){'
            '(_bloc.out${field.name} as BehaviorSubject).value'
            '.removeWhere((${field.name}) => ${field.name}.$displayField == index);'
            '}'
            'setState(() {'
            '${field.name}Items[index] = value;'
            '});'
            '},'
            '));'
            '});'
            'return Column('
            'children: checkBox,'
            ');'
            '}'
            ')');
        declareMethod('${field.name}Builder', lambda: true, body: code);
      }
    });
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
      } else if (isOneToManyField(field)) {
        buildCode.add(Code('${field.name}Builder(),'));
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
