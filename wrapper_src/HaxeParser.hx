package;
import hx.util.CsharpConverter;
/**
 * ...
 * @author Christoph Otter
 */
class HaxeParser 
{
	static function main() {
		var parser = new hx.HaxeParser(sys.io.File.getContent("src/haxeparser/HaxeParser.hx"), "HaxeParser.hx");
		var result = parser.Parse();
		trace(result);
	}
	
	
}