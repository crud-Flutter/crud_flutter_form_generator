import 'package:analyzer/dart/element/element.dart';
import 'package:code_builder/code_builder.dart';
import 'package:crud_generator/crud_generator.dart';
import 'package:source_gen/source_gen.dart';
import 'package:flutter_persistence_api/flutter_persistence_api.dart'
    as annotation;
import 'annotations.dart';

class FormStateFlutterGenerator
    extends GenerateFlutterWidgetForAnnotation<FormEntity> {
  String generateName() => '${element.name}${manyToManyPosFix}FormPageState';

  void optionalClassInfo() {
    extend = refer('flutter.State<${element.name}${manyToManyPosFix}FormPage>');
    if (!manyToMany) {
      addImportPackage('${element.name.toLowerCase()}.form.stateful.dart');
    }
  }

  void generateMethods() {
    _methodInitState();
    _methodBuild();
    _methodSave();
    // _methodManyToOneBuilder();
    // _methodOneToManyBuilder();
    // methodDispose();
  }

  void generateFields() {
    declareField(refer('final'), '_formKey',
        assignment: Code('flutter.GlobalKey<flutter.FormState>()'));
    addImportPackage('package:bloc_pattern/bloc_pattern.dart');
    if (!manyToMany) {
      addImportPackage('${element.name.toLowerCase()}.bloc.dart');
    }
    declareField(refer('${element.name}${manyToManyPosFix}Bloc'), '_bloc');
    declareField(refer('flutter.BuildContext'), 'context');
    // if (!manyToMany)
    //   addImportPackage('${element.name.toLowerCase()}.entity.dart');
    elementAsClass.fields.forEach((field) {
      //   if (field.type.name == 'DateTime' ||
      //       field.type.name == 'Date' ||
      //       field.type.name == 'Time') {
      //     addImportPackage(
      //         'package:flutter_datetime_formfield/flutter_datetime_formfield.dart');
      //     declareField(refer('DateTimeFormField'), '${field.name}Field');
      //   } else
      if (isManyToOneField(field)) {
        addImportPackage(
            '../${field.type.name.toLowerCase()}/${field.type.name.toLowerCase()}.entity.dart');
        declareField(
            refer('List<flutter.DropdownMenuItem<${field.type.name}Entity>>'),
            '${field.name}Items');
        //   } else if (isOneToManyField(field)) {
        //     var type = (getGenericTypes(field.type).first.element as ClassElement)
        //         .getField(getDisplayField(annotation.OneToMany, field))
        //         .type
        //         .name;
        //     declareField(refer('Map<$type, bool>'), '${field.name}Items');
        //   } else if (isManyToManyField(field)) {
        //   } else {
        //     declareField(refer('final'), '${field.name}Controller',
        //         assignment: Code('flutter.TextEditingController()'));
        //     declareField(refer('flutter.TextFormField'), '${field.name}Field');
      }
    });
  }

  void generateConstructors() {}

  _methodInitState() {
    var initStateCode = StringBuffer('''super.initState();
         _bloc = BlocProvider.getBloc<${element.name}${manyToManyPosFix}Bloc>();''');
    // elementAsClass.fields.forEach((field) {
    //   if (field.type.name == 'DateTime') {
    //     initStateCode.add(Code('var ${field.name}DateTime = DateTime.now();'));
    //   }
    // });
    // // initStateCode.add(Code(
    // // 'if (${element.name.toLowerCase()}${manyToManyPosFix}Entity != null) {'));
    // // initStateCode.add(Code(
    // // '_bloc.set${element.name}${manyToManyPosFix}Entity(${element.name.toLowerCase()}${manyToManyPosFix}Entity);'));
    elementAsClass.fields.forEach((field) {
      //   if (field.type.name == 'int' ||
      //       field.type.name == 'double' ||
      //       field.type.name == 'num') {
      //     initStateCode.add(Code(
      //         '${field.name}Controller.text = ${element.name.toLowerCase()}${manyToManyPosFix}Entity.${field.name} as String;'));
      //   } else
      // if (field.type.name == 'DateTime') {
      //   initStateCode.write(
      //       'if (${element.name.toLowerCase()}${manyToManyPosFix}Entity.${field.name} != null) {'
      //       '${field.name}DateTime = ${element.name.toLowerCase()}${manyToManyPosFix}Entity.${field.name};'
      //       '}');
      // }
      // });
      // // initStateCode.add(Code('} else {''}'));
      // elementAsClass.fields.forEach((field) {
      //   if (field.type.name == 'String') {
      //     initStateCode.add(_variableTextField(field.name));
      //   } else if (field.type.name == 'DateTime') {
      //     var dateOnlyField = TypeChecker.fromRuntime(annotation.Date);
      //     var timeOnlyField = TypeChecker.fromRuntime(annotation.Time);
      //     var only = null;
      //     if (dateOnlyField.hasAnnotationOfExact(field)) {
      //       only = 'onlyDate: true,';
      //     } else if (timeOnlyField.hasAnnotationOfExact(field)) {
      //       only = 'onlyTime: true,';
      //     }
      //     initStateCode
      //         .add(_variableDateTimeField(field.name, onlyDateOrTime: only));
      //   } else if (!isManyToOneField(field) &&
      //       !isOneToManyField(field) &&
      //       !isManyToManyField(field)) {
      //     // initStateCode
      //         // .add(_variableTextField(field.name, type: field.type.name));
      //   }
    });
    declareMethod('initState', body: Code(initStateCode.toString()));
  }

  String _manyToOneField(FieldElement field) {
    var displayField = getDisplayField(annotation.ManyToOne, field);
    return '''
    flutter.StreamBuilder<List<${field.type.name}Entity>>(
      stream: _bloc.list${field.name},
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return flutter.Center(child: flutter.CircularProgressIndicator());
        return flutter.Column(
          children: [
            flutter.DropdownButtonFormField<${field.type.name}Entity>(
              onChanged: (${field.type.name}Entity ${field.type.name.toLowerCase()}Entity) {
                setState(() {
                  _bloc.set${field.name}(${field.type.name.toLowerCase()}Entity);
                });
              },
              value: _bloc.$entityInstance?.${field.name},
              items: snapshot.data.map<flutter.DropdownMenuItem<${field.type.name}Entity>>
              ((${field.type.name}Entity ${field.name}Entity) =>
                flutter.DropdownMenuItem(
                  child: flutter.Text(${field.name}Entity.$displayField),
                  value: ${field.name}Entity,
                )
              ).toList()
            )
          ]
        );
      }
    ),
    ''';
  }

  String _oneToManyField(field) {
    var type = getGenericTypes(field.type).first.name;
    var displayField = getDisplayField(annotation.OneToMany, field);
    addImportPackage(
        '../${getGenericTypes(field.type).first.name.toLowerCase()}'
        '/${getGenericTypes(field.type).first.name.toLowerCase()}.entity.dart');
    return '''
    flutter.StreamBuilder<List<${type}Entity>>(
      stream: _bloc.list${field.name},
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return flutter.Center(child: flutter.CircularProgressIndicator());
        return flutter.Column(
          children: snapshot.data.map((${field.name}){
            return flutter.SwitchListTile(
              title: flutter.Text(${field.name}.$displayField),
              value: _bloc.has${field.name}(${field.name}),
              onChanged: (value) {
                setState(() {
                  if (value)                  
                    _bloc.add${field.name}(${field.name});                  
                  else                  
                    _bloc.remove${field.name}(${field.name});
                });
              }
            );
          }).toList()
        );
      },
    ),
          ''';
    // var type = getGenericTypes(field.type).first.name;
    // var displayField = getDisplayField(annotation.OneToMany, field);
    // addImportPackage(
    //     '../${type.toLowerCase()}/${type.toLowerCase()}.entity.dart');
    // declareMethod('${field.name}Builder',
    //     lambda: true, body: Code('''flutter.StreamBuilder<List<${type}Entity>>(
    //         stream: _bloc.list$type(),
    //         builder: (build, snapshot) {
    //         if (!snapshot.hasData)
    //         return flutter.Center(child: flutter.CircularProgressIndicator());
    //         if (${field.name}Items == null) {
    //         ${field.name}Items = {};
    //         snapshot.data.forEach((${field.name}) {
    //         var value = false;
    //         if (${element.name.toLowerCase()}${manyToManyPosFix}Entity != null
    //         && ${element.name.toLowerCase()}${manyToManyPosFix}Entity.${field.name} != null)
    //         value = ${element.name.toLowerCase()}${manyToManyPosFix}Entity.${field.name}
    //         .where((${field.name}Where)
    //         => ${field.name}Where.$displayField == ${field.name}.$displayField)
    //         .length > 0;
    //         ${field.name}Items[${field.name}.${displayField}] = value;
    //         });
    //         }
    //         var checkBox = List<flutter.Widget>();
    //         ${field.name}Items.forEach((index, value){
    //         checkBox.add(flutter.SwitchListTile(
    //         title: flutter.Text(index),
    //         value: value,
    //         onChanged: (bool value) {
    //         if (value) {
    //         if ((_bloc.out${field.name} as BehaviorSubject).value == null) {
    //         _bloc.set${field.name}([${type}Entity()..$displayField = index]);
    //         } else {
    //         if ((_bloc.out${field.name} as BehaviorSubject).value
    //         .where((${field.name}) => ${field.name}.$displayField == index)
    //         .length <=0) {
    //         (_bloc.out${field.name} as BehaviorSubject)
    //         .value.add(${type}Entity()..$displayField = index);
    //         }
    //         }
    //         } else if ((_bloc.out${field.name} as BehaviorSubject).value!=null){
    //         (_bloc.out${field.name} as BehaviorSubject).value
    //         .removeWhere((${field.name}) => ${field.name}.$displayField == index);
    //         }
    //         setState(() {
    //         ${field.name}Items[index] = value;
    //         });
    //         },
    //         ));
    //         });
    //         return flutter.Column(
    //         children: checkBox,
    //         );
    //         }
    //         )'''));
  }

  Code _dateTimeField(FieldElement field) {
    var dateOnlyField = TypeChecker.fromRuntime(annotation.Date);
    var timeOnlyField = TypeChecker.fromRuntime(annotation.Time);
    var onlyDateOrTime = null;
    if (dateOnlyField.hasAnnotationOfExact(field)) {
      onlyDateOrTime = 'onlyDate: true,';
    } else if (timeOnlyField.hasAnnotationOfExact(field)) {
      onlyDateOrTime = 'onlyTime: true,';
    }
    addImportPackage(
        'package:flutter_datetime_formfield/flutter_datetime_formfield.dart');
    var blockBuilder = StringBuffer('''DateTimeFormField(
        initialValue: _bloc.$entityInstance.${field.name},''');
    blockBuilder.writeln(onlyDateOrTime ?? '');
    blockBuilder.writeln('''label: '${field.name}',
        onSaved: _bloc.set${field.name}
        ),
        ''');
    return Code(blockBuilder.toString());
  }

  String _textField(String name, {String type = 'String'}) {
    var textFieldCode = StringBuffer('''flutter.TextFormField(
      decoration: flutter.InputDecoration(
        hintText: '${name[0].toUpperCase()}${name.substring(1)}'),''');
    var onChanged = Code('onChanged: _bloc.set${name},');
    if (type == 'String') {
      textFieldCode.writeln('initialValue: _bloc.$entityInstance?.$name,');
    } else if (type == 'int' || type == 'num' || type == 'number') {
      textFieldCode.writeln('keyboardType: flutter.TextInputType.number,');
      if (type == 'int') {
        textFieldCode.writeln(
            'inputFormatters: [flutter.WhitelistingTextInputFormatter.digitsOnly],');
      }
      onChanged =
          Code('onChanged: (text) {_bloc.set${name}($type.parse(text));},');
    }
    textFieldCode.writeln(onChanged);
    textFieldCode.writeln('),');
    return textFieldCode.toString();
  }

  void _methodSave() {
    var saveCode = StringBuffer('''if (_formKey.currentState.validate()) {
        _formKey.currentState.save();''');
    if (manyToMany) {
      saveCode.writeln('flutter.Navigator.pop(context);');
    } else {
      saveCode.writeln('''_bloc.insertOrUpdate().then((dynamic){
          flutter.Navigator.pop(context);
          });''');
    }
    saveCode.writeln('}');
    declareMethod('save', body: Code(saveCode.toString()));
  }

  void _methodBuild() {
    var titlePage = '${element.name}s';
    try {
      titlePage = getAnnotationValue('titlePage').stringValue;
    } catch (e) {}
    var buildCode = StringBuffer('''body: flutter.SingleChildScrollView(child:
      flutter.Form(
      key: _formKey,''');
    buildCode.writeln('child: flutter.Column(');
    buildCode.writeln('children:  <flutter.Widget> [');
    elementAsClass.fields.forEach((field) {
      if (field.type.name == 'DateTime') {
        buildCode.writeln(_dateTimeField(field));
      } else if (isManyToOneField(field)) {
        buildCode.writeln(_manyToOneField(field));
      } else if (isOneToManyField(field)) {
        buildCode.writeln(_oneToManyField(field));
      } else if (isManyToManyField(field)) {
      } else {
        buildCode.writeln(_textField(field.name, type: field.type.name));
      }
    });
    buildCode.writeln(']))),');
    var actionBarCode = StringBuffer('''actions: <flutter.Widget>[
      flutter.IconButton(icon: flutter.Icon(flutter.Icons.done),
      onPressed: save,
      ),]''');
    var fab;
    if (!manyToMany) {
      var where =
          elementAsClass.fields.where((field) => isManyToManyField(field));
      if (where.length == 1) {
        var name = getGenericTypes(where.first.type).first.element.name;
        fab = instanceFab(
            Code('flutter.Icon(flutter.Icons.add)'), Code('''() async {
               var ${name.toLowerCase()}ManyToManyEntity = 
               await flutter.Navigator.push<${name}ManyToManyEntity>(
                context, flutter.MaterialPageRoute(builder: (context)
                => ${name}ManyToManyFormPage()));
                if (${name.toLowerCase()}ManyToManyEntity !=null)
                _bloc.add${where.first.name}ManyToMany
                (${name.toLowerCase()}ManyToManyEntity);
                }'''));
      } else if (where.length > 1) {}
    }
    var scaffoldCode = StringBuffer('this.context=context;');
    scaffoldCode.writeln(instanceScaffold(titlePage,
        actionBar: Code(actionBarCode.toString()),
        body: Code(buildCode.toString()),
        fab: fab));
    methodBuild(Code(scaffoldCode.toString()));
  }

  @override
  GenerateClassForAnnotation instance() => FormStateFlutterGenerator()
    ..manyToMany = true
    ..generateImport = false;
}
