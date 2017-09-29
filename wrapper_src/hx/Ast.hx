package hx;

import cs.NativeArray;
import haxe.macro.Expr.Constant;
import haxe.macro.Expr.Binop;
import haxe.macro.Expr.Unop;
import haxe.macro.Expr.Access;
import haxeparser.Data.EnumFlag;
import haxeparser.Data.ImportMode;

//TODO: auto-generate most of these?

//HAXEPARSER

@:nativeGen
interface FieldResult
{
	var name : String;
	var doc : String;
	var meta: NativeArray<MetadataEntry>;
	var pos: Position;
}

//@:struct //not working in current version of Haxe
@:nativeGen
class ParseResult
{
	public var pack : NativeArray<String>;
	public var decls : NativeArray<TypeDecl>;
	
	public function new() {}
}

@:nativeGen
class FieldExpr
{
	public var field : String;
	public var expr : Expr;
	
	public function new() {}
}

@:nativeGen
class PackPos
{
	public var pack : String;
	public var pos : Position;
	
	public function new() {}
}


@:nativeGen
class TypeDecl
{
	public var decl : TypeDef;
	public var pos : Position;
	
	public function new() {}
}

@:nativeGen
class Arg
{
	public var name : String;
	public var opt : Bool;
	public var type : ComplexType;
	
	public function new() {}
}

@:nativeGen
class EnumConstructor implements FieldResult
{
	public var name : String;
	public var doc: String;
	public var meta: NativeArray<MetadataEntry>;
	public var args: NativeArray<Arg>;
	public var pos: Position;
	public var params: NativeArray<TypeParamDecl>;
	public var type: Null<ComplexType>;
	
	public function new() {}
}

enum ClassFlag {
	HInterface;
	HExtern;
	HPrivate;
	HExtends(t:TypePath);
	HImplements(t:TypePath);
}

enum TypeDef {
	EClass(d:Definition<ClassFlag, NativeArray<Field>>);
	EEnum(d:Definition<EnumFlag, NativeArray<EnumConstructor>>);
	EAbstract(a:Definition<AbstractFlag, NativeArray<Field>>);
	EImport(sl:NativeArray<PackPos>, mode:ImportMode);
	ETypedef(d:Definition<EnumFlag, ComplexType>);
	EUsing(path:TypePath);
}

enum AbstractFlag {
	APrivAbstract;
	AFromType(ct:ComplexType);
	AToType(ct:ComplexType);
	AIsType(ct:ComplexType);
	AExtern;
}

//TODO: check how generics look
@:nativeGen
class Definition<A,B>
{
	public var name : String;
	public var doc: String;
	public var params: NativeArray<TypeParamDecl>;
	public var meta: NativeArray<MetadataEntry>;
	public var flags: NativeArray<A>;
	public var data: B;
	
	public function new() {}
}


/**
	Represents a metadata entry in the AST.
**/
@:nativeGen
class MetadataEntry
{
	/**
		The name of the metadata entry.
	**/
	public var name : String;

	/**
		The optional parameters of the metadata entry.
	**/
	@:optional public var params : NativeArray<Expr>;

	/**
		The position of the metadata entry.
	**/
	public var pos : Position;
	
	public function new() {}
}

/**
	Represents a position in a file.
**/
@:nativeGen
class Position
{
	/**
		Reference to the filename.
	**/
	public var file : String;

	/**
		Position of the first character.
	**/
	public var min : Int;

	/**
		Position of the last character.
	**/
	public var max : Int;
	
	public function new() {}
}

/**
	Represents a type parameter declaration in the AST.
**/
@:nativeGen
class TypeParamDecl
{
	/**
		The name of the type parameter.
	**/
	public var name : String;

	/**
		The optional constraints of the type parameter.
	**/
	@:optional public var constraints : NativeArray<ComplexType>;

	/**
		The optional parameters of the type parameter.
	**/
	@:optional public var params : NativeArray<TypeParamDecl>;

	/**
		The metadata of the type parameter.
	**/
	@:optional public var meta : NativeArray<MetadataEntry>;
	
	public function new() {}
}

@:nativeGen
class Expr
{
	/**
		The expression kind.
	**/
	public var expr : ExprDef;

	/**
		The position of the expression.
	**/
	public var pos : Position;
	
	public function new() {}
}

/**
	Represents the kind of a node in the AST.
**/
enum ExprDef {
	/**
		A constant.
	**/
	EConst( c : Constant );

	/**
		Array access `e1[e2]`.
	**/
	EArray( e1 : Expr, e2 : Expr );

	/**
		Binary operator `e1 op e2`.
	**/
	EBinop( op : Binop, e1 : Expr, e2 : Expr );

