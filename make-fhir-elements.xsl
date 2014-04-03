<?xml version="1.0"?>

<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:fh="http://hl7.org/fhir"
                xmlns:my="http://localhost:8080/fhir-metadata"
                xpath-default-namespace="http://hl7.org/fhir"
                exclude-result-prefixes="fh my">

  <xsl:output method="xml" version="1.0"
              encoding="UTF-8" indent="yes"/>

  <xsl:function name="my:capitalize">
    <xsl:param name="str" />
    <xsl:sequence select="concat(upper-case(substring($str,1,1)),
          substring($str, 2),
          ' '[not(last())]
         )" />
  </xsl:function>

  <xsl:template name="expandPolymorphic">
    <xsl:param name="path" />
    <xsl:param name="min" />
    <xsl:param name="max" />
    <xsl:param name="type" />

    <xsl:for-each select="$type">
      <xsl:variable name="currentType" select="." />

      <xsl:call-template name="output">
        <xsl:with-param name="path" select="replace($path, '\[x\]', my:capitalize($currentType))" />
        <xsl:with-param name="type" select="$currentType" />
        <xsl:with-param name="min" select="$min" />
        <xsl:with-param name="max" select="$max" />
      </xsl:call-template>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="output">
    <xsl:param name="path" />
    <xsl:param name="min" />
    <xsl:param name="max" />
    <xsl:param name="type" />

    <element>
      <xsl:attribute name="path"><xsl:value-of select="$path" /></xsl:attribute>
      <min><xsl:attribute name="value"><xsl:value-of select="$min" /></xsl:attribute></min>
      <max><xsl:attribute name="value"><xsl:value-of select="$max" /></xsl:attribute></max>
      <type><xsl:attribute name="value"><xsl:value-of select="$type" /></xsl:attribute></type>
    </element>
  </xsl:template>

  <xsl:template match="//element">
    <xsl:variable name="type" select="definition/type/code/@value" />
    <xsl:variable name="path" select="path/@value" />
    <xsl:variable name="min" select="definition/min/@value" />
    <xsl:variable name="max" select="definition/max/@value" />

    <!-- Ignore extensions for now -->
    <xsl:if test="not(contains($path, '.extension'))">
      <xsl:choose>
        <xsl:when test="contains($path, '[x]')">
          <xsl:call-template name="expandPolymorphic">
            <xsl:with-param name="path" select="$path" />
            <xsl:with-param name="type" select="$type" />
            <xsl:with-param name="min" select="$min" />
            <xsl:with-param name="max" select="$max" />
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="output">
            <xsl:with-param name="path" select="$path" />
            <xsl:with-param name="type" select="$type[1]" />
            <xsl:with-param name="min" select="$min" />
            <xsl:with-param name="max" select="$max" />
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>

  <xsl:template name="extractTypeElements">
    <xsl:param name="document" />
    <xsl:variable name="elements" select="$document//structure[1]/element" />

    <xsl:for-each-group select="$elements[contains(path/@value, '.')]" group-by="./path/@value">
      <xsl:call-template name="output">
        <xsl:with-param name="path" select="path/@value" />
        <xsl:with-param name="type" select="definition/type/code/@value" />
        <xsl:with-param name="min" select="definition/min/@value" />
        <xsl:with-param name="max" select="definition/max/@value" />
      </xsl:call-template>
    </xsl:for-each-group>
  </xsl:template>

  <xsl:template match="text()|@*">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="/">
    <elements>
      <xsl:apply-templates />

      <xsl:call-template name="extractTypeElements">
        <xsl:with-param name="document"
                        select="document('build/profiles-types.xml')" />
      </xsl:call-template>
    </elements>
  </xsl:template>

</xsl:stylesheet>
