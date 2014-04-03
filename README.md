FHIR XML => JSON via XSLT
=========================

This repository contains XSL 2.0 stylesheet `fhir-xml2json.xsl` for
transformation of
[FHIR resources](http://www.hl7.org/implement/standards/fhir/) XML
representation into JSON.

Such transformation requires metadata about FHIR resources structure,
so main XSL stylesheet `fhir-xml2json.xsl` needs other file called
`fhir-elements.xml` to be able to do conversion.

`fhir-elements.xml` is build from official FHIR metadata with XSL
stylesheet called `make-fhir-elements.xsl`. Once `fhir-elements.xml`
was built, you don't need `make-fhir-elements.xsl` to perform
conversion.

Prerequisites
-----

Basically you need some Unix environment (OSX or Linux are fine,
Windows needs Cygwin). Specially, following components should be
installed:

  * [Saxon](http://saxon.sourceforge.net/) XSLT processor
  * `make` utility to build `fhir-elements.xml` automatically
  * Python interpreter to pretty-print JSON when invoking `make
    examples`
  * `unzip` binary to extract ZIP archives

Usage
-----

Just clone this repo, cd into it and run `make`:

    $ cd fhir-xml2json
    $ make

If anything finished without errors, you will see `fhir-elements.xml`,
which is XML file containing all metainformation required to perform
XML => JSON conversion. In `examples` directory you can find some FHIR
resource samples converted to JSON.

License
-----

This code is distributed under MIT License.

