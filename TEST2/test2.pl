#!/usr/bin/env perl

use 5.014;
use warnings;
use utf8;
use LWP::Simple;
use HTML::Entities;
use Path::Tiny;

my $index_url = "http://www.isds.duke.edu/courses/Spring01/sta114/data/andrews.html";

my $wanted_table = shift || '';

my $index_html = get($index_url) or die "Error retrieving index";
# Sample match
#<TR><TD><A href="Andrews/T08.1">Table &nbsp; 8.1</A></TD><TD>Number of
#    Coal-Mining Disasters between March 15, 1851 and March 22, 1962</TD></TR>
# We could be more exact in our matching using negative lookaheads, but non-greedy is sufficient for this.
my $table_row_regex = qr{
    <TR>\s*
        <TD>\s*
            <A\s+href="([^"]+)"\s*>\s*([^<]+)</A>\s*
        </TD>\s*
        <TD>\s*
            (.*?) # Minimally matching
        </TD>\s*
    </TR>
}smxi;

# Retrieve table names and links into a data structure
#my %raw_links = $index_html =~ m/$table_row_regex/gsmi;

my %links;
my $index_base_url = $index_url =~ s{/[^/]*$}{}gr;
my $months_regex = qr{\b(?:january|february|march|april|may|june|july|august|september|october|november|december)\b}i;
#while (my ($link,$table_name) = each %raw_links) {
while ( $index_html =~ m/$table_row_regex/gsmi ) {
    my ($link,$table_name,$desc) = ($1,$2,$3);
    # Skip descriptions without month names
    next unless  $desc =~ m{$months_regex}i;
    # Decode HTMLentities, remove duplicate spaces, trim leading/trailing whitespace
    $table_name = decode_entities( $table_name );
    $table_name =~ s/\s\s+/ /g;
    $table_name =~ s/^\s+|\s+$//g;
    # Create absolute URL
    $link = join '/', $index_base_url, $link;
    # Add to links hash
    $links{$table_name} = $link;
}

# print table name / link for links not including month names
say "$_\t$links{$_}" for keys %links;

if ( my $download_url = $links{"Table $wanted_table"} ) {
    my $download_data = get($download_url) or die "No download data found at $download_url";
    path("output.dat")->spew_utf8( $download_data );
}
