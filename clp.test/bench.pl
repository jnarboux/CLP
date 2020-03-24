#!/usr/bin/env perl
# author : bjarneh@ifi.uio.no
# license: beerware

use warnings;
use strict;
use Switch;
use feature 'say'; # :-)
use Proc::Reliable;
use Getopt::Long;
use Term::ANSIColor;
use Time::HiRes;
use File::Temp;
use Data::Dumper;

# command line options
my %opts = ('help' => 0,
            'time' => 3,
            'only' => 'all',
            'file=s' => '',
            'ansi' => 0,
            'quiet' => 0,
            'what' => 'plain',
            'dry'   => 0);

# results of all tests
my %results = ('clp' => {}, 'clp -G' => {}, 'CL.pl' => {}, 'colog' => {}, 'vampire' => {}, 'eprover' => {}, 'leancop' => {}, 'Geo' => {});

# use ANSI colors on these if --ansi
my $OK = 'ok';
my $NO = 'no';

# the different formats (same formulas though)
my @bezFiles = glob('formats/Bezem/*.in');
my @fishFiles = glob('formats/Fisher/*.gl');
my @tptpFiles = glob('formats/TPTP/*.p');

# run subprocesses with Proc:Reliable
my $process = Proc::Reliable->new();

my $helpmessage='
 bench.pl - benchmarking tool

 usage: ./bench.pl [OPTIONS]

 options:

   -h --help  : print this menu and exit
   -f --file  : results -> file (default:stdout)
   -o --only  : legal values: CL.pl,clp,colog,Geo
   -t --time  : timeout in seconds (default:3)
   -a --ansi  : turn on ANSI colored output
   -q --quiet : do not report anything during run
   -d --dry   : dryrun, print what bench.pl would do
   -w --what  : what format [plain,md,tex,html]
';

# initialization of this n that..
sub init {
    if($opts{'ansi'}){
        $OK = color('green') . $OK . color('reset');
        $NO = color('red') . $NO . color('reset');
    }

    # timeout for subprocesses
    $process->maxtime($opts{'time'});
}

# parse command line arguments with Getopt::Long...
sub parseArgv {
    my $ok = GetOptions ('help' => \$opts{'help'},
                         'time=i' => \$opts{'time'},
                         'file=s' => \$opts{'file'},
                         'only=s' => \$opts{'only'},
                         'ansi' => \$opts{'ansi'},
                         'quiet' => \$opts{'quiet'},
                         'what=s' => \$opts{'what'},
                         'dry' => \$opts{'dry'});
    if( ! $ok ){
        usage()
    }
}

sub sanity {

    # are the required executables in place?
    my @executables = ('java', 'swipl', 'clp', 'geo', 'eprover');
    for (@executables) {
       usage("[ERROR] missing executable: '$_'") unless which($_);
    }

    # are we getting funky arguments
    my @legal = ('clp', 'clp -G', 'CL.pl', 'colog', 'all', 'Geo', 'vampire', 'eprover', 'leanCop');
    unless ( grep( { $_ eq $opts{'only'} } @legal ) ){
        usage("[ERROR] legal values for --only: CL.pl, clp, colog")
    }

    # are we getting funky arguments
    @legal = ('plain', 'html', 'tex', 'md');
    unless ( grep( { $_ eq $opts{'what'} } @legal ) ){
        usage("[ERROR] legal values for --what: plain, html, tex, md")
    }
}

# print help menu and error (if any)
sub usage {

    my $failed = 0;

    if ( @_ ) {
        say shift;
        $failed = 1;
    }

    say $helpmessage;

    exit($failed);
}

# look for executables in $PATH
sub which {

    my $what = shift;
    my $path = $ENV{'PATH'};

    for(split(/:/, $path)) {
        if( -x join('/', $_, $what) ) {
            return 1;
        }
    }
    return 0;
}

sub runClp {

    my $prover = "clp";
    my $argv = "clp -m 0 -CM";

    for (@bezFiles) {
        my ($status, $used) = runCmd("$argv -w $opts{'time'} $_");
        if( ! $opts{'dry'} ) {
            fmtResult($prover, $status, $used, $_);
            $results{'clp'}{nameFromPath($_)} = [$status,$used];
        }
    }

}

sub runVampire {

    my $prover = "vampire";
    my $argv = "vampire --proof tptp --mode casc -t $opts{'time'} ";

    for (@tptpFiles) {
        my ($status, $used) = runCmd("cat $_ | $argv ");
        if( ! $opts{'dry'} ) {
            fmtResult($prover, $status, $used, $_);
            $results{'vampire'}{nameFromPath($_)} = [$status,$used];
        }
    }

}

sub runGeo {

    my $prover = "Geo";
    my $argv = "geo -nonempty -tptp_input -inputfile ";

    for (@tptpFiles) {
        my ($status, $used) = runCmd("$argv $_");
        if( ! $opts{'dry'} ) {
            fmtResult($prover, $status, $used, $_);
            $results{'Geo'}{nameFromPath($_)} = [$status,$used];
        }
    }

}

sub runLeancop {

    my $prover = "leancop";
    my $argv = "./leancop.sh";

    chdir("leancop");
    for (@tptpFiles) {
        my ($status, $used) = runCmd("$argv ../$_");
        if( ! $opts{'dry'} ) {
            fmtResult($prover, $status, $used, $_);
            $results{'leancop'}{nameFromPath($_)} = [$status,$used];
        }
	runCmd("killall swipl");
    }
    chdir("..");
}


sub runEprover {

    my $prover = "eprover";
    my $argv = "eprover -s --print-statistics -xAuto -tAuto --cpu-limit=$opts{'time'} --memory-limit=Auto --tptp3-format --answers";

    for (@tptpFiles) {
        my ($status, $used) = runCmd("$argv $_");
        if( ! $opts{'dry'} ) {
            fmtResult($prover, $status, $used, $_);
            $results{'eprover'}{nameFromPath($_)} = [$status,$used];
        }
    }

}


sub runClpGl {

    my $prover = "clp -G";
    my $argv = "clp -m 0 -GM";

    for (@fishFiles) {
        my ($status, $used) = runCmd("$argv $_");
        if( ! $opts{'dry'} ) {
            fmtResult($prover, $status, $used, $_);
            $results{'clp -G'}{nameFromPath($_)} = [$status,$used];
        }
    }

}


sub runCLpl {

    my $prover = "CL.pl    ";
    my ($formula, $fname) = undef, undef;
    my $argv = "swipl -s";

    for (@bezFiles) {

        $formula = nameFromPath($_);
        $fname   = "CL/tmp/$formula.in";

        if( ! -f $fname ) {
            open( FH, ">$fname" );
            print( FH ":- consult('CL/CL'), test('formats/Bezem/" . $formula . "'), halt.\n" );
            close( FH );
        }

        my ($status, $used) = runCmd("$argv $fname");
        if( ! $opts{'dry'} ) {
            fmtResult($prover, $status, $used, $_);
            $results{'CL.pl'}{$formula} = [$status,$used];
        }
    }

}

sub runColog {

    my $prover = "colog 1.9";
    my $argv = "./run_colog.sh  width=100000 depth=100000 ";

    for (@fishFiles) {
        my ($status, $used) = runCmd("$argv file=$_");
        if( ! $opts{'dry'} ) {
            fmtResult($prover, $status, $used, $_);
            $results{'colog'}{nameFromPath($_)} = [$status,$used];
        }
	runCmd("killall java");
    }
}

# run and time cmd (wall clock)
sub runCmd {

    my $argv = shift;

    if( $opts{'dry'} ){
        say $argv;
        return undef, undef;
    }

    my $start_time = [Time::HiRes::gettimeofday()];

    $process->run($argv);

    return $process->status, Time::HiRes::tv_interval($start_time);

}

sub runAll {
    runGeo();
    runVampire();
    runEprover();
    runClpGl();
    runClp();
    runCLpl();
    runLeancop();
    runColog();
}


sub fmtResult {

    my ($what, $status, $used, $name) = @_;
    my $report = ($status)? $NO : $OK;

    if ( ! $opts{'quiet'} ) {
        printf("%s  -  %s  -  wclock: %5.3fs  -  %s\n",
               $what, $report, $used, nameFromPath($name));
   }
}

# formula name from path to file
sub nameFromPath {

    my $pathName = shift;

    if( $pathName =~ m/^.+\/([^\/]+)\.(in|gl|p)$/) {
        return $1;
    }

    die("[ERROR] '$pathName' not a valid filename");
}


sub outPlain {

    my $FH = undef;
    my @provers = undef;
    my %set = (); # use hash to make set of formulas

    for my $prover (keys %results) {
        for my $frml (keys %{$results{$prover}}){
            $set{$frml} = 1;
        }
    }

    switch ( $opts{'only'} ) {
        case "all"   { @provers = ('CL.pl', 'clp', 'vampire', 'eprover', 'leancop', 'Geo', 'colog'); }
        case "clp"   { @provers = ('clp'); }
        case "CL.pl" { @provers = ('CL.pl'); }
        case "colog" { @provers = ('colog'); }
        case "eprover" { @provers = ('eprover'); }
        case "vampire" { @provers = ('vampire'); }
        case "leancop" { @provers = ('leancop'); }
        case "Geo" { @provers = ('Geo'); }
    }

    if($opts{'file'}) {
        open( $FH, ">$opts{'file'}" );
        $opts{'ansi'} = 0; # don't write ANSI sequences to file
    }else{
        open( $FH, ">-" ); # STDOUT
    }

    my $timeoutLength = length($opts{'time'});
    my @longest = sort { length($a) cmp length($b) } keys(%set);
    my $columnWidth = length( pop( @longest ));
    if( $columnWidth < (18 + $timeoutLength) ){ $columnWidth = 18 + $timeoutLength; }
    my $numWidth = $timeoutLength + 5;
    my $spacerResult = "     ";

    printf $FH  "\n%${columnWidth}s", "";
    for (@provers) {        printf $FH "%-${columnWidth}s", $_;
    }
    print $FH "\n\n";


    for my $f (sort keys %set){
        printf $FH "%-${columnWidth}s", $f;
        for my $p (@provers) {
            if( exists $results{$p}{$f} ){
                my $res = undef;
                if( $results{$p}{$f}[0] ){
                    $res = ($opts{'ansi'})? $NO : "no";
                }else{
                    $res = ($opts{'ansi'})? $OK : "ok";
                }
                printf $FH "%s  - %$numWidth.3fs %s", $res, $results{$p}{$f}[1], $spacerResult ;
            }else{
                printf $FH "%${columnWidth}s", "";
            }
        }
        print $FH "\n";
    }
    print $FH "\n";

    # close normal files (not STDOUT)
    if($opts{'file'}) {
        close $FH;
    }
}

# output googlecode markdown
sub outMD {

    my $FH = undef;
    my @provers = undef;
    my %set = (); # use hash to make set of formulas

    for my $prover (keys %results) {
        for my $frml (keys %{$results{$prover}}){
            $set{$frml} = 1;
        }
    }

    switch ( $opts{'only'} ) {
        case "all"   { @provers = ('CL.pl', 'clp', 'clp -G', 'vampire', 'eprover', 'leancop', 'Geo', 'colog'); }
        case "clp"   { @provers = ('clp'); }
        case "CL.pl" { @provers = ('CL.pl'); }
        case "colog" { @provers = ('colog'); }
        case "Geo" { @provers = ('Geo'); }
        case "vampire" { @provers = ('vampire'); }
        case "eprover" { @provers = ('eprover'); }
        case "leanCop" { @provers = ('leanCop'); }
    }

    if($opts{'file'}) {
        open( $FH, ">$opts{'file'}" );
    }else{
        open( $FH, ">-" ); # STDOUT
    }


    print $FH  "||*formula*|";
    for (@provers) {
        printf $FH "| *%s* |", $_;
    }
    print $FH "|\n";


    for my $f (sort keys %set){
        printf $FH "|| %-15s |", $f;
        for my $p (@provers) {
            if( exists $results{$p}{$f} ){
                my $res = ($results{$p}{$f}[0])? "no" : "ok";
                printf $FH "| %s  - %.3fs |", $res, $results{$p}{$f}[1];
            }else{
                print $FH "| N/A |";
            }
        }
        print $FH "|\n";
    }
    print $FH "\n";

    # close normal files (not STDOUT)
    if($opts{'file'}) {
        close $FH;
    }
}

# plain HTML table
sub outHTML {
    my $FH = undef;
    my @provers = undef;
    my %set = (); # use hash to make set of formulas

    for my $prover (keys %results) {
        for my $frml (keys %{$results{$prover}}){
            $set{$frml} = 1;
        }
    }

    switch ( $opts{'only'} ) {
        case "all"   { @provers = ('CL.pl', 'clp', 'clp -G', 'vampire', 'eprover', 'leancop', 'Geo', 'colog'); }
        case "clp"   { @provers = ('clp'); }
        case "CL.pl" { @provers = ('CL.pl'); }
        case "colog" { @provers = ('colog'); }
        case "Geo" { @provers = ('Geo'); }
        case "vampire" { @provers = ('vampire'); }
        case "eprover" { @provers = ('eprover'); }
        case "leanCop" { @provers = ('leanCop'); }
    }

    if($opts{'file'}) {
        open( $FH, ">$opts{'file'}" );
    }else{
        open( $FH, ">-" ); # STDOUT
    }

    print $FH  "<table border=1>\n";

    print $FH  "<tr>\n<td> <b>formula</b> </td>";
    for (@provers) {
        printf $FH "<td> %s </td> ", $_;
    }
    print $FH "</tr>\n";


    for my $f (sort keys %set){
        printf $FH "<tr>\n<td> %s </td> ", $f;
        for my $p (@provers) {
            if( exists $results{$p}{$f} ){
                my $res = ($results{$p}{$f}[0])? "no" : "ok";
                printf $FH "<td> %s  - %.3fs </td> ", $res, $results{$p}{$f}[1];
            }else{
                print $FH "<td> N/A </td> ";
            }
        }
        print $FH "</tr>\n";
    }
    print $FH "</table>\n";

    # close normal files (not STDOUT)
    if($opts{'file'}) {
        close $FH;
    }
}

sub outTex {
    say "TODO";
}


# main
{

    parseArgv();
    sanity();
    init();

    if( $opts{'help'} ){
        usage();
    }

    switch ( $opts{'only'} ) {
        case "all" { runAll(); }
        case "clp" { runClp(); }
        case "clp -G" { runClpGl(); }
        case "CL.pl" { runCLpl(); }
        case "colog" { runColog(); }
        case "Geo" { runGeo(); }
	case "leanCop" { runLeancop(); }
	case "vampire" { runVampire(); }
	case "eprover" { runEprover(); }
    }

    # don't write results in dryrun :-)
    if( ! $opts{'dry'} ) {
        switch( $opts{'what'} ) {
            case "plain" { outPlain(); }
            case "md" { outMD(); }
            case "html" { outHTML(); }
            case "tex" { outTex(); }
        }
    }
}
