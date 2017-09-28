package hx;
import byte.ByteData;
import cs.Lib;
import cs.NativeArray;
import hx.Ast;
import haxeparser.Data.TypeDecl;
import haxeparser.Data.Token;
import haxeparser.Data.TokenDef;

/**
 * ...
 * @author Christoph Otter
 */
@:nativeGen
class HaxeParser 
{
	@:protected var internalParser : haxeparser.HaxeParser;
	@:protected var internalLexer : haxeparser.HaxeLexer;

	public function new(content : String, filename : String) 
	{
		var data = ByteData.ofString(content);
		internalParser = new haxeparser.HaxeParser(data, filename);
		internalLexer = new haxeparser.HaxeLexer(data, filename);
	}
	
	public function GetLexerTokens() : NativeArray<Token>
	{
		var tokens = new Array<Token>();
		try {
			var token : Token;
			do {
				token = internalLexer.token(haxeparser.HaxeLexer.tok);
				tokens.push(token);
			}
			while (token.tok != TokenDef.Eof);
		}
		catch (e : Dynamic) { trace(e); }
		
		return Lib.nativeArray(tokens, true);
	}
	
	public function Define(flag:String, value:Dynamic = null)
	{
		internalParser.define(flag, value);
	}

	public function Parse() : ParseResult
	{
		var r : {pack: Array<String>, decls: Array<haxeparser.Data.TypeDecl>} = internalParser.parse();
		
		return InteropMacro.convert(r);
	}
}