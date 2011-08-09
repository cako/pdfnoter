README
======

Introduction
------------

Annotating PDF files is hard. There are a few
options, but none of them are good enough for the
technically inclined. Most PDF annotators use either
ASCII text or free form tools.

The question arises: How does one annotate a PDF
with LaTeX notation. The answer is, you simply
don't.

This little script might be the beginning of a
positive answer. The idea of the solution is to
create another PDF with the annotations, then
"stamp" it on the original PDF one needs to
annotate.

The manual process was first described on [this
blog](http://3diagramsperpage.wordpress.com/2011/07/29/mathematical-annotations-in-pdf-documents/).
After the author contacted me, I took it upon myself
to automate the process a bit, and the results so far include this script and my
other project, [annotate-pdf](https://github.com/cako/annotate_pdf). Hopefully, 
I won't stop here, and will find even better ways to quickly annotate PDFs.
The idea is to eventually embed this type of annotation in popular PDF readers,
or even write another PDF reader dedicated to annotations.

Requirements
------------
* [perl](http://www.perl.org/get.html)
* [pdftk](http://www.pdflabs.com/docs/install-pdftk/)
* [pdfinfo](http://www.foolabs.com/xpdf/) (part of the xpdf utilities for PDF files)
* pdflatex
* textpos package for LaTeX

Installation
------------
The tricky part here is the installation of the requirements, and not the program itself.

### Ubuntu

    sudo apt-get install perl pdftk poppler-utils texlive-latex-extra

### Windows

Download Strawberry Perl [here](http://strawberryperl.com/) and install it.

Download `pdftk` [here](http://strawberryperl.com/). To install it, copy
the two files (a `.exe` and a `.dll`) to the
`C:\WINDOWS\system32\` folder.

Download `pdfinfo` from
[here](http://www.foolabs.com/xpdf/download.html),
and copy `pdfinfo.exe` to the `C:\WINDOWS\system32\` folder.

Finally, install a LaTeX distribution such as
[MiKTeX](http://miktex.org/2.9/setup) if you
don't already have one.
    
Instructions
------------

Write your notes in a text file, following the format specified in the
`example.tex` example file. (The format is super simple,
[check it out](https://github.com/cako/pdfnoter/blob/master/example.tex)!)
Then run
    
    perl pdfnoter.pl INPUT_PDF INPUT_NOTES

You are done! The annotated file is produced on the same folder as the
`INPUT_NOTES` file.


Example
-------
The most simple note is this one:
    <begin:note>
    1, 5cm, 1cm, 1cm
    This as complicated as notes get!
    <end:note>

Another note, found in [example.tex](https://github.com/cako/pdfnoter/blob/master/example.tex)
produces the following PDF, given the input PDF has the correct size and margins.

![Looks good to me!][img1half]

[img1]: http://i.imgur.com/58pDA.png
[img1half]  http://i.imgur.com/ia3gu.png

To Do
----
* Allow relative positioning of text
* Allow the specification of the output name
* Add options such as "verbose"
* Add more information on errors
* Create `.exe` for Windows with bundled programs (and their sources!)
* Allow comments
    

Please Contribute!
------------------
This code is licensed under the GNU General Public
License version 3. Go ahead, fork it and improve it!
