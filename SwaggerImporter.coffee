(this.loadScript or require)("tv4.js")
(this.loadScript or require)("yaml.js")

SwaggerImporter = ->

    # Create Paw requests from a Swagger Request (object)
    @createPawRequest = (context, swaggerCollection, swaggerRequestPath, swaggerRequestMethod, swaggerRequestValue) ->

        if swaggerRequestValue.summary
          swaggerRequestTitle = swaggerRequestValue.summary
        else
          swaggerRequestTitle = swaggerRequestPath

        headers = {}
        queries = {}
        formData = {}
        body

        # Extract contentType from Consumes and add the first one to Headers
        if swaggerRequestValue.consumes
          for contentType in swaggerRequestValue.consumes
            headers["Content-Type"] = contentType
            break

        # Extract Headers and Query params
        for index, swaggerRequestParamValue of swaggerRequestValue.parameters

          # Add Queries
          if swaggerRequestParamValue.in == 'query' and swaggerRequestParamValue.type == 'string'
            queries[swaggerRequestParamValue.name] = if swaggerRequestParamValue.default then swaggerRequestParamValue.default else swaggerRequestParamValue.name

          # Add Headers
          if swaggerRequestParamValue.in == 'header' and swaggerRequestParamValue.type == 'string'
            headers[swaggerRequestParamValue.name] = if swaggerRequestParamValue.default then swaggerRequestParamValue.default else swaggerRequestParamValue.name

          # Add Url Encoded
          if swaggerRequestParamValue.in == 'formData' and swaggerRequestParamValue.type == 'string'
            formData[swaggerRequestParamValue.name] = if swaggerRequestParamValue.default then swaggerRequestParamValue.default else swaggerRequestParamValue.name

          # Add Body
          if swaggerRequestParamValue.in == 'body' #Only string
            body = @json_from_definition_schema swaggerCollection, swaggerRequestParamValue.schema

        swaggerRequestUrl = @createSwaggerRequestUrl swaggerCollection, swaggerRequestPath, queries
        swaggerRequestMethod = swaggerRequestMethod.toUpperCase()

        # Create Paw request
        pawRequest = context.createRequest swaggerRequestTitle, swaggerRequestMethod, swaggerRequestUrl

        # Add Headers
        for key, value of headers
          pawRequest.setHeader key, value

        # Add Basic Auth if required
        pawRequest.setHeader "Authorization", "HTTP Basic Auth (Username/Password)" if @has_basic_auth swaggerCollection, swaggerRequestValue

        # Set raw body
        pawRequest.body = body if body

        # Set Form URL-Encoded body
        if Object.keys(formData).length > 0
            # Set Form URL-Encoded body
            if headers['Content-Type'] == "application/x-www-form-urlencoded"
              pawRequest.urlEncodedBody = formData
            # Set Multipart body
            else if headers['Content-Type'] == "multipart/form-data"
              pawRequest.multipartBody = formData

        return pawRequest

    @has_basic_auth = (swaggerCollection, swaggerRequestValue) ->
      if swaggerRequestValue.security
        for security in swaggerRequestValue.security
          for own key, value of security
            if swaggerCollection.securityDefinitions[key] and swaggerCollection.securityDefinitions[key].type == 'basic'
              return true
            break
      return false

    @json_from_definition_schema = (swaggerCollection, property, indent = 0) ->

        if property.type == 'string'
        	if property.hasOwnProperty("default") && property.default?
	            s = "\"" + property.default + "\""
	        else
	        	s = "\"string\""
        else if property.type == 'integer'
            if property.hasOwnProperty("default") && property.default?
                s = property.default
            else
            	s = "0"
        else if property.type == 'boolean'
            if property.hasOwnProperty("default") && property.default?
                s = property.default
            else
            	s = "true"
        else if typeof(property) == 'object'
            indent_str = Array(indent + 1).join('    ')
            indent_str_children = Array(indent + 2).join('    ')

            if property.items
              property = property.items
              s = "[\n" +
                  "#{indent_str_children}#{@json_from_definition_schema(swaggerCollection, property, indent+1)}" +
                  "\n#{indent_str}]"
            else
              property = swaggerCollection.definitions[property["$ref"].split('/').pop()] if property["$ref"]
              property = property.properties if property.properties # Skip properties

              s = "{\n" +
                  ("#{indent_str_children}\"#{key}\" : #{@json_from_definition_schema(swaggerCollection, value, indent+1)}" for key, value of property).join(',\n') +
                  "\n#{indent_str}}"

        return s

    @createSwaggerRequestUrl = (swaggerCollection, swaggerRequestPath, queries) ->

        # Build swaggerRequestQueries
        if Object.keys(queries).length > 0
          swaggerRequestQueries = []

        for key, value of queries
          swaggerRequestQueries.push "#{key}=#{value}"

        swaggerRequestUrl = (if swaggerCollection.schemes then swaggerCollection.schemes[0] else 'http') +
          '://' +
          (swaggerCollection.host or 'echo.luckymarmot.com')

        # add basePath
        if swaggerCollection.basePath and swaggerCollection.basePath.length > 0
          basePath = swaggerCollection.basePath

          # make sure it starts with a /
          if basePath.indexOf('/') != 0
            basePath = '/' + basePath

          # make sure it doesn't end with a /
          if basePath.length > 0 and basePath[basePath.length - 1] == '/'
            basePath = basePath.substr(0, basePath.length - 1)
          swaggerRequestUrl += basePath

        # add path
        if not swaggerRequestPath or swaggerRequestPath.length == 0 or swaggerRequestPath[0] != '/'
          throw new Error "Invalid Swagger, path must begin with a /"
        swaggerRequestUrl += swaggerRequestPath

        if swaggerRequestQueries
          swaggerRequestUrl = swaggerRequestUrl + '?' + swaggerRequestQueries.join('&')

        return swaggerRequestUrl

    @createPawGroup = (context, swaggerCollection, swaggerRequestPathName, swaggerRequestPathValue) ->

        # Create Paw group
        pawGroupName = swaggerRequestPathName

        # use resource name (first part of the path) as paw group name
        rx = /(\/.+?)\//
        match = rx.exec swaggerRequestPathName
        if match && match[1]
            pawGroupName = match[1]

        # Create Paw group for resource
        pawGroup = context.getRequestGroupByName pawGroupName
        if typeof pawGroup is 'undefined'
            pawGroup = context.createRequestGroup pawGroupName

        for own swaggerRequestMethod, swaggerRequestValue of swaggerRequestPathValue

            # Add global 'consumes' to individual pawRequest
            if swaggerCollection.consumes
              # Don't override the RequestValue.consumes with the global swaggerCollection.consumes, if
              # the individual RequestValue.consumes is already set
              if not swaggerRequestValue.consumes?.length
                swaggerRequestValue.consumes = swaggerCollection.consumes

            # Create a Paw request
            pawRequest = @createPawRequest context, swaggerCollection, swaggerRequestPathName, swaggerRequestMethod, swaggerRequestValue

            # Add request to root group
            pawGroup.appendChild pawRequest

        return pawGroup

    @canImport = (context, items) ->
      a = 0
      b = 0
      for item in items
        a += @_canImportItem(context, item)
        b += 1
      return if b > 0 then a/b else 0

    @_canImportItem = (context, item) ->
      try
        # Try JSON parse
        swag = JSON.parse(item.content)
      catch jsonParseError
        try
          # Try YAML parse
          swag = yaml.load(item.content)
        catch yamlParseError
          return 0
      if swag and swag.swagger and swag.swagger == '2.0' and swag.info
        return 1
      return 0

    @import = (context, items, options) ->
      order = options?.order or null
      parent = options?.parent or null
      for item in items
        @_importStringToGroup(context, item.content, {
          parent: parent,
          order: order,
        })
        order += 1
      return true

    @importString = (context, str) ->
      return @_importStringToGroup(context, str)

    @_importStringToGroup = (context, str, options={}) ->

      try
        # Try JSON parse
        swaggerCollection = JSON.parse(str)
      catch jsonParseError
        try
          # Try YAML parse
          swaggerCollection = yaml.load(str)
        catch yamlParseError
          console.error "Trying JSON Format: #{ jsonParseError }"
          console.error "Trying YAML Format: #{ yamlParseError }"
          throw new Error "Invalid Swagger file format (invalid JSON or YAML file)"

      schema = readFile "schema.json"
      valid = tv4.validate swaggerCollection, JSON.parse(schema)

      if not valid
        throw new Error "Invalid Swagger file (invalid schema or schema version < 2.0):\n#{ tv4.error }"

      if swaggerCollection

        # Define host to localhost if not specified in file
        swaggerCollection.host = if swaggerCollection.host then swaggerCollection.host else 'localhost'

        # Create a PawGroup
        pawRootGroup = context.createRequestGroup(swaggerCollection.info.title)

        # Set parent and order of group
        if options.parent
            options.parent.appendChild(pawRootGroup)
        if options.order and options.order >= 0
            pawRootGroup.order = options.order

        # Add Swagger groups
        for own swaggerRequestPathName, swaggerRequestPathValue of swaggerCollection.paths

          pawGroup = @createPawGroup context, swaggerCollection, swaggerRequestPathName, swaggerRequestPathValue

          # Add group to root
          pawRootGroup.appendChild(pawGroup)

        return true

    return

SwaggerImporter.identifier = "com.luckymarmot.PawExtensions.SwaggerImporter"
SwaggerImporter.title = "Swagger Importer"

registerImporter SwaggerImporter
