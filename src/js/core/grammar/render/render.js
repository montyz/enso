var requirejs = require('requirejs');
requirejs.config({ nodeRequire: require, baseUrl: 'js' });
requirejs([
  "enso",
  "core/system/load/load",
  "core/grammar/render/layout"
],
function(Enso, Load, Layout) {
  var outname, outgrammar, filename;
  if (! ARGV._get(0)) {
    System.stderr().push("Usage: render.rb <model> [grammar] -o <output>");
    exit_in_place(1);
  }
  name = ARGV._get(0);
  if (ARGV.size() > 1) {
    if (ARGV._get(1) == "-o") {
      outname = ARGV._get(1);
    } else {
      outgrammar = ARGV._get(1);
      if (ARGV._get(2) == "-o") {
        outname = ARGV._get(3);
      }
    }
  }
  if (! outgrammar) {
    filename = name.split("/")._get(- 1);
    outgrammar = filename.split(".")._get(- 1);
  }
  if (outname) {
    out = File.new(outname, "w");
  } else {
    out = System.stdout();
  }
  m = Load.load(name);
  g = Load.load(S(outgrammar, ".grammar"));
  System.stderr().push(S("## Printing ", ARGV._get(0), "...\n"));
  Layout.DisplayFormat.print(g, m, out, false); })
