package hx;
import byte.ByteData;
import hx.Ast;
import haxeparser.Data.TypeDecl;

/**
 * ...
 * @author Christoph Otter
 */
@:nativeGen
class HaxeParser 
{
	@:protected var internalParser : haxeparser.HaxeParser;

	public function new(content : String, filename : String) 
	{
		internalParser = new haxeparser.HaxeParser(ByteData.ofString(content), filename);
	}
	
	public function define(flag:String, value:Dynamic = null)
	{
		internalParser.define(flag, value);
	}

	public function parse() : ParseResult
	{
		var r : {pack: Array<String>, decls: Array<haxeparser.Data.TypeDecl>} = internalParser.parse();
		
		return InteropMacro.convert(r);
	}
}