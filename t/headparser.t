print "1..2\n";

{ package H;
  sub new { bless {}, shift; }

  sub header {
     my $self = shift;
     my $key  = uc(shift);
     my $old = $self->{$key};
     if (@_) { $self->{$key} = shift; }
     $old;     
  }

  sub push_header {
     my($self, $k, $v) = @_;
     $k = uc($k);
     if (exists $self->{$k}) {
        $self->{$k} = [ $self->{$k} ] unless ref $self->{$k};
	push(@{$self->{$k}}, $v);
     } else {
	$self->{$k} = $v;
     }
  }

  sub as_string {
     my $self = shift;
     my $str = "";
     for (sort keys %$self) {
         if (ref($self->{$_})) {
            my $v;
            for $v (@{$self->{$_}}) {
	        $str .= "$_: $v\n";
            }
         } else {
            $str .= "$_: $self->{$_}\n";
         }
     }
     $str;
  }
}


$HTML = <<'EOT';

<title>&Aring v�re eller &#229; ikke v�re</title>
<meta http-equiv="Expires" content="Soon">
<meta http-equiv="Foo" content="Bar">
<link href="mailto:aas@sn.no" rev=made title="Gisle Aas">

<script>

    ignore this

</script>

<base href="http://www.sn.no">
<meta name="Keywords" content="test, test, test,...">
<meta name="Keywords" content="more">

Dette er vanlig tekst.  Denne teksten definerer ogs� slutten p�
&lt;head> delen av dokumentet.

<style>

   ignore this too

</style>

<isindex>

Dette er ogs� vanlig tekst som ikke skal blir parset i det hele tatt.

EOT

$| = 1;

#$HTML::HeadParser::DEBUG = 1;
require HTML::HeadParser;
$p = HTML::HeadParser->new( H->new );

$bad = 0;

print "\n#### Parsing full text...\n";
if ($p->parse($HTML)) {
    $bad++;
    print "Need more data which should not happen\n";
} else {
    print $p->as_string;
}

$p->header('Title') =~ /� v�re eller � ikke v�re/ or $bad++;
$p->header('Expires') eq 'Soon' or $bad++;
$p->header('Content-Base') eq 'http://www.sn.no' or $bad++;
$p->header('Link') =~ /<mailto:aas\@sn.no>/ or $bad++;

# This header should not be present because the head ended
$p->header('Isindex') and $bad++;

print "not " if $bad;
print "ok 1\n";


# Try feeding one char at a time
print "\n\n#### Parsing once char at a time...\n";
$expected = $p->as_string;
$p = HTML::HeadParser->new(H->new);
while ($HTML =~ /(.)/sg) {
    print $1;
    $p->parse($1) or last;
}
print "���� Enough!!\n";
$got = $p->as_string;
print "$got";
print "not " if $expected ne $got;
print "ok 2\n";
