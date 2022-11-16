<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template match="/">
<html>
<head>
<link rel="stylesheet" href="https://www.w3schools.com/w3css/4/w3.css"/>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css"/>
<link rel="stylesheet" href="/styles/listview.css"/>
<script type="text/javascript" src="/scripts/listview.js"/>
</head>
<body onload="initPage()">
  <div class="flex-container" id="navigation"/>
  <table id="results">
    <thead>
      <tr>
        <xsl:for-each select="ROWSET/ROW[1]/*">
          <th>
<!--
            <xsl:value-of select="name(.)"/>
-->
            <xsl:call-template name="heading">
              <xsl:with-param name="str" select="name(.)"/>
              <xsl:with-param name="chr">_</xsl:with-param>
            </xsl:call-template>

          </th>
        </xsl:for-each>
      </tr> 
    </thead>
    <xsl:for-each select="ROWSET/ROW">
    <tr>
      <xsl:apply-templates/>
    </tr>
    </xsl:for-each>
  </table>
</body>
</html>
</xsl:template>

<!-- generate column header from tag name -->

<xsl:template name="heading">
  <xsl:param name="str"/>
  <xsl:param name="chr"/>
  <xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'"/>
  <xsl:variable name="lowercase" select="'abcdefghijklmnopqrstuvwxyz'"/>
  <xsl:variable name="prefix" select="substring-before($str, $chr)"/>
  <xsl:choose>
    <xsl:when test="not(normalize-space($prefix)='')">
      <xsl:value-of select="concat(substring($prefix,1,1), translate(substring($prefix, 2), $uppercase, $lowercase), ' ')"/>
      <xsl:call-template name="heading">
        <xsl:with-param name="str" select="substring-after($str, $chr)"/>
        <xsl:with-param name="chr" select="$chr"/>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="concat(substring($str,1,1), translate(substring($str, 2), $uppercase, $lowercase))"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- these nodes have specific behaviour -->

<xsl:template match="ORDERS">
<td class="w3-right-align">
<xsl:if test=". &gt; 0">
	<a href="Orders?CUSTOMER_ID={../CUSTOMER_ID}"><xsl:value-of select="."/></a>
</xsl:if>
</td>
</xsl:template>

<xsl:template match="CONTACTS">
<td class="w3-right-align">
<xsl:if test=". &gt; 0">
	<a href="Contacts?CUSTOMER_ID={../CUSTOMER_ID}"><xsl:value-of select="."/></a>
</xsl:if>
</td>
</xsl:template>

<xsl:template match="SALESMAN_ID">
<td class="w3-right-align">
<xsl:if test=". &gt; 0">
	<a href="Sales?SALESMAN_ID={../SALESMAN_ID}"><xsl:value-of select="."/></a>
</xsl:if>
</td>
</xsl:template>

<xsl:template match="ORDER_ID">
<td class="w3-right-align">
<xsl:if test=". &gt; 0">
	<a href="Order?ORDER_ID={../ORDER_ID}"><xsl:value-of select="."/></a>
</xsl:if>
</td>
</xsl:template>

<xsl:template match="WEBSITE">
<td>
	<a href="{.}"><xsl:value-of select="."/></a>
</td>
</xsl:template>

<xsl:template match="EMAIL">
<td>
	<a href="mailto:{.}"><xsl:value-of select="."/></a>
</td>
</xsl:template>

<!-- all other node are just displayed as a cell: strings left aligned, dates centred, and numbers right aligned -->

<xsl:template match="*">
<xsl:choose>
	<xsl:when test="number(.)">
		<td class="w3-right-align"><xsl:value-of select="."/></td>
	</xsl:when>
	<xsl:otherwise>
		<xsl:choose>
			<xsl:when test="translate(., '123456789', '000000000') = '00-00-0000'">
				<td class="w3-center"><xsl:value-of select="."/></td>
			</xsl:when>
			<xsl:otherwise>
				<td class="w3-left-align"><xsl:value-of select="."/></td>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:otherwise>
</xsl:choose>
</xsl:template>

</xsl:stylesheet>
