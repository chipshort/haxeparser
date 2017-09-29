package;
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.ExprTools;
import haxe.macro.MacroStringTools;
import haxe.macro.TypeTools;
import haxe.macro.TypedExprTools;

using StringTools;

typedef EnumConstr = {
	name: String,
	params: Int,
	type: Type
}

/**
 * ...
 * @author Christoph Otter
 */
class InteropMacro
{
	//Contains types that were not originally in haxeparser.Data and generic types
	static var predefinedTypes = [
		"ParseResult" => macro: { pack : Array<String>, decls: Array<haxeparser.Data.TypeDecl> },
		"FieldExpr" => macro: { field : String, expr : haxe.macro.Expr },
		"PackPos" => macro: { pack : String, pos : haxe.macro.Expr.Position },
		"Definition" => macro: haxeparser.Data.Definition<A,B>,
		"Arg" => macro: { name: String, opt: Bool, type: haxe.macro.Expr.ComplexType}
	];
	
	macro public static function buildConverter() : Array<Field>
	{
		var fields = Context.getBuildFields();
		var types = Context.getModule("hx.Ast");
		
		//var debugStr = "";
		
		for (ty in types) {
			switch (ty) {
				case TInst(t, params):
					var type = t.get();
					if (type.isInterface) continue;
					
					if (params.length == 0) { //Generic functions need to be written by hand
						var typestr = baseTypeToString(type, params, false);
						
						var field = createConverterField(ty, type, macro {
							${Context.parse('var result : $typestr = InteropMacro.convertTypeDef(input)', Context.currentPos())};
							return result;
						});
						
						/*switch (field.kind) {
							case FFun( f ):
								var e = EFunction(field.name, f);
								debugStr += ExprTools.toString({expr: e, pos: Context.currentPos()}) + "\n";
							default:
						}*/
						
						fields.push(field);
					}
					
					
				case TEnum(t, params):
					var type = t.get();
					var typestr = baseTypeToString(type, params);
					
					var field = createConverterField(ty, type, macro {
						${Context.parse('var result : $typestr = InteropMacro.convertEnum(input)', Context.currentPos())};
						return result;
					});
					
					/*switch (field.kind) {
						case FFun( f ):
							var e = EFunction(field.name, f);
							debugStr += ExprTools.toString({expr: e, pos: Context.currentPos()}) + "\n";
						default:
					}*/
					
					fields.push(field);
					
				default: //should not exist
					throw "This should not happen, hx.Ast contains a type that is not an enum or class: " + ty;
			}
		}
		
		//trace(debugStr);
		
		return fields;
	}

	macro public static function convert(e : Expr) : Expr
	{
		var type = Context.getExpectedType();
		var input = Context.typeExpr(e).t;
		
		if (type == null)
			throw "This macro needs explicit information about the expected type, make sure to provide it. Called with expr: " + ExprTools.toString(e);
		
		var typeName = typeToString(type);
		var inputName = typeToString(input);
		var simpleTypeName : String; //just the last part of the type path, same for input and output type
		
		var typeParams : Array<Type>;
		var inputParams : Array<Type>;		
		
		typeParams = getTypeParams(type);
		inputParams = getTypeParams(input);
		
		//normalize Null<> wrapped types
		while (inputName.startsWith("StdTypes.Null")) {
			input = inputParams[0];
			inputParams = getTypeParams(input);
			inputName = typeToString(input);
		}
		while (typeName.startsWith("StdTypes.Null")) {
			type = typeParams[0];
			typeParams = getTypeParams(type);
			typeName = typeToString(type);
		}
		
		simpleTypeName = getSimpleTypeName(type);
		
		var returnExpr : Expr;
		
		if (typeName.startsWith("cs.NativeArray")) { //handle arrays
			
			var typestr = typeToString(typeParams[0]);
			returnExpr = macro {
				var original = ${e};
				if (original == null) {
					null;
				}
				else {
					var result = ${Context.parse('new $typeName(original.length)', pos("Array creation"))}
					
					for (i in 0...original.length) {
						${Context.parse('var res : $typestr = InteropMacro.convert(original[i])', pos('InteropMacro.convert $typestr'))};
						result[i] = res;
					}
					
					result;
				}
				
			}
		}
		else if (typeName == inputName) { //don't convert identical types, just assign directly
			returnExpr = e;
		}
		else {
			if (typeParams.length > 0) { //generic type needs special treatment
				simpleTypeName = simpleTypeName + "_" + typeParams.map(function (t) return getSimpleTypeName(t)).join("_");
			}
			
			returnExpr = macro {
				${Context.parse('hx.util.CsharpConverter.convert$simpleTypeName', pos('convert$simpleTypeName'))}($e);
			}
		}
		
		//trace(ExprTools.toString(returnExpr));

		return returnExpr;
	}
	
	macro public static function convertTypeDef(expr : Expr)
	{
		var type = Context.getExpectedType();
		var input = Context.typeExpr(expr).t;
		var typename = typeToString(type);
		var itypename = typeToString(input);
		
		var fields : Array<String> = TypeTools.getClass(type).fields.get().filter(function (f) return f.kind.match(FVar(_,_))).map(function (f) return f.name);
		
		var returnExpr = macro {
			var original = ${expr};
			if (original == null) {
				null;
			}
			else {
				//create class
				var result = ${Context.parse('new $typename()', Context.currentPos())};
				//copy all fields
				$b{fields.map(function (f) return Context.parse('result.$f = InteropMacro.convert(original.$f)', pos("InteropMacro.convert in convertTypeDef")))};
				
				result;
			}
			
		}
		
		return returnExpr;
	}
	
	macro public static function convertEnum(expr : Expr)
	{
		var type = Context.getExpectedType();
		var input = Context.typeExpr(expr).t;
		var enumConstructs : Map<String, EnumConstr>;
		var typename = typeToString(type);
		var itypename = typeToString(input);
		
		
		enumConstructs = getEnumConstructorData(TypeTools.getEnum(type));
		
		var enumCode = "switch (original) {";
		for (c in enumConstructs)
		{
			enumCode += "case " + itypename + "." + c.name;

			if (c.params > 0)
				enumCode += "(";

			var args = [for (i in 0 ... c.params) 'a$i'];

			enumCode += args.join(", ");

			if (c.params > 0)
				enumCode += ")";

			enumCode += ": " + typename + "." + c.name;

			if (c.params > 0)
				enumCode += "(";

			enumCode += args.map(function (arg) return 'InteropMacro.convert($arg)').join(", ");

			if (c.params > 0)
				enumCode += ")";

			enumCode += ";";

		}

		enumCode += "}";

		var returnExpr = macro {
			var original = ${expr};
			if (original == null) {
				null;
			}
			else {
				//switch over all possible values
				var result = ${Context.parse(enumCode, pos('Enum $typename'))};
				result;
			}
		}
		
		return returnExpr;
	}

	#if macro
	
	static function pos(msg : String)
	{
		return Context.makePosition({min:0, max:0, file:'$msg'});
	}
	
	static function getTypeParams(type : Type) : Array<Type>
	{
		switch (type)
		{
			case TInst(_, params):
				return params;
			case TEnum(_, params):
				return params;
			case TType(_, params): //Null<T>
				return params;
			case TAbstract(_, params):
				return params;
			default:
				return null;
		}
	}
	
	static function getSimpleTypeName(type : Type) : String
	{
		switch (type)
		{
			case TInst(t, _):
				return t.get().name;
			case TEnum(t, _):
				return t.get().name;
			case TType(t, _): //Null<T>
				return t.get().name;
			case TAbstract(t, _):
				return t.get().name;
			case TDynamic(_):
				return "Dynamic";
			default:
				return null;
		}
	}
	
	static function createConverterField(output : Type, type : BaseType, convertExpr : Expr) : Field
	{
		//get input type (either from haxeparser.Data or haxe.macro.Expr)
		var input = try {
			var t = TypeTools.toComplexType(Context.getType("haxeparser.Data." + type.name));
			if (t == null) throw "";
			t;
		} catch (e : Dynamic) {
			try {
				var t = TypeTools.toComplexType(Context.getType("haxe.macro.Expr." + type.name));
				if (t == null) throw "";
				t;
			}
			catch (e : Dynamic) {
				predefinedTypes[type.name];
			}
		}
		
		var params : Array<TypeParamDecl> = [for (t in type.params) { name: t.name }];
		
		var field : Field = {
			name: "convert" + type.name,
			access: [APublic, AStatic],
			pos: Context.makePosition({min:0, max:0, file: "hx.Ast." + type.name}),
			kind: FFun({
				args: [{
					name: "input",
					type: input
				}],
				ret: TypeTools.toComplexType(output),
				expr: convertExpr,
				params: params
			})
		}
		
		return field;
	}
	
	static function getEnumConstructorData(t : EnumType)
	{
		var enumConstructs = new Map<String, EnumConstr>();

		for (c in t.constructs) {
			switch (c.type)
			{
				case TFun(args, _):
					enumConstructs.set(c.name,
					{
						name: c.name,
						params: args.length,
						type: c.type
					});
				default:
					enumConstructs.set(c.name,
					{
						name: c.name,
						params: 0,
						type: c.type
					});
			}
		}

		return enumConstructs;
	}
	
	static function nestedTypeToString(type : Type)
	{
		switch (type) {
			case TEnum(t, params):
				return t.get().name;
			case TInst(t, params):
				return t.get().name;
			case TType(t, params):
				return t.get().name;
			case TAbstract(t, params):
				return t.get().name;
			case TAnonymous(a):
				var fields = a.get().fields.map(function (f) return f.name + " : " + typeToString(f.type));
				return "{ " + fields.join(", ") + " }";
			default:
				return TypeTools.toString(type);
		}
	}
	
	static function typeToString(type : Type)
	{
		switch (type) {
			case TEnum(t, params):
				return baseTypeToString(t.get(), params);
			case TInst(t, params):
				return baseTypeToString(t.get(), params);
			case TType(t, params):
				return baseTypeToString(t.get(), params);
			case TAbstract(t, params):
				return baseTypeToString(t.get(), params);
			case TAnonymous(a):
				var fields = a.get().fields.map(function (f) return f.name + " : " + typeToString(f.type));
				return "{ " + fields.join(", ") + " }";
			default:
				return TypeTools.toString(type);
		}
		
	}

	static function baseTypeToString(t : BaseType, params : Array<Type>, nested = true)
	{
		var result = t.module;
		
		if (!t.module.endsWith(t.name))
			result += "." + t.name;
			
		if (params.length > 0) {
			result += "<";
			
			if (nested)
				result += params.map(typeToString).join(",");
			else
				result += params.map(nestedTypeToString).join(",");
			result += ">";
		}
		return result;
	}

	#end

}