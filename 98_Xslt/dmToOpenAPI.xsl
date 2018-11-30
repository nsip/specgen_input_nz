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
		<xsl:value-of select="concat( 'openapi: 3.0.0&#x0a;',
                                      'info:&#x0a;',
                                      '  version: ', $sifVersion, '&#x0a;',
                                      '  title: &quot;SIF ', $sifLocale, ' derived API&quot;&#x0a;',
									  '  description: ', normalize-space(specgen:TitlePage/specgen:h1), '&#x0a;',
									  '  host: &quot;api.terito.education.govt.nz&quot;&#x0a;',
									  '  basePath: &quot;v3&quot;&#x0a;')"/>

		<xsl:apply-templates select=".//specgen:Section[@name = 'Domain Map']" mode="DomainMap"/>

		<xsl:text># /////////////////////////////////////////////////////////////&#x0a;</xsl:text>
		<xsl:apply-templates select=".//specgen:DataObjects" mode="paths"/>

		<xsl:text>&#x0a;# /////////////////////////////////////////////////////////////&#x0a;</xsl:text>
		<xsl:text>components:&#x0a;</xsl:text>
		<xsl:text>  schemas:&#x0a;</xsl:text>

		<xsl:apply-templates select=".//specgen:DataObjects//specgen:DataObject" mode="schemasList"/>
		<xsl:apply-templates select=".//specgen:DataObjects//specgen:DataObject" mode="schemasSingle"/>
		
		<xsl:apply-templates select=".//specgen:Appendix[@name = 'Common Types']//specgen:CommonElement"/>
		<xsl:apply-templates select=".//specgen:Appendix[ends-with(@name,'Code Sets')]//specgen:CodeSet"/>
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
			<xsl:apply-templates select="specgen:Item[concat('@', specgen:Attribute)
										 eq current()/specgen:Key]/specgen:Description"/><xsl:text>&#x0a;</xsl:text>
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
		<xsl:value-of select="concat('                    $ref: ''#/components/schemas/', @name, '''&#x0a;')"/>
		<xsl:text>            application/xml:&#x0a;</xsl:text>
		<xsl:text>              schema:&#x0a;</xsl:text>
		<xsl:value-of select="concat('                $ref: ''#/components/schemas/', @name, '''&#x0a;')"/>
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
		<xsl:value-of select="concat('                    $ref: ''#/components/schemas/', @name, 's''&#x0a;')"/>
		<xsl:text>            application/xml:&#x0a;</xsl:text>
		<xsl:text>              schema:&#x0a;</xsl:text>
		<xsl:value-of select="concat('                $ref: ''#/components/schemas/', @name, 's''&#x0a;')"/>
		<xsl:apply-templates select="xhtml:Example[1]" mode="xml"/>
	</xsl:template>

	<xsl:template match="specgen:DataObject" mode="schemasSingle">
		<xsl:text>    # /////////////////////////////////////////////////////////////&#x0a;</xsl:text>
		<xsl:value-of select="concat('    ', @name, ':&#x0a;',
			                         '      type: object&#x0a;',
			                         '      description: &gt;-&#x0a;        ')"/>
		<xsl:apply-templates select="specgen:Item[1]/specgen:Description"/><xsl:text>&#x0a;</xsl:text>
		<xsl:text>      properties:&#x0a;</xsl:text>
		<xsl:apply-templates select="specgen:Item[position() gt 1]">
			<xsl:with-param name="indent" select="'        '"/>
		</xsl:apply-templates>
	</xsl:template>

	<xsl:template match="xhtml:Example" mode="xml">
	<xsl:text>          examples:&#x0a;</xsl:text>
	<xsl:text>            application/xml: &gt;-&#x0a;</xsl:text>
	<xsl:value-of select="concat('             ', xfn:xmlString(*), '&#x0a;')"/>
	</xsl:template>

	<xsl:template match="specgen:DataObject" mode="schemasList">
		<xsl:text>    # /////////////////////////////////////////////////////////////&#x0a;</xsl:text>
		<xsl:value-of select="concat('    ', @name, 's:&#x0a;',
			                         '      type: object&#x0a;',
			                         '      description: &gt;-&#x0a;        A List of ', @name, ' objects&#x0a;')"/>
		<xsl:text>      properties:&#x0a;</xsl:text>
		<xsl:value-of select="concat('        ', @name, ':&#x0a;')"/>
		<xsl:text>          type: array&#x0a;</xsl:text>
		<xsl:text>          items:&#x0a;</xsl:text>
		<xsl:value-of select="concat('            $ref: ''#/components/schemas/', @name, '''&#x0a;&#x0a;')"/>
	</xsl:template>		
	
	
	<xsl:template match="specgen:CommonElement">
		<xsl:text>&#x0a;  # /////////////////////////////////////////////////////////////&#x0a;</xsl:text>
		<xsl:value-of select="concat('    ', xfn:chopType(@name), ':&#x0a;')"/>

		<xsl:text>      description: &gt;-&#x0a;        </xsl:text>
		<xsl:apply-templates select="specgen:Item[1]/specgen:Description"/><xsl:text>&#x0a;</xsl:text>

		<!-- Simple and extended Types -->
		<xsl:apply-templates select="specgen:Item[1]/specgen:Type">
			<xsl:with-param name="indent" select="'    '"/>
		</xsl:apply-templates>
		
		<!-- What kind of CommonElement is it ?
			 - Object
			 - List of objects
		-->
		<xsl:choose>
			<!-- List of Object -->
			<xsl:when test="count(specgen:Item[1]/specgen:List) gt 0">
				<xsl:text>      type: object&#x0a;</xsl:text>
				<xsl:text>      properties:&#x0a;</xsl:text>
				<xsl:value-of select="concat('        ', specgen:Item[2]/specgen:Element, ':&#x0a;')"/>
				<xsl:text>          type: array&#x0a;</xsl:text>
				<xsl:text>          items:&#x0a;</xsl:text>
				<xsl:value-of select="concat('            $ref: ''#/components/schemas/', xfn:chopType(specgen:Item[2]/specgen:Type/@name), '''&#x0a;')"/>
			</xsl:when>
			
			<!-- Object -->
			<xsl:when test="count(specgen:Item[1][specgen:Type]) eq 0">
				<xsl:text>      type: object&#x0a;</xsl:text>
				
				<xsl:if test="count(specgen:Item) gt 1">
					<xsl:text>      properties:&#x0a;</xsl:text>
				</xsl:if>
			</xsl:when>
		</xsl:choose>

		<!-- Add properties for non-List objects, indent is different depending on
		     - properties are being added to an extension of a base type
		     - properties are being added to an ordinary object
		-->
		<xsl:if test="count(specgen:Item[1]/specgen:List) eq 0">
			<xsl:apply-templates select="specgen:Item[position() gt 1]">
				<xsl:with-param name="indent">
					<xsl:choose>
						<xsl:when test="count(specgen:Item[1]/specgen:Type/[@complex]) gt 0">
							<xsl:text>            </xsl:text>
						</xsl:when>
						<xsl:otherwise>
							<xsl:text>        </xsl:text>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:with-param>
			</xsl:apply-templates>
		</xsl:if>
	</xsl:template>
	

	<!-- Untyped elements, get special indentation -->
	<xsl:template match="specgen:Item[count(specgen:Type) eq 0]">
		<xsl:param name="indent"/>
		
		<xsl:value-of select="concat($indent, specgen:Element|specgen:Attribute, ':&#x0a;')"/>

		<xsl:if test="normalize-space(specgen:Description) ne ''">
			<xsl:value-of select="concat($indent, '  description: &gt;-&#x0a;', $indent, '    ')"/>
			<xsl:apply-templates select="specgen:Description"/><xsl:text>&#x0a;</xsl:text>
		</xsl:if>

		<xsl:apply-templates select="specgen:Values">
			<xsl:with-param name="indent" select="concat($indent, '  ')"/>
		</xsl:apply-templates>

		<xsl:if test="specgen:Attribute"> 
			<xsl:value-of select="concat($indent, '  xml:&#x0a;', $indent, '    attribute: true&#x0a;')"/>
		</xsl:if>
	</xsl:template>

	<!-- Elements with named Types get a refId and particular indentation -->
	<xsl:template match="specgen:Item[count(specgen:Type) gt 0]">
		<xsl:param name="indent"/>
		
		<xsl:value-of select="concat($indent, specgen:Element|specgen:Attribute, ':&#x0a;')"/>

		<xsl:choose>
			<xsl:when test="specgen:Type/@name ne ''">
				<xsl:apply-templates select="specgen:Type">
					<xsl:with-param name="indent" select="$indent"/>
				</xsl:apply-templates>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates select="preceding-sibling::specgen:Item[1]/specgen:Type">
					<xsl:with-param name="indent" select="$indent"/>
				</xsl:apply-templates>
			</xsl:otherwise>
		</xsl:choose>
		
		<xsl:if test="normalize-space(specgen:Description) ne ''">
			<xsl:value-of select="concat($indent, '  description: &gt;-&#x0a;', $indent, '    ')"/>
			<xsl:apply-templates select="specgen:Description"/><xsl:text>&#x0a;</xsl:text>
		</xsl:if>

		<xsl:apply-templates select="specgen:Values">
			<xsl:with-param name="indent" select="$indent"/>
		</xsl:apply-templates>

		<xsl:if test="specgen:Attribute"> 
			<xsl:value-of select="concat($indent, '  xml:&#x0a;', $indent, '    attribute: true&#x0a;')"/>
		</xsl:if>
	</xsl:template>

	<!--  Type is an extension of a base type -->
	<xsl:template match="specgen:Type[@complex = 'extension']">
		<xsl:text>      allOf:&#x0a;</xsl:text>
		<xsl:value-of select="concat('        - $ref: ''#/components/schemas/', xfn:chopType(@name), '''&#x0a;')"/>
		<xsl:text>        - type: object&#x0a;</xsl:text>
		<xsl:text>          properties:&#x0a;</xsl:text>
	</xsl:template>

	<!-- Type is of known xs:type -->
	<xsl:template match="specgen:Type[not(@complex) and starts-with(@name, 'xs:')]">
		<xsl:param name="indent"/>

		<xsl:choose>
			<xsl:when test="   @name eq 'xs:integer'
							or @name eq 'xs:int'">
				<xsl:value-of select="concat($indent, '  type: integer&#x0a;')"/>
			</xsl:when>
			
			<xsl:when test="@name eq 'xs:unsignedInt'">
				<xsl:value-of select="concat($indent, '  type: integer&#x0a;')"/>
				<xsl:value-of select="concat($indent, '  minimum: 0&#x0a;')"/>
				<xsl:value-of select="concat($indent, '  maximum: 4294967295&#x0a;')"/>
			</xsl:when>

			<xsl:when test="@name eq 'xs:date'">
				<xsl:value-of select="concat($indent, '  type: string&#x0a;')"/>
				<xsl:value-of select="concat($indent, '  format: date&#x0a;')"/>
			</xsl:when>
			
			<xsl:when test="   @name eq 'xs:string'
							or @name eq 'xs:normalizedString'
                            or @name eq 'xs:token'
					        or @name eq 'NCName'">
				<xsl:value-of select="concat($indent, '  type: string&#x0a;')"/>
			</xsl:when>
			
			<xsl:when test="   @name eq 'xs:boolean'">
				<xsl:value-of select="concat($indent, '  type: boolean&#x0a;')"/>
			</xsl:when>
			
			<xsl:when test="@name eq 'xs:anyURI'">
				<xsl:value-of select="concat($indent, '  type: string&#x0a;')"/>
				<xsl:value-of select="concat($indent, '  format: uri&#x0a;')"/>
			</xsl:when>

			<xsl:when test="@name eq 'base64Binary'">
				<xsl:value-of select="concat($indent, '  type: string&#x0a;')"/>
				<xsl:value-of select="concat($indent, '  contentEncoding: base64&#x0a;')"/>				
			</xsl:when>
		</xsl:choose>
	</xsl:template>

	<!-- Type is of named type -->
	<xsl:template match="specgen:Type[not(@complex) and @name ne '' and not(starts-with(@name, 'xs:'))]">
		<xsl:param name="indent"/>
		<xsl:value-of select="concat($indent, '  $ref: ''#/components/schemas/',
                                      xfn:chopType(@name), '''&#x0a;')"/>
	</xsl:template>

	<!-- Un-named type, so inline object -->
	<xsl:template match="specgen:Type">
		<xsl:param name="indent"/>
		<xsl:value-of select="concat($indent, '  type: object&#x0a;')"/>
	</xsl:template>

	

	
    <xsl:template match="specgen:CodeSet">
		<xsl:text>&#x0a;  # /////////////////////////////////////////////////////////////&#x0a;</xsl:text>
		<xsl:value-of select="concat('    ', ancestor::specgen:Grouping/@code, @name, translate(specgen:ID, '- /', ''), ':&#x0a;',
			                         '      type: string&#x0a;',
							         '      title: ', specgen:ID, '&#x0a;',
			                         '      description: &gt;-&#x0a;       ')"/>
		<xsl:apply-templates select="specgen:Intro"/><xsl:text>&#x0a;</xsl:text>

		<xsl:apply-templates select="specgen:Values">
			<xsl:with-param name="indent" select="'      '"/>
		</xsl:apply-templates>
	</xsl:template>

	<xsl:template match="specgen:Values">
		<xsl:param name="indent"/>
		<xsl:value-of select="concat($indent, '  &lt;dl&gt;&#x0a;')"/>
		<xsl:apply-templates select="specgen:Value" mode="defnList">
			<xsl:with-param name="indent" select="concat($indent, '    ')"/>
		</xsl:apply-templates>
		<xsl:value-of select="concat($indent, '  &lt;/dl&gt;&#x0a;')"/>

		<xsl:value-of select="concat($indent, 'enum: [')"/>
		<xsl:apply-templates select="specgen:Value" mode="enum"/>
		<xsl:text>]&#x0a;</xsl:text>
	</xsl:template>
	
	<xsl:template match="specgen:Value" mode="defnList">
		<xsl:param name="indent"/>

		<xsl:variable name="valDesc">
			<xsl:apply-templates select="specgen:Text"/>
		</xsl:variable>
		
		<xsl:value-of select="concat($indent, '&lt;dt&gt;''', specgen:Code, '''&lt;/dt&gt;',
                                              '&lt;dd&gt; - ', $valDesc, '&lt;/dd&gt;&lt;br/&gt;&#x0a;')"/>
	</xsl:template>

	<xsl:template match="specgen:Value[position() eq 1]" mode="enum">
		<xsl:value-of select="concat('''', specgen:Code, '''')"/>
	</xsl:template>
	<xsl:template match="specgen:Value[position() gt 1]" mode="enum">
		<xsl:value-of select="concat(', ''', specgen:Code, '''')"/>
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
		<xsl:variable name="outStr">
			<xsl:apply-templates select="$inXml" mode="nodetostring"/>
		</xsl:variable>
		<xsl:value-of select="replace(normalize-space($outStr), '&gt; &lt;', '&gt;&lt;')"/>
	</xsl:function>

	<xsl:variable name="q">
		<xsl:text>"</xsl:text>
	</xsl:variable>
	<xsl:variable name="empty"/>


	<xsl:template match="*" mode="selfclosetag">
		<xsl:text>&lt;</xsl:text>
		<xsl:value-of select="name()"/>
		<xsl:apply-templates select="@*" mode="attribs"/>
		<xsl:text>/&gt;</xsl:text>
	</xsl:template>

	<xsl:template match="*" mode="opentag">
		<xsl:text>&lt;</xsl:text>
		<xsl:value-of select="name()"/>
		<xsl:apply-templates select="@*[not(namespace-uri() = 'http://json.org/')]" mode="attribs"/>
		<xsl:text>&gt;</xsl:text>
	</xsl:template>

	<xsl:template match="*" mode="closetag">
		<xsl:text>&lt;/</xsl:text>
		<xsl:value-of select="name()"/>
		<xsl:text>&gt;</xsl:text>
	</xsl:template>

	<xsl:template match="* | text()" mode="nodetostring">
		<xsl:choose>
			<xsl:when test="boolean(name())">
				<xsl:choose>
					<!--
						if element is not empty
					-->
					<xsl:when test="normalize-space(.) != $empty or *">
						<xsl:apply-templates select="." mode="opentag"/>
							<xsl:apply-templates select="* | text()" mode="nodetostring"/>
						<xsl:apply-templates select="." mode="closetag"/>
					</xsl:when>
					<!--
						assuming emty tags are self closing, e.g. <img/>, <source/>, <input/>
					-->
					<xsl:otherwise>
						<xsl:apply-templates select="." mode="selfclosetag"/>
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
</xsl:stylesheet>
