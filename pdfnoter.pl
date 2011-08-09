#!/usr/bin/perl 
#==============================================================================#
#                                                                              #
# Copyright 2011 Carlos Alberto da Costa Filho                                 #
#                                                                              #
# This program is free software: you can redistribute it and/or modify         #
# it under the terms of the GNU General Public License as published by         #
# the Free Software Foundation, either version 3 of the License, or            #
# (at your option) any later version.                                          #
#                                                                              #
# This program is distributed in the hope that it will be useful,              #
# but WITHOUT ANY WARRANTY; without even the implied warranty of               #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the                 #
# GNU General Public License for more details.                                 #
#                                                                              #
# You should have received a copy of the GNU General Public License            #
# along with this program. If not, see <http://www.gnu.org/licenses/>.         #
#                                                                              #
#==============================================================================#

use 5.010;
use strict;
use warnings;
use File::Spec;
use File::Basename;

# Preliminary hash for paper sizes. Incomplete.
sub get_number_of_pages {
    my $input_pdf = $_[0];
    my $pages_data;
    my $pages;
    if ($^O =~ m/win/i){
        chomp($pages_data = `pdftk $input_pdf dump_data`);
    } else {
        chomp($pages_data = `pdftk '$input_pdf' dump_data`);
    }
    if ($pages_data =~ /NumberOfPages:\s*(\d+)/){
        $pages = $1;
    } else {
        die "Cannot get page number!";
    }
    return $pages;

}
sub get_size {
    my $input_pdf = $_[0];
    
    # Paper formats hash
    my %paper_sizes;
    $paper_sizes{"letter"} = "letterpaper";
    $paper_sizes{"A4"} = "a4paper";

    my $width_data;
    if ($^O =~ m/win/i){
        chomp($width_data = `pdfinfo $input_pdf`);
    } else {
        chomp($width_data = `pdfinfo '$input_pdf'`);
    }
    # The numbers are (?<width>\d+(\.\d+) and the paper size is (?<paper>\w+)
    $width_data =~ /Page \s size: \s+ (?<width>\d+(\.\d+)?) \s x \s (?<len>\d+(\.\d+)?) \s pts \s+ ( \( (?<paper>\w+) \) )?/x;
    my $width = $+{width};
    my $len = $+{len};
    my $paper;
    if ($+{paper}){
        $paper = $+{paper};
    } else {
        $paper = '';
    }
    my $doc_opts;
    if ($paper_sizes{$paper}){
        $doc_opts = "\[$paper_sizes{$paper}\]";
    } else {
        $doc_opts = '';
    }
    return ($width, $len, $doc_opts);
}

# Begin MAIN
die "Not enough options" if (scalar (@ARGV) < 2);
my ($input_pdf, $annotations_file) = @ARGV;
die "$annotations_file does not exist." unless (-e $annotations_file);
die "$input_pdf does not exist." unless (-e $input_pdf);
#say "file: $annotations_file";
#say "pdf: $input_pdf";

# PDF info
my $pages = &get_number_of_pages($input_pdf);  
my ($width, $len, $doc_opts) = &get_size($input_pdf);

print "Generating auxiliary .tex mask from $annotations_file. ";
my $tex_contents = <<END;
\\newcommand\{\\numberofpages\}\{$pages\}
\\newcommand\{\\pagewidth\}\{$width\}
\\newcommand\{\\pagelength\}\{$len\}
END
$tex_contents = '\documentclass' . $doc_opts . '{article}' . "\n" . $tex_contents;  
my $tex_contents_rest = <<'END';
% GEOMETRY PACKAGE
% Necessary to add text to any part of the document.
\usepackage{geometry}
\geometry{papersize={\pagewidth pt,\pagelength pt}, total={\pagewidth pt,\pagelength pt}, scale=1}

\usepackage[absolute]{textpos}

% PACKAGES
\usepackage{amsmath}  
\usepackage{amssymb}
\usepackage{color}

% USER DEFINED PACKAGES
END
$tex_contents .= $tex_contents_rest;

open  ANNOT, '<', $annotations_file
    or die  "$0 : failed to open  input file '$annotations_file' : $!\n";

my %notes;
my %in_tags;
$notes{'packages'} = ''; # Initialize 'packages' to not mess up notes offset.
while (<ANNOT>) {
    my $line = $_;
    if ($line =~ /^<begin:packages>/){
        $in_tags{'packages'} = 1;
    } elsif ($line =~ /^<end:packages>/){
        $in_tags{'packages'} = 0;
    } elsif ($line =~ /^<begin:note>/){
        my $new_note = scalar(keys %notes); # Don't add one, the inclusion of 'packages' as a note takes care of the offset.
        $in_tags{"$new_note"} = 1;
        $notes{"$new_note"} = '';
    } elsif ($line =~ /^<end:note>/){
        my $last_note = scalar(keys %notes) - 1; # Again, the -1 is because of 'packages' being included.
        $in_tags{"$last_note"} = 0;
    }
    # Find which tag is in
    my @in_now = grep { $in_tags{$_} == 1 } keys %in_tags;
    warn "You shouldn't have more than one tag open at once! Funky stuff is bound to happen." if (scalar(@in_now) > 1); 
    if ($in_now[0]) {
        $notes{$in_now[0]} = $notes{$in_now[0]} . $line unless ($line =~ /^<begin:(packages|note)/);
    }
}
close  ANNOT
    or warn "$0 : failed to close input file '$annotations_file' : $!\n";

