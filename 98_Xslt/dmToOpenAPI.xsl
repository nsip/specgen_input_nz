<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:specgen="http://sifassociation.org/SpecGen"
	xmlns:xfn="http://stuart.geek.nz/xslt-functions"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:xhtml="http://www.w3.org/1999/xhtml"
	xmlns:json="http://json.org/">

	<!-- Take a SIF_DataModel.input.xml file and produce a matching OpenAPI v3.0.0 spec -->
	<xsl:output method="text" omit-xml-declaration="yes" indent="no"/>

	<xsl:param name="sifVersion"/>
	<xsl:param name="sifLocale"/>
	
	<xsl:template match="/specgen:SIFSpecification">
		<xsl:value-of select="concat( 'openapi: 3.0.2&#x0a;',
                                      'info:&#x0a;',
                                      '  version: ', $sifVersion, '&#x0a;',
                                      '  title: &quot;SIF ', $sifLocale, ' derived API&quot;&#x0a;',
									  '  description: ', normalize-space(specgen:TitlePage/specgen:h1), '&#x0a;',
									  '  host: &quot;api.terito.education.govt.nz&quot;&#x0a;',
									  '  basePath: &quot;v3&quot;&#x0a;')"/>

		<xsl:apply-templates select=".//specgen:Section[@name = 'Domain Map']" mode="DomainMap"/>

		<xsl:text># /////////////////////////////////////////////////////////////&#x0a;</xsl:text>
		<xsl:apply-templates select=".//specgen:DataObjects" mode="paths"/>
	</xsl:template>

	<xsl:template match="specgen:Section" mode="DomainMap">
		<xsl:text>tags:&#x0a;</xsl:text>
		<xsl:apply-templates select="specgen:Domain" mode="DomainMap"/>
	</xsl:template>

	<xsl:template match="specgen:Domain" mode="DomainMap">
	    <xsl:value-of select="concat('- name: ', @name, '&#x0a;')"/>
		<xsl:text>  description: &gt;-&#x0a;    </xsl:text>
		<xsl:apply-templates select="specgen:Intro"/><xsl:text>&#x0a;</xsl:text>
		<xsl:text>  externalDocs: &#x0a;</xsl:text>
		<xsl:value-of select="concat('    description: &quot;', @name, ' Domain in SIF NZ Data Model&quot;&#x0a;')"/>
		<xsl:value-of select="concat('    url: &quot;http://localhost:8080/DomainMap.html#Domain__', xfn:cleanUrl(@name), '&quot;&#x0a;')"/>
	</xsl:template>

	<xsl:template match="specgen:DataObjects" mode="paths">
		<xsl:text>paths:&#x0a;</xsl:text>		
		<xsl:apply-templates select=".//specgen:DataObject" mode="paths"/>
	</xsl:template>              

	<xsl:template match="specgen:DataObject" mode="paths">
		<xsl:variable name="tags">
			<xsl:for-each select="//specgen:Domain[specgen:DataObject = current()/@name]">
				<xsl:value-of select="concat('      - ', @name, '&#x0a;')"/>
			</xsl:for-each>
		</xsl:variable>
		<xsl:text>  # /////////////////////////////////////////////////////////////&#x0a;</xsl:text>
		<xsl:value-of select="concat('  /', @name, 's:&#x0a;')"/>
		<xsl:text>    get:&#x0a;</xsl:text>
		<xsl:text>      tags:&#x0a;</xsl:text>
		<xsl:value-of select="$tags"/>
		<xsl:value-of select="concat('      summary: Default operation to get a list of all available ', @name, 's&#x0a;')"/>
		<xsl:apply-templates select="." mode="responsesList"/>
			
		<xsl:if test="specgen:Key">
			<xsl:text>  # /////////////////////////////////////////////////////////////&#x0a;</xsl:text>
			<xsl:value-of select="concat('  /', @name, 's/{', lower-case(@name), translate(specgen:Key, '@', ''), '}:&#x0a;')"/>
			<xsl:text>    get:&#x0a;</xsl:text>
			<xsl:text>      tags:&#x0a;</xsl:text>
			<xsl:value-of select="$tags"/>
			<xsl:value-of select="concat('      summary: Default operation to get a single ', @name, '&#x0a;')"/>
			<xsl:value-of select="concat('      parameters:&#x0a;      - name: ', lower-case(@name), translate(specgen:Key, '@', ''), '&#x0a;')"/>
			<xsl:text>        in: path&#x0a;        description: >-&#x0a;          </xsl:text>
			<xsl:apply-templates select="specgen:Item[specgen:Element eq current()/specgen:Key]/specgen:Description"/><xsl:text>&#x0a;</xsl:text>
			<xsl:text>        required: true&#x0a;</xsl:text>
			<xsl:text>        schema:&#x0a;</xsl:text>
			<xsl:text>          type: string&#x0a;</xsl:text>
		</xsl:if>
		<xsl:apply-templates select="." mode="responsesSingle"/>
	</xsl:template>

    <xsl:template match="specgen:DataObject" mode="responsesSingle">
		<xsl:text>      responses:&#x0a;</xsl:text>
        <xsl:text>        '200':&#x0a;</xsl:text>
        <xsl:text>          description: successful operation&#x0a;</xsl:text>
		<xsl:text>          content:&#x0a;</xsl:text>
		<xsl:text>            application/json:&#x0a;</xsl:text>
		<xsl:text>              schema:&#x0a;</xsl:text>
		<xsl:text>                type: object&#x0a;</xsl:text>
		<xsl:text>                properties:&#x0a;</xsl:text>
		<xsl:value-of select="concat('                  ', @name, ':&#x0a;')"/>
		<xsl:value-of select="concat('                    $ref: ''jsonSchema.yaml#/definitions/', @name, '''&#x0a;')"/>
		<xsl:apply-templates select="xhtml:Example[lower-case(@intl)=lower-case($sifLocale) or not(@intl)][1]" mode="json"/>
		<xsl:text>            application/xml:&#x0a;</xsl:text>
		<xsl:text>              schema:&#x0a;</xsl:text>
		<xsl:value-of select="concat('                $ref: ''jsonSchema.yaml#/definitions/', @name, '''&#x0a;')"/>
		<xsl:apply-templates select="xhtml:Example[lower-case(@intl)=lower-case($sifLocale) or not(@intl)][1]" mode="xml"/>
	</xsl:template>

    <xsl:template match="specgen:DataObject" mode="responsesList">
		<xsl:text>      responses:&#x0a;</xsl:text>
        <xsl:text>        '200':&#x0a;</xsl:text>
        <xsl:text>          description: successful operation&#x0a;</xsl:text>
		<xsl:text>          content:&#x0a;</xsl:text>
		<xsl:text>            application/json:&#x0a;</xsl:text>
		<xsl:text>              schema:&#x0a;</xsl:text>
		<xsl:text>                type: object&#x0a;</xsl:text>
		<xsl:text>                properties:&#x0a;</xsl:text>
		<xsl:value-of select="concat('                  ', @name, 's:&#x0a;')"/>
        <xsl:text>                  type: object&#x0a;</xsl:text>
        <xsl:text>                  description: >-&#x0a;</xsl:text>
        <xsl:value-of select="concat('                    A List of ', @name, ' objects&#x0a;')"/>
        <xsl:text>                  properties:&#x0a;</xsl:text>
        <xsl:value-of select="concat('                    ', @name, ':&#x0a;')"/>
        <xsl:text>                      type: array&#x0a;</xsl:text>
        <xsl:text>                      items:&#x0a;</xsl:text>
        <xsl:value-of select="concat('                      $ref: ''jsonSchema.yaml#/definitions/', @name, '''&#x0a;')"/>
		<xsl:apply-templates select="xhtml:Example[lower-case(@intl)=lower-case($sifLocale) or not(@intl)][1]" mode="json"/>

		<xsl:text>            application/xml:&#x0a;</xsl:text>
		<xsl:text>              schema:&#x0a;</xsl:text>
		<xsl:text>                type: object&#x0a;</xsl:text>
		<xsl:text>                properties:&#x0a;</xsl:text>
		<xsl:value-of select="concat('                  ', @name, 's:&#x0a;')"/>
        <xsl:text>                  type: object&#x0a;</xsl:text>
        <xsl:text>                  description: >-&#x0a;</xsl:text>
        <xsl:value-of select="concat('                    A List of ', @name, ' objects&#x0a;')"/>
        <xsl:text>                  properties:&#x0a;</xsl:text>
        <xsl:value-of select="concat('                    ', @name, ':&#x0a;')"/>
        <xsl:text>                      type: array&#x0a;</xsl:text>
        <xsl:text>                      items:&#x0a;</xsl:text>
        <xsl:value-of select="concat('                      $ref: ''jsonSchema.yaml#/definitions/', @name, '''&#x0a;')"/>
		<xsl:apply-templates select="xhtml:Example[lower-case(@intl)=lower-case($sifLocale) or not(@intl)][1]" mode="xml"/>
		
	</xsl:template>
	
	<xsl:template match="xhtml:Example" mode="json">
		<xsl:text>                example: &gt;-&#x0a;</xsl:text>
		<xsl:value-of select="xfn:jsonString(*, '                  ')"/>
	</xsl:template>

	<xsl:template match="xhtml:Example" mode="xml">
		<xsl:text>              example: &gt;-&#x0a;</xsl:text>
		<xsl:value-of select="xfn:xmlString(*, '                ')"/>
	</xsl:template>
	
	<!-- Bring Description, Intro or Text mixed content elements across with all its embedded html -->
	<xsl:template match="specgen:Description|specgen:Intro|specgen:Text">
		<xsl:variable name="descr"><xsl:apply-templates/></xsl:variable>

		<xsl:value-of select="normalize-space(translate($descr, ':', ''))"/>
	</xsl:template>
	<xsl:template match="specgen:p|specgen:br
						 |specgen:code|specgen:strong|specgen:em|specgen:span
						 |specgen:h1|specgen:h2|specgen:h3|specgen:h4
						 |specgen:ul|specgen:ol|specgen:li
						 |specgen:dl|specgen:dt|specgen:dd
						 |specgen:table|specgen:thead|specgen:tbody|specgen:tr|specgen:th|specgen:td">
		<xsl:value-of select="concat('&lt;', local-name(.))"/>
		<xsl:for-each select="@*">
			<xsl:value-of select="concat(' ', local-name(.), '=&quot;', . , '&quot;')"/>
		</xsl:for-each>
		<xsl:choose>
			<xsl:when test="not(*) and not(normalize-space())">
				<xsl:text>/&gt;</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>&gt;</xsl:text>
				<xsl:apply-templates/>
				<xsl:value-of select="concat('&lt;/', local-name(.), '&gt;')"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>


	<!-- Custom function to chop 'Type' off the end of XSD type names -->
	<xsl:function name="xfn:chopType" as="xs:string">
		<xsl:param name="inp"/>
		<xsl:choose>
			<xsl:when test="ends-with($inp, 'Type')">
				<xsl:value-of select="substring($inp, 1, string-length($inp)-4)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$inp"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>

	<!-- Custom function to tidy up URL -->
	<xsl:function name="xfn:cleanUrl" as="xs:string">
		<xsl:param name="inUrl"/>
		<xsl:value-of select="replace(replace($inUrl, ' ', ''), '&amp;', '')"/>
	</xsl:function>

	<!-- Custom function XML to string -->
	<xsl:function name="xfn:xmlString" as="xs:string">
		<xsl:param name="inXml"/>
		<xsl:param name="pfx"/>

		<xsl:variable name="outStr">
			<xsl:apply-templates select="$inXml" mode="nodetostring">
				<xsl:with-param name="pfx"><xsl:value-of select="$pfx"/></xsl:with-param>
			</xsl:apply-templates>
		</xsl:variable>
		<xsl:value-of select="$outStr"/>
	</xsl:function>

	<xsl:function name="xfn:jsonString" as="xs:string">
		<xsl:param name="inXml"/>
		<xsl:param name="pfx"/>

		<xsl:variable name="outStr">
			<xsl:apply-templates select="$inXml" mode="nodetojson">
				<xsl:with-param name="pfx"><xsl:value-of select="$pfx"/></xsl:with-param>
			</xsl:apply-templates>
		</xsl:variable>
		<xsl:value-of select="$outStr"/>
	</xsl:function>

	<xsl:variable name="q">
		<xsl:text>"</xsl:text>
	</xsl:variable>
	<xsl:variable name="empty"/>


	<xsl:template match="*" mode="selfclosetag">
		<xsl:value-of select="concat('&lt;', name())"/>
		<xsl:apply-templates select="@*[not(namespace-uri() = 'http://json.org/')]" mode="attribs"/>
		<xsl:text>/&gt;&#x0a;</xsl:text>
	</xsl:template>

	<xsl:template match="* | text()" mode="nodetostring">
		<xsl:param name="pfx"/>

		<xsl:choose>
			<xsl:when test="boolean(name())">
				<xsl:choose>
					<!-- element has children -->
					<xsl:when test="*">
						<xsl:value-of select="concat($pfx, '&lt;', name(), '&gt;&#x0a;')"/> 

						<xsl:apply-templates select="*" mode="nodetostring">
							<xsl:with-param name="pfx"><xsl:value-of select="concat($pfx, '  ')"/></xsl:with-param>
						</xsl:apply-templates>
						<xsl:value-of select="concat($pfx, '&lt;/', name(), '&gt;&#x0a;')"/>
					</xsl:when>
					<!--
						Just a text element 
					-->
					<xsl:otherwise>
						<xsl:value-of select="concat($pfx, '&lt;/', name(), '&gt;', normalize-space(.),'&lt;/', name(), '&gt;&#x0a;')"/> 
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="."/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="@*" mode="attribs">
		<xsl:if test="position() = 1">
			<xsl:text> </xsl:text>
		</xsl:if>
		<xsl:value-of select="concat(name(), '=', $q, ., $q)"/>
		<xsl:if test="position() != last()">
			<xsl:text> </xsl:text>
		</xsl:if>
	</xsl:template>	

	<xsl:template match="*" mode="nodetojson">
		<xsl:param name="pfx"/>

		<xsl:choose>
			<xsl:when test="boolean(name())">

				<xsl:variable name="isArray" select="    (count(../*[name() = name(current())]) > 1) 
				                                     or  @json:force-array = 'true'"/>
				<xsl:choose>
					<!-- element has children -->
					<xsl:when test="*">
						<xsl:value-of select="$pfx"/>

						<xsl:choose>
							<xsl:when test="$isArray and position() > 1"><xsl:text> </xsl:text></xsl:when>
							<xsl:when test="$isArray"><xsl:value-of select="concat('&quot;',name(), '&quot;: [')"/></xsl:when>
							<xsl:otherwise><xsl:value-of select="concat('&quot;', name(), '&quot;:')"/></xsl:otherwise>
						</xsl:choose>

						<xsl:text>{ &#x0a;</xsl:text>
						<xsl:apply-templates select="*" mode="nodetojson">
							<xsl:with-param name="pfx">
								<xsl:value-of select="concat($pfx, '  ')"/>
							</xsl:with-param>
						</xsl:apply-templates>
						<xsl:value-of select="concat($pfx, '}')"/>
						<xsl:if test="position() != last()"><xsl:text>,</xsl:text></xsl:if>
						<xsl:if test="$isArray and position() = last()"><xsl:text>]</xsl:text></xsl:if>
						<xsl:text>&#x0a;</xsl:text>
					</xsl:when>

					<!--
						Element has no children
					-->
					<xsl:otherwise>
						<xsl:choose>
							<!-- An empty element -->
							<xsl:when test="normalize-space(.) = ''">
								<xsl:value-of select="concat($pfx, '&quot;', name(), '&quot;: {}')"/>
								<xsl:if test="position() != last()"><xsl:text>,</xsl:text></xsl:if>
								<xsl:text>&#x0a;</xsl:text>
							</xsl:when>

							<!-- An ordinary atomic valued element (or an array thereof) -->
							<xsl:otherwise>
								<xsl:value-of select="$pfx"/>
								<xsl:if test="not($isArray) or (position() = 1)">
									<xsl:value-of select="concat('&quot;', name(), '&quot;: ')"/>
								</xsl:if>

								<xsl:if test="$isArray and position() = 1"><xsl:text>[</xsl:text></xsl:if>

								<xsl:choose>
									<!--
										A value is considered a string if the following conditions are met:
										* There is whitespace/formatting around the value of the node.
										* The value is not a valid JSON number (i.e. '01', '+1', '1.', and '.5' are not valid JSON numbers.)
										* The value does not equal the any of the following strings: 'false', 'true', 'null'.
									-->
									<xsl:when test="./@json:force-string eq 'true' or ((normalize-space(.) ne . or not((string(.) castable as xs:integer  and not(starts-with(string(.),'+')) and not(starts-with(string(.),'0') and not(. = '0'))) or (string(.) castable as xs:decimal  and not(starts-with(string(.),'+')) and not(starts-with(.,'-.')) and not(starts-with(.,'.')) and not(starts-with(.,'-0') and not(starts-with(.,'-0.'))) and not(ends-with(.,'.')) and not(starts-with(.,'0') and not(starts-with(.,'0.'))) )) and not(. = 'false') and not(. = 'true') and not(. = 'null')))">             
										<xsl:text/>&quot;<xsl:value-of select="json:encode-string(.)"/>&quot;<xsl:text/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:text/><xsl:value-of select="."/><xsl:text/>
									</xsl:otherwise>
								</xsl:choose>

								<xsl:if test="$isArray and position() = last()"><xsl:text>]</xsl:text></xsl:if>
								<xsl:if test="position() != last()"><xsl:text>,</xsl:text></xsl:if>
								<xsl:text>&#x0a;</xsl:text>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="concat('&quot;Uuuurrrrkkkkk', ., '&quot;,')"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:function name="json:encode-string" as="xs:string">
		<xsl:param name="string" as="xs:string"/>
		<xsl:sequence select="replace(
			replace(
			replace(
			replace(
			replace(
			replace(
			replace(
			replace($string,
				'\\','\\\\'),
				'&quot;', '\\&quot;'),
				'&#xA;','\\n'),
				'&#xD;','\\r'),
				'&#x9;','\\t'),
				'\n','\\n'),
				'\r','\\r'),
				'\t','\\t')"/>
	</xsl:function>	
</xsl:stylesheet>
