#!perl

use strict;
use warnings;

use blib 't/Sub-Op-LexicalSub';

use Test::More tests => (4 + 2 * 4) + (2 * 5);

our $call_foo;
sub foo { ok $call_foo, 'the preexistent foo was called' }

our $called;

{
 local $/ = "####\n";
 while (<DATA>) {
  my ($code, $params)           = split /----\s*/, $_;
  my ($names, $ret, $exp, $seq) = split /\s*#\s*/, $params;

  my @names = split /\s*,\s*/, $names;

  my @exp = eval $exp;
  if ($@) {
   fail "@names: unable to get expected values: $@";
   next;
  }
  my $calls = @exp;

  my @seq;
  if ($seq) {
   s/^\s*//, s/\s*$//  for $seq;
   @seq = split /\s*,\s*/, $seq;
   die "calls and seq length mismatch" unless @seq == $calls;
  } else {
   @seq = ($names[0]) x $calls;
  }

  my $test = "{\n";
  for my $name (@names) {
   $test .= <<"   INIT"
    use Sub::Op::LexicalSub $name => sub {
     ++\$called;
     my \$exp = shift \@exp;
     is_deeply \\\@_, \$exp,   '$name: arguments are correct';
     my \$seq = shift \@seq;
     is        \$seq, '$name', '$name: sequence is correct';
     $ret;
    };
   INIT
  }
  $test .= "{\n$code\n}\n";
  $test .= "}\n";

  local $called = 0;
  eval $test;
  if ($@) {
   fail "@names: unable to evaluate test case: $@";
   diag $test;
  }

  is $called, $calls, "@names: the hook was called the right number of times";
  if ($called < $calls) {
   fail for $called + 1 .. $calls;
  }
 }
}

__DATA__
foo();
----
foo # () # [ ]
####
foo;
----
foo # () # [ ]
####
foo(1);
----
foo # () # [ 1 ]
####
foo 2;
----
foo # () # [ 2 ]
####
local $call_foo = 1;
&foo();
----
foo # () #
####
local $call_foo = 1;
&foo;
----
foo # () #
####
local $call_foo = 1;
&foo(3);
----
foo # () #
####
local $call_foo = 1;
my $foo = \&foo;
$foo->();
----
foo # () #
####
local $call_foo = 1;
my $foo = \&foo;
&$foo;
----
foo # () #
