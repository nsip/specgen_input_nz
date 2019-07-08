<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:specgen="http://sifassociation.org/SpecGen"
	xmlns:xfn="http://stuart.geek.nz/xslt-functions"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:xml="http://www.w3.org/XML/1998/namespace">

	<!-- Take a SIF_DataModel.input.xml file and produce a matching Json Schema -->
	<xsl:output method="text" omit-xml-declaration="yes" indent="no"/>
	
	<xsl:param name="sifVersion"/>
	<xsl:param name="sifLocale"/>

	<!-- This schema is for UPDATES so mandatory fields are OPTIONAL -->
	<xsl:param name="mandatoryFields">optional</xsl:param>

	<!-- How many enumeration values to include in descriptions ? -->
	<xsl:param name="enumCount">12</xsl:param>
	
	<!-- Where is the SIF HTML documentation available for links -->
	<xsl:param name="extDocURLBase">https://sifnzmodel.azurewebsites.net/SIFNZ/</xsl:param>

    <!-- Now that we've configured all the options -->
    <xsl:include href="dmToJsonSchema.xsl"/>
</xsl:stylesheet>
