#!/usr/bin/perl -w

use strict;
my $tag;
my $text;

use HTML::Parser ();
my $p = HTML::Parser->new(start_h => [sub { $tag = shift  }, "tagname"],
	                  text_h  => [sub { $text .= shift }, "dtext"],
                         );

eval {
    $p->marked_sections(1);
};
if ($@) {
    print $@;
    print "1..0\n";
    exit;
}

print "1..11\n";

$p->parse("<![[foo]]>");
print "not " unless $text eq "foo";
print "ok 1\n";

$p->parse("<![TEMP INCLUDE[bar]]>");
print "not " unless $text eq "foobar";
print "ok 2\n";

$p->parse("<![ INCLUDE -- IGNORE -- [foo<![IGNORE[bar]]>]]>\n<br>");
print "not " unless $text eq "foobarfoo\n";
print "ok 3\n";

$text = "";
$p->parse("<![  CDATA   [&lt;foo");
$p->parse("<![IGNORE[bar]]>,bar&gt;]]><br>");
print "not " unless $text eq "&lt;foo<![IGNORE[bar,bar>]]>";
print "ok 4\n";

$text = "";
$p->parse("<![ RCDATA [&aring;<a>]]><![CDATA[&aring;<a>]]>&aring;<a><br>");
print "not " unless $text eq "�<a>&aring;<a>�" && $tag eq "br";
print "ok 5\n";

$text = "";
$p->parse("<![INCLUDE RCDATA CDATA IGNORE [foo&aring;<a>]]><br>");
print "not " unless $text eq "";
print "ok 6\n";

$text = "";
$p->parse("<![INCLUDE RCDATA CDATA [foo&aring;<a>]]><br>");
print "not " unless $text eq "foo&aring;<a>";
print "ok 7\n";

$text = "";
$p->parse("<![INCLUDE RCDATA [foo&aring;<a>]]><br>");
print "not " unless $text eq "foo�<a>";
print "ok 8\n";

$text = "";
$p->parse("<![INCLUDE [foo&aring;<a>]]><br>");
print "not " unless $text eq "foo�";
print "ok 9\n";

$text = "";
$p->parse("<![[foo&aring;<a>]]><br>");
print "not " unless $text eq "foo�";
print "ok 10\n";

# offsets/line/column numbers
$p = HTML::Parser->new(default_h => [\&x, "line,column,offset,text"],
		       marked_sections => 1,
		      );
$p->parse(<<'EOT')->eof;
<title>Test</title>
<![CDATA
  [foo&aring;<a>
]]>
<![[
INCLUDE
STUFF
]]>
  <h1>Test</h1>
EOT

my @x;
sub x {
    my($line, $col, $offset, $text) = @_;
    $text =~ s/\n/\\n/g;
    $text =~ s/ /./g;
    push(@x, "$line.$col:$offset $text\n");
}

#print @x;
print "not " unless join("", @x) eq <<'EOT';
1.0:0 <title>
1.7:7 Test
1.11:11 </title>
1.19:19 \n
3.3:29 foo&aring;<a>\n
4.3:46 \n
5.1:48 \nINCLUDE\nSTUFF\n
8.3:66 \n..
9.2:69 <h1>
9.6:73 Test
9.10:77 </h1>
9.15:82 \n
EOT
print "ok 11\n";
