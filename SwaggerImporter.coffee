require "tv4.js"

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
            queries[swaggerRequestParamValue.name] = swaggerRequestParamValue.name 
                      
          # Add Headers
          if swaggerRequestParamValue.in == 'header' and swaggerRequestParamValue.type == 'string'
            headers[swaggerRequestParamValue.name] = swaggerRequestParamValue.name
            
          # Add Url Encoded 
          if swaggerRequestParamValue.in == 'formData' and swaggerRequestParamValue.type == 'string'
            formData[swaggerRequestParamValue.name] = swaggerRequestParamValue.name
            
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
            s = "\"string\""
        else if property.type == 'integer'
            s = "0"
        else if property.type == 'boolean'
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
        
        swaggerRequestUrl = swaggerCollection.schemes[0] + '://' +
        swaggerCollection.host +
        swaggerCollection.basePath +
        swaggerRequestPath
        
        if swaggerRequestQueries
          swaggerRequestUrl = swaggerRequestUrl + '?' + swaggerRequestQueries.join('&')
        
        return swaggerRequestUrl
            
    @createPawGroup = (context, swaggerCollection, swaggerRequestPathName, swaggerRequestPathValue) ->

        # Create Paw group
        pawGroup = context.createRequestGroup swaggerRequestPathName

        for own swaggerRequestMethod, swaggerRequestValue of swaggerRequestPathValue
              
            # Create a Paw request
            pawRequest = @createPawRequest context, swaggerCollection, swaggerRequestPathName, swaggerRequestMethod, swaggerRequestValue
    
            # Add request to root group
            pawGroup.appendChild pawRequest

        return pawGroup
        
    @importString = (context, string) ->

        # Try JSON parse
        swaggerCollection = JSON.parse string

        schema = readFile "schema.json"
        valid = tv4.validate swaggerCollection, JSON.parse(schema)

        if not valid
          throw new Error "Invalid Swagger file (invalid schema or schema version < 2.0)"
        
        if swaggerCollection
          
          # Define host to localhost if not specified in file
          swaggerCollection.host = if swaggerCollection.host then swaggerCollection.host else 'localhost'
          
          # Create a PawGroup
          pawRootGroup = context.createRequestGroup swaggerCollection.info.title
          
          # Add Swagger groups
          for own swaggerRequestPathName, swaggerRequestPathValue of swaggerCollection.paths
    
            pawGroup = @createPawGroup context, swaggerCollection, swaggerRequestPathName, swaggerRequestPathValue

            # Add group to root
            pawRootGroup.appendChild pawGroup
      
          return true
    
    return

SwaggerImporter.identifier = "com.luckymarmot.PawExtensions.SwaggerImporter"
SwaggerImporter.title = "Swagger Importer"

registerImporter SwaggerImporter
