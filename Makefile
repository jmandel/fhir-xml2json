.PHONY: all
all: examples

build/fhir-specs.zip:
	mkdir build && curl -L -o build/fhir-specs.zip 'http://www.hl7.org/documentcenter/public/standards/FHIR/fhir-spec.zip'

build/profiles-resources.xml:
	(unzip -j -o build/fhir-specs.zip "*.xml" -d build || echo "OK")

fhir-elements.xml: build/profiles-resources.xml
	saxonb-xslt -s:build/profiles-resources.xml -xsl:make-fhir-elements.xsl > fhir-elements.xml

.PHONY: examples
examples: build/profiles-resources.xml fhir-elements.xml
	cd examples && make all

clean:
	rm -rf fhir-elements.xml build/*.xml examples/*.json

