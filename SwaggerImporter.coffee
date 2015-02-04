require "tv4.js"

SwaggerImporter = ->

    # Create Paw requests from a Postman Request (object)
    @createPawRequest = (context, swaggerCollection, swaggerRequestPath, swaggerRequestMethod, swaggerRequestValue) ->

        if swaggerRequestValue.summary
          swaggerRequestTitle = swaggerRequestValue.summary
        else
          swaggerRequestTitle = swaggerRequestPath
          
        swaggerRequestUrl = swaggerCollection.schemes[0] + '://' + swaggerCollection.host + swaggerCollection.basePath + swaggerRequestPath
        swaggerRequestMethod = swaggerRequestMethod.toUpperCase()
          
        # Create Paw request
        pawRequest = context.createRequest swaggerRequestTitle, swaggerRequestMethod, swaggerRequestUrl
        
        for index, swaggerRequestParamValue of swaggerRequestValue.parameters
          
          # Add Headers
          if swaggerRequestParamValue.in == 'header'
            pawRequest.setHeader swaggerRequestParamValue.name, "value"
          
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
    
        # Parse JSON collection
        swaggerCollection = JSON.parse string
        schema = readFile "schema.json" 
        valid = tv4.validate string, schema

        if not valid
          throw new Error "Invalid Swagger file (not a valid JSON)"
          
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