$tex_contents .= $notes{'packages'};
delete $notes{'packages'};
$tex_contents_rest = <<'END';

% STAMPING COMMANDS
\newcommand{\multistamp}[1]{%
  \loop\unless\ifnum\value{page}>#1
    \dowhatsonthispage
  \repeat}

\newcommand{\dowhatsonthispage}{%
  \null\csname onthispage\thepage\endcsname\newpage}

\newcommand{\putonpage}[2]{%
  \expandafter\def\csname onthispage#1\endcsname{#2}}
  

\begin{document}

% HEADER
\pagestyle{empty} %no pagenumbers and titles%
\thispagestyle{empty}

% BEGIN ANNOTATIONS
END

$tex_contents .= $tex_contents_rest;

# In the %pages hash, the keys are the pages.
# The values are arrays.
# The arrays consist of all notes that are to be places on the page specified by the key
my %pages;
for my $note_number (sort keys %notes){
    $notes{$note_number} =~ /^(?<page>.+)(\s+)?,(\s+)?(?<size>.+)(\s+)?,(\s+)?(?<x>.+)(\s+)?,(\s+)?(?<y>.+)(\s+)?\n/;
    my $page_number = $+{page};
    push @{ $pages{"$page_number"} }, $note_number;
    #say "Added note $note_number to page $page_number.";
}

#for my $page (keys %pages){
    #say "Page $page : ";
    #for my $i (0..$#{ $pages{$page} } ){
        #print "\tNote $i is: $pages{$page}[$i]"; 
    #}
    #print "\n";
#}

for my $page (sort keys %pages){
    if ($page > $pages){
        print "Any note placed on page $page will be ignored; the document is only $pages long.\n";
        next;
    }
    $tex_contents .= '\putonpage{' . $page . "\}\{\n";

    for my $note_number (@{ $pages{$page} }){
        $notes{$note_number} =~ /^(?<page>.+),( )?(?<size>.+),( )?(?<x>.+),( )?(?<y>.+)\n/;
        my ($width, $x_pos, $y_pos) = ($+{size}, $+{x}, $+{y});
        my ($width_unit, $x_unit, $y_unit);

        $width =~ /(?<w>.+)(?<w_unit>\w{2})/; 
        ($width, $width_unit) = ($+{w}, $+{w_unit});

        $x_pos =~ /(?<x>.+)(?<x_unit>\w{2})/; 
        ($x_pos, $x_unit) = ($+{x}, $+{x_unit});

        $y_pos =~ /(?<y>.+)(?<y_unit>\w{2})/; 
        ($y_pos, $y_unit) = ($+{y}, $+{y_unit});
        #say "Note $note_number";
        #say "x_unit: $x_unit\nx value: $x_pos\ny_unit: $y_unit\ny value: $y_pos\n";
        # Convert $width and $x_pos to pt so both that units match. Necessary for textpos
        my %convert_factor = ('pt', 1, 'mm', 2.84, 'cm', 28.4, 'in', 72.27);
        $width *= $convert_factor{"$width_unit"};
        $x_pos *= $convert_factor{"$x_unit"};
        say "\nwidth_unit of note $note_number : $width_unit";
        say "x_pos_unit of note $note_number : $x_unit";
        say "width of note $note_number : $width";
        say "x_pos of note $note_number : $x_pos";
        print "\n";
        $tex_contents .= "\n";
        $tex_contents .= '\setlength{\TPHorizModule}{1pt}' . "\n";
        $tex_contents .= '\setlength{\TPVertModule}{1' . "$y_unit\}\n";
        $tex_contents .= '\begin{textblock}{'. $width . '}' . "($x_pos, $y_pos)";
        $tex_contents .= "\\noindent\n% $notes{$note_number}";
        $tex_contents .= '\end{textblock}';
        $tex_contents .= "\n";
    }

    $tex_contents .= '}' . "\n";
}

$tex_contents .= "\n" . '\multistamp{\numberofpages}' . "\n" . '\end{document}';
    
my $notes_dir = dirname($annotations_file);
basename($input_pdf) =~ /(.+)\.pdf/;
my $annotated = File::Spec->catfile($notes_dir, $1 . "_annotated.pdf");
my $note_mask = File::Spec->catfile($notes_dir, basename($annotations_file) . "_mask.tex");
$note_mask =~ /(.+)\.tex/;
my $note_mask_pdf = $1 . ".pdf";

open  NOTE_MASK, '>', $note_mask
    or die  "$0 : failed to open  input file '$note_mask' : $!\n";
print NOTE_MASK $tex_contents;
close  NOTE_MASK
    or warn "$0 : failed to close output file '$note_mask' : $!\n";
print "Done.\n";

print "Compiling $note_mask. ";
my $compile = "pdflatex --output-directory $notes_dir $note_mask";
#`$compile`;
system "pdflatex", "--output-directory", $notes_dir, $note_mask;
print "Done.\n";

print "Stamping $input_pdf with $note_mask_pdf. ";
system "pdftk", $input_pdf, "multistamp", File::Spec->catfile($notes_dir, $note_mask_pdf), "output", $annotated;
print "Done.\n";

print "Removing auxiliary files. ";
$note_mask =~ /(.+)\.tex/;
for my $aux ( "$1.aux", "$1.log", "$1.out", "$1.pdf", "$1.tex" ){
    unlink File::Spec->catfile($notes_dir, $aux);
}
if ($^O =~ m/win/i){
    print "Done.";
} else {
    print "Done.\n";
}
