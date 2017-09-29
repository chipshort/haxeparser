package hx;
import byte.ByteData;
import cs.Lib;
import cs.NativeArray;
import cs.internal.Function;
import hx.Ast;
import haxeparser.Data.TokenDef;

/**
 * ...
 * @author Christoph Otter
 */
@:nativeGen
@:classCode("
	public void Define(string flag)
	{
		Define(flag, null);
	}
")
@:keep
class HaxeParser 
{
	@:protected var internalParser : haxeparser.HaxeParser;
	@:protected var internalLexer : haxeparser.HaxeLexer;
	@:protected var internalParseResult : {pack: Array<String>, decls: Array<haxeparser.Data.TypeDecl>};
	@:protected var parseResult : ParseResult;
	@:protected var lexerTokens : NativeArray<Token>;
	@:protected var error : haxeparser.HaxeParser.ParserError;

	public function new(content : String, filename : String) 
	{
		var data = ByteData.ofString(content);
		internalParser = new haxeparser.HaxeParser(data, filename);
		internalLexer = new haxeparser.HaxeLexer(data, filename);
	}
	
	/**
	 * Does the actual parsing / tokenizing. This has to be called before anything else.
	 */
	@:keep
	public function Parse() : Void
	{
		tokenize();
		
		try {
			parse();
		}
		catch (e : haxeparser.HaxeParser.ParserError) {
			error = e;
		}
	}
	
	/**
	 * Get the results from parsing. null if the parsing failed.
	 */
	@:keep
	public function GetParseResult() : ParseResult
	{
		return parseResult;
	}
	
	/**
	 * Get the lexer tokens from parsing.
	 */
	public function GetLexerTokens() : NativeArray<Token>
	{
		return lexerTokens;
	}
	
	/**
	 * Define a flag with an optional value. Call this before calling Parse.
	 */
	@:keep
	public function Define(flag:String, value:Dynamic = null)
	{
		internalParser.define(flag, value);
	}
	
	/**
	 * Get all types declared in the parsed file
	 */
	@:keep
	public function GetTypes() : NativeArray<TypeDecl>
	{
		return parseResult.decls;
	}
	
	/**
	 * Get the token at pos
	 */
	@:keep
	public function GetTokenAt(pos : Int) : Token
	{
		var tokens = GetLexerTokens();
		var i = 0;
		var token = null;
		do {
			token = lexerTokens[i++];
			var p = token.pos;
		} while (i < lexerTokens.Length && !(pos >= token.pos.min && pos <= token.pos.max));

		return token;
	}
	
	@:keep
	public function GetFields(type : hx.Ast.TypeDef) : cs.system.collections.generic.List_1<Field>
	{
		var fields = new cs.system.collections.generic.List_1<Field>();
		for (decl in parseResult.decls) {
			switch (decl.decl) {
				case EAbstract(a):
					untyped __cs__("fields.AddRange(a.data)");
				case EClass(b):
					untyped __cs__("fields.AddRange(b.data)");
				case EEnum(c):
					var array = new NativeArray<Field>(c.data.Length);
					var i = 0;
					for (cnst in c.data) {
						array[i++] = enumConstrToField(cnst);
					}
					untyped __cs__("fields.AddRange(array)");
				case ETypedef(d):
					switch (d.data) {
						case TAnonymous(f):
							untyped __cs__("fields.AddRange(f)");
						default:
					}
				default:
			}
		}
		
		return fields;
	}
	
	@:keep
	public function GetTypeMemberAt(pos : Int) : Field
	{
		var types = GetTypes();
		
		for (t in parseResult.decls) {
			switch (t.decl) {
				case EClass(d):
					for (f in d.data) {
						if (isAtPos(pos, f.pos))
							return f;
					}
				case EAbstract(d):
					for (f in d.data) {
						if (isAtPos(pos, f.pos))
							return f;
					}
				case ETypedef(d):
					switch (d.data) {
						case TAnonymous(fields):
							for (f in fields) {
								if (isAtPos(pos, f.pos))
									return f;
							}
						default:
					}
					
				case EEnum(d):
					for (c in d.data) {
						if (isAtPos(pos, c.pos)) {
							return enumConstrToField(c);
						}
					}
				default:
			}
		}
		
		return null;
	}
	
	@:protected function enumConstrToField(c : EnumConstructor)
	{
		var args = new NativeArray<FunctionArg>(c.args.length);
		var i = 0;
		for (a in c.args) {
			var arg = new FunctionArg();
			arg.name = a.name;
			arg.opt = a.opt;
			arg.type = a.type;
			arg.meta = new NativeArray<MetadataEntry>(0);
			arg.value = null;
			args[i++] = arg;
		}
		var access = new NativeArray<haxe.macro.Expr.Access>(1);
		access[0] = haxe.macro.Expr.Access.APublic;
		var func = new Function();
		func.args = args;
		func.ret = c.type;
		func.params = c.params;
		func.expr = null;
		var field = new Field();
		field.name = c.name;
		field.doc = c.doc;
		field.access = access;
		field.pos = c.pos;
		field.kind = FFun(func);
		
		return field;
	}
	
	@:protected inline function isAtPos(p : Int, pos : haxe.macro.Expr.Position)
	{
		return pos.min <= p && p <= pos.max;
	}
	
	@:protected inline function tokenize() : Void
	{
		var tokens = new Array<haxeparser.Data.Token>();
		try {
			var token : haxeparser.Data.Token;
			do {
				token = internalLexer.token(haxeparser.HaxeLexer.tok);
				tokens.push(token);
			}
			while (token.tok != TokenDef.Eof);
		}
		catch (e : Dynamic) { trace(e); }
		
		lexerTokens = InteropMacro.convert(tokens);
	}
	
	@:protected inline function parse() : Void
	{
		internalParseResult = internalParser.parse();
		parseResult = InteropMacro.convert(internalParseResult);
	}
}