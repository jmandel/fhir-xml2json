<?xml version="1.0"?>

<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:fh="http://hl7.org/fhir"
                xpath-default-namespace="http://hl7.org/fhir">

  <xsl:variable name="elementsDoc" select="document('fhir-elements.xml')"/>
  <xsl:key name="element-by-path" match="*:element" use="@path" />

  <xsl:output method="text" encoding="UTF-8" media-type="text/plain"/>

  <xsl:function name="fh:get-json-type">
    <xsl:param name="path" />
    <xsl:param name="pathTail" />

    <!-- <xsl:message terminate="no"> -->
    <!--   determining type for <xsl:value-of select="$path" /> | <xsl:value-of select="$pathTail" /> -->
    <!-- </xsl:message> -->

    <xsl:if test="string-length($path) = 0">
      <xsl:message terminate="yes">
        Zero-length $path passed, stopping.
      </xsl:message>
    </xsl:if>

    <xsl:variable name="pType" select="key('element-by-path', $path, $elementsDoc)[1]/*:type/@value" />

    <!-- <xsl:message terminate="no"> -->
    <!--   !!! <xsl:value-of select="$pType" /> -->
    <!-- </xsl:message> -->

    <xsl:choose>
      <xsl:when test="$pType and string-length($pathTail) = 0">
        <xsl:value-of select="$pType" />
      </xsl:when>

      <xsl:when test="$pType and string-length($pathTail) > 0">
        <xsl:choose>
          <xsl:when test="starts-with($pType, 'Resource(')">
            <xsl:value-of select="'Resource'" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name="ctPath" select="concat($pType, '.', replace($pathTail, '\.$', ''))" />

            <xsl:value-of select="fh:get-json-type($ctPath, '')[1]" />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="tokenizedPath" select="tokenize($path, '\.')" />
        <xsl:variable name="newPath" select="string-join(remove($tokenizedPath, count($tokenizedPath)), '.')" />
        <xsl:variable name="newPathTail" select="concat($tokenizedPath[count($tokenizedPath)], '.', $pathTail)" />

        <xsl:value-of select="fh:get-json-type($newPath, $newPathTail)[1]" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:template match="/*[1]">
    <xsl:call-template name="element">
      <xsl:with-param name="path"><xsl:value-of select="name()" /></xsl:with-param>
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="element">
    <xsl:param name="path" />

    <xsl:choose>
      <!-- if we have @value attr in current element, just output it -->
      <xsl:when test="@value">
        <xsl:call-template name="value">
          <xsl:with-param name="path" select="$path" />
          <xsl:with-param name="value" select="@value" />
        </xsl:call-template>
      </xsl:when>

      <xsl:otherwise>
        <!-- open curly brace if this element contains child nodes &
             doesn't have @value -->

        <xsl:variable name="isObject" select="not(./@value) and count(./*) > 0" />
        <xsl:if test="$isObject">{</xsl:if>

        <xsl:if test="$path = local-name()">
          "resourceType": "<xsl:value-of select="local-name()" />",
        </xsl:if>

        <xsl:for-each-group select="*" group-by="local-name()">
          <xsl:variable name="currentName"
                        select="name(current-group()[1])" />

          <xsl:variable name="currentPath"
                        select="concat($path, '.', $currentName)" />

          <xsl:variable name="max"
                        select="key('element-by-path', $currentPath, $elementsDoc)[1]/*:max/@value"
                        />

          <xsl:variable name="isArray"
                        select="$max = '*' or (current-group()[1]/@value
                                and count(current-group()) > 1)" />

          <xsl:if test="not(name() = 'text' and ./status)"> <!-- skip
                                                                 text
                                                                 for now -->

            <!-- open array if needed -->
            "<xsl:value-of select="name()" />": <xsl:if test="$isArray">[</xsl:if>

            <xsl:for-each select="current-group()">
              <xsl:call-template name="element">
                <xsl:with-param name="path">
                  <xsl:choose>
                    <xsl:when test="string-length($path) > 0">
                      <xsl:value-of select="concat($path, '.', local-name())" />
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="local-name()" />
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:with-param>
              </xsl:call-template>

              <xsl:if test="position() != last()">,</xsl:if>
            </xsl:for-each>

            <xsl:if test="$isArray">]</xsl:if>
            <xsl:if test="position() != last()">,</xsl:if>
          </xsl:if>
        </xsl:for-each-group>

        <xsl:if test="$isObject">}</xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- outputs JSON value: string, boolean or numeric -->
  <xsl:template name="value">
    <xsl:param name="path" />
    <xsl:param name="value" />

    <xsl:variable name="type" select="fh:get-json-type($path, '')" />

    <xsl:choose>
      <xsl:when test="$type = 'boolean' or
                      $type = 'decimal' or
                      $type = 'integer' ">
        <xsl:value-of select="$value" />
      </xsl:when>
      <xsl:otherwise>           <!-- string fallback -->
        <xsl:text>"</xsl:text>

        <!-- escape double quotes in string -->
        <xsl:value-of select="replace($value, '&quot;', '\\&quot;')" />
        <xsl:text>"</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>