	/**
		Field access on `e.field`.
	**/
	EField( e : Expr, field : String );

	/**
		Parentheses `(e)`.
	**/
	EParenthesis( e : Expr );

	/**
		An object declaration.
	**/
	EObjectDecl( fields : NativeArray<FieldExpr> ); //TODO remove typedef

	/**
		An array declaration `[el]`.
	**/
	EArrayDecl( values : NativeArray<Expr> );

	/**
		A call `e(params)`.
	**/
	ECall( e : Expr, params : NativeArray<Expr> );

	/**
		A constructor call `new t(params)`.
	**/
	ENew( t : TypePath, params : NativeArray<Expr> );

	/**
		An unary operator `op` on `e`:

		* e++ (op = OpIncrement, postFix = true)
		* e-- (op = OpDecrement, postFix = true)
		* ++e (op = OpIncrement, postFix = false)
		* --e (op = OpDecrement, postFix = false)
		* -e (op = OpNeg, postFix = false)
		* !e (op = OpNot, postFix = false)
		* ~e (op = OpNegBits, postFix = false)
	**/
	EUnop( op : Unop, postFix : Bool, e : Expr );

	/**
		Variable declarations.
	**/
	EVars( vars : NativeArray<Var> );

	/**
		A function declaration.
	**/
	EFunction( name : Null<String>, f : Function );

	/**
		A block of expressions `{exprs}`.
	**/
	EBlock( exprs : NativeArray<Expr> );

	/**
		A `for` expression.
	**/
	EFor( it : Expr, expr : Expr );

	/**
		A `(e1 in e2)` expression.
	**/
	EIn( e1 : Expr, e2 : Expr );

	/**
		An `if(econd) eif` or `if(econd) eif else eelse` expression.
	**/
	EIf( econd : Expr, eif : Expr, eelse : Null<Expr> );

	/**
		Represents a `while` expression.
		When `normalWhile` is `true` it is `while (...)`.
		When `normalWhile` is `false` it is `do {...} while (...)`.
	**/
	EWhile( econd : Expr, e : Expr, normalWhile : Bool );

	/**
		Represents a `switch` expression with related cases and an optional.
		`default` case if edef != null.
	**/
	ESwitch( e : Expr, cases : NativeArray<Case>, edef : Null<Expr> );

	/**
		Represents a `try`-expression with related catches.
	**/
	ETry( e : Expr, catches : NativeArray<Catch> );

	/**
		A `return` or `return e` expression.
	**/
	EReturn( ?e : Null<Expr> );

	/**
		A `break` expression.
	**/
	EBreak;

	/**
		A `continue` expression.
	**/
	EContinue;

	/**
		An `untyped e` source code.
	**/
	EUntyped( e : Expr );

	/**
		A `throw e` expression.
	**/
	EThrow( e : Expr );

	/**
		A `cast e` or `cast (e, m)` expression.
	**/
	ECast( e : Expr, t : Null<ComplexType> );

	/**
		Internally used to provide completion.
	**/
	EDisplay( e : Expr, isCall : Bool );

	/**
		Internally used to provide completion.
	**/
	EDisplayNew( t : TypePath );

	/**
		A `(econd) ? eif : eelse` expression.
	**/
	ETernary( econd : Expr, eif : Expr, eelse : Expr );

	/**
		A `(e:t)` expression.
	**/
	ECheckType( e : Expr, t : ComplexType );

	/**
		A `@m e` expression.
	**/
	EMeta( s : MetadataEntry, e : Expr );
}

/**
	Represents a type path in the AST.
**/
@:nativeGen
class TypePath
{
	/**
		Represents the package of the type path.
	**/
	public var pack : NativeArray<String>;

	/**
		The name of the type path.
	**/
	public var name : String;

	/**
		Optional parameters of the type path.
	**/
	@:optional public var params : NativeArray<TypeParam>;

	/**
		Sub is set on module sub-type access:
		`pack.Module.Type` has name = Module, sub = Type, if available.
	**/
	@:optional public var sub : String;
	
	public function new() {}
}

/**
	Represents a variable in the AST.
	@see https://haxe.org/manual/expression-var.html
**/
@:nativeGen
class Var
{
	/**
		The name of the variable.
	**/
	public var name : String;

	/**
		The type-hint of the variable, if available.
	**/
	public var type : Null<ComplexType>;

	/**
		The expression of the variable, if available.
	**/
	public var expr : Null<Expr>;
	
	public function new() {}
}

/**
	Represents a function in the AST.
**/
@:nativeGen
class Function {
	/**
		A list of function arguments.
	**/
	public var args : NativeArray<FunctionArg>;

	/**
		The return type-hint of the function, if available.
	**/
	public var ret : Null<ComplexType>;

	/**
		The expression of the function body, if available.
	**/
	public var expr : Null<Expr>;

	/**
		An optional list of function parameter type declarations.
	**/
	@:optional public var params : NativeArray<TypeParamDecl>;
	
	public function new() {}
}


/**
	Represents a switch case.
	@see https://haxe.org/manual/expression-switch.html
**/
@:nativeGen
class Case
{
	/**
		The value expressions of the case.
	**/
	public var values : NativeArray<Expr>;

	/**
		The optional guard expressions of the case, if available.
	**/
	@:optional public var guard : Null<Expr>;

	/**
		The expression of the case, if available.
	**/
	public var expr: Null<Expr>;
	
	public function new() {}
}

/**
	Represents a catch in the AST.
	@https://haxe.org/manual/expression-try-catch.html
**/
@:nativeGen
class Catch
{
	/**
		The name of the catch variable.
	**/
	public var name : String;

	/**
		The type of the catch.
	**/
	public var type : ComplexType;

	/**
		The expression of the catch.
	**/
	public var expr : Expr;
	
	public function new() {}
}

/**
	Represents a function argument in the AST.
**/
@:nativeGen
class FunctionArg
{
	/**
		The name of the function argument.
	**/
	public var name : String;

	/**
		Whether or not the function argument is optional.
	**/
	@:optional public var opt : Null<Bool>;

	/**
		The type-hint of the function argument, if available.
	**/
	public var type : Null<ComplexType>;

	/**
		The optional value of the function argument, if available.
	**/
	@:optional public var value : Null<Expr>;

	/**
		The metadata of the function argument.
	**/
	@:optional public var meta : NativeArray<MetadataEntry>;
	
	public function new() {}
}

/**
	Represents a concrete type parameter in the AST.

	Haxe allows expressions in concrete type parameters, e.g.
	`new YourType<["hello", "world"]>`. In that case the value is `TPExpr` while
	in the normal case it's `TPType`.
**/
enum TypeParam {
	/**

	**/
	TPType( t : ComplexType );

	/**

	**/
	TPExpr( e : Expr );
}

/**
	Represents a field in the AST.
**/
@:nativeGen
class Field implements FieldResult {
	/**
		The name of the field.
	**/
	public var name : String;

	/**
		The documentation of the field, if available. If the field has no
		documentation, the value is `null`.
	**/
	@:optional public var doc : Null<String>;

	/**
		The access modifiers of the field. By default fields have private access.
		@see https://haxe.org/manual/class-field-access-modifier.html
	**/
	@:optional public var access : NativeArray<Access>;

	/**
		The kind of the field.
	**/
	public var kind : FieldType;

	/**
		The position of the field.
	**/
	public var pos : Position;

	/**
		The optional metadata of the field.
	**/
	@:optional public var meta : NativeArray<MetadataEntry>;
	
	public function new() {}
}

/**
	Represents the field type in the AST.
**/
enum FieldType {
	/**
		Represents a variable field type.
	**/
	FVar( t : Null<ComplexType>, ?e : Null<Expr> );

	/**
		Represents a function field type.
	**/
	FFun( f : Function );

	/**
		Represents a property with getter and setter field type.
	**/
	FProp( get : String, set : String, ?t : Null<ComplexType>, ?e : Null<Expr> );
}

/**
	Represents a type syntax in the AST.
**/
enum ComplexType {
	/**
		Represents the type path.
	**/
	TPath( p : TypePath );

	/**
		Represents a function type.
		@see https://haxe.org/manual/types-function.html
	**/
	TFunction( args : NativeArray<ComplexType>, ret : ComplexType );

	/**
		Represents an anonymous structure type.
		@see https://haxe.org/manual/types-anonymous-structure.html
	**/
	TAnonymous( fields : NativeArray<Field> );

	/**
		Represents parentheses around a type, e.g. the `(Int -> Void)` part in
		`(Int -> Void) -> String`.
	**/
	TParent( t : ComplexType );

	/**
		Represents typedef extensions `> Iterable<T>`.
		The array `p` holds the type paths to the given types.
		@see https://haxe.org/manual/type-system-extensions.html
	**/
	TExtend( p : NativeArray<TypePath>, fields : NativeArray<Field> );

	/**
		Represents an optional type.
	**/
	TOptional( t : ComplexType );
}


//HAXELEXER
@:nativeGen
class Token {
	public var tok: haxeparser.Data.TokenDef;
	public var pos: Position;
	#if keep_whitespace
	public var space = "";
	#end
	
	public function new() {
	}

	public function toString() {
		return haxeparser.Data.TokenDefPrinter.toString(tok);
	}
}