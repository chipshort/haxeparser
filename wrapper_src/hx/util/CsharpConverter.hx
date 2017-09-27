package hx.util;
import cs.NativeArray;
import haxeparser.Data;
import haxe.macro.Expr;

/**
 * This type contains mostly auto-generated functions to convert haxe typedefs to classes recursively to be able to use them nicely in C#
 * @author Christoph Otter
 */
@:build(InteropMacro.buildConverter())
class CsharpConverter 
{

	
	// The following methods are needed, because generic types cannot be auto-generated easily
	public static function convertDefinition_ClassFlag_NativeArray(input : Definition<haxeparser.Data.ClassFlag, Array<Field>>)
		: hx.Ast.Definition<hx.Ast.ClassFlag, NativeArray<hx.Ast.Field>>
	{
		var result : hx.Ast.Definition<hx.Ast.ClassFlag, NativeArray<hx.Ast.Field>> = InteropMacro.convertTypeDef(input);
		return result;
	}
	
	public static function convertDefinition_EnumFlag_NativeArray(input : Definition<EnumFlag, Array<EnumConstructor>>)
		: hx.Ast.Definition<EnumFlag, NativeArray<hx.Ast.EnumConstructor>>
	{
		var result : hx.Ast.Definition<EnumFlag, NativeArray<hx.Ast.EnumConstructor>> = InteropMacro.convertTypeDef(input);
		return result;
	}
	
	public static function convertDefinition_AbstractFlag_NativeArray(input : Definition<haxeparser.Data.AbstractFlag, Array<Field>>)
		: hx.Ast.Definition<hx.Ast.AbstractFlag, NativeArray<hx.Ast.Field>>
	{
		var result : hx.Ast.Definition<hx.Ast.AbstractFlag, NativeArray<hx.Ast.Field>> = InteropMacro.convertTypeDef(input);
		return result;
	}
	
	public static function convertDefinition_EnumFlag_ComplexType(input : Definition<EnumFlag, ComplexType>)
		: hx.Ast.Definition<EnumFlag, hx.Ast.ComplexType>
	{
		var result : hx.Ast.Definition<EnumFlag, hx.Ast.ComplexType> = InteropMacro.convertTypeDef(input);
		return result;
	}
}