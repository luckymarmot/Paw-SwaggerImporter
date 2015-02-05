require "tv4.js"
require "yaml.min.js"

SwaggerImporter = ->

    # Create Paw requests from a Swagger Request (object)
    @createPawRequest = (context, swaggerCollection, swaggerRequestPath, swaggerRequestMethod, swaggerRequestValue) ->

        if swaggerRequestValue.summary
          swaggerRequestTitle = swaggerRequestValue.summary
        else
          swaggerRequestTitle = swaggerRequestPath
          
        headers = {}
        queries = {}
        formData = []
        body = []
        
        # Extract contentType from Consumes and add the first one to Headers
        if swaggerRequestValue.consumes
          for contentType in swaggerRequestValue.consumes
            headers["Content-type"] = contentType
            break
                  
        # Extract Headers and Query params
        for index, swaggerRequestParamValue of swaggerRequestValue.parameters
          
          # Add Queries
          if swaggerRequestParamValue.in == 'query' and swaggerRequestParamValue.type == 'string'
            queries[swaggerRequestParamValue.name] = swaggerRequestParamValue.name 
                      
          # Add Headers
          if swaggerRequestParamValue.in == 'header' and swaggerRequestParamValue.type == 'string'
            headers[swaggerRequestParamValue.name] = ''
            
          # Add Url Encoded 
          if swaggerRequestParamValue.in == 'formData' and swaggerRequestParamValue.type == 'string'
            body.push swaggerRequestParamValue.name
            
          # Add Body
          if swaggerRequestParamValue.in == 'body' #Only string
            body.push swaggerRequestParamValue.name
        
        swaggerRequestUrl = @createSwaggerRequestUrl swaggerCollection, swaggerRequestPath, queries
        swaggerRequestMethod = swaggerRequestMethod.toUpperCase()
          
        # Create Paw request
        pawRequest = context.createRequest swaggerRequestTitle, swaggerRequestMethod, swaggerRequestUrl
        # 
        # for index, swaggerRequestParamValue of swaggerRequestValue.parameters
        
        # Add Headers
        for key, value of headers
          pawRequest.setHeader key, value
        
        # # Set raw body
        # if postmanRequest["dataMode"] == "raw"
        #     contentType = pawRequest.getHeaderByName "Content-Type"
        #     rawRequestBody = postmanRequest["rawModeData"]
        #     foundBody = false;
        # 
        #     # If the Content-Type contains "json" make it a JSON body
        #     if contentType and contentType.indexOf("json") >= 0 and rawRequestBody and rawRequestBody.length > 0
        #         # try to parse JSON body input
        #         try
        #             jsonObject = JSON.parse rawRequestBody
        #         catch error
        #             console.log "Cannot parse Request JSON: #{ postmanRequest["name"] } (ID: #{ postmanRequestId })"
        #         # set the JSON body
        #         if jsonObject
        #             pawRequest.jsonBody = jsonObject
        #             foundBody = true
        # 
        #     if not foundBody
        #         pawRequest.body = rawRequestBody
        # 
        # # Set Form URL-Encoded body
        # else if postmanRequest["dataMode"] == "urlencoded"
        #     postmanBodyData = postmanRequest["data"]
        #     bodyObject = new Object()
        #     for bodyItem in postmanBodyData
        #         # Note: it sounds like all data fields are "text" type
        #         # when in "urlencoded" data mode.
        #         if bodyItem["type"] == "text"
        #             bodyObject[bodyItem["key"]] = bodyItem["value"]
        # 
        #     pawRequest.urlEncodedBody = bodyObject;
        # 
        # # Set Multipart body
        # else if postmanRequest["dataMode"] == "params"
        #     postmanBodyData = postmanRequest["data"]
        #     bodyObject = new Object()
        #     for bodyItem in postmanBodyData
        #         # Note: due to Apple Sandbox limitations, we cannot import
        #         # "file" type items
        #         if bodyItem["type"] == "text"
        #             bodyObject[bodyItem["key"]] = bodyItem["value"]
        # 
        #     pawRequest.multipartBody = bodyObject
        # 
          
        return pawRequest
    
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
    
        try
          # Try JSON parse
          swaggerCollection = JSON.parse string
        catch error
          # Try YAML parse
          swaggerCollection = yaml.load string
        
        schema = readFile "schema.json"
        valid = tv4.validate swaggerCollection, JSON.parse(schema)

        if not valid
          throw new Error "Invalid Swagger file (invalid schema or schema version < 2.0)"
          
        if swaggerCollection
          
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
