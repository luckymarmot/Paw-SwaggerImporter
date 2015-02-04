require "tv4.js"

SwaggerImporter = ->

    # Create Paw requests from a Postman Request (object)
    @createPawRequest = (context, swaggerCollection, swaggerPath, swaggerRequest) ->
    
        # Create Paw request
        for own swaggerMethod, request of swaggerRequest
          
          swaggerRequestTitle = request.summary
          swaggerRequestUrl = swaggerCollection.schemes[0] + "://" + swaggerCollection.host + swaggerCollection.basePath + swaggerPath
          swaggerMethod = swaggerMethod.toUpperCase()
          
          pawRequest = context.createRequest swaggerRequestTitle, swaggerMethod, swaggerRequestUrl
          
          # # Add Headers
          # # Postman stores headers like HTTP headers, separated by \n
          # postmanHeaders = postmanRequest["headers"].split "\n"
          # for headerLine in postmanHeaders
          #     match = headerLine.match /^([^\s\:]*)\s*\:\s*(.*)$/
          #     if match
          #         pawRequest.setHeader match[1], match[2]
          # 
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
          
          break # Should have only one key
        
        return pawRequest
    
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
      
          # Add Swagger requests in root
          if pawRootGroup
            
              for own path, request of swaggerCollection.paths
                    
                  # Create a Paw request
                  pawRequest = @createPawRequest context, swaggerCollection, path, request
          
                  # Add request to root group
                  pawRootGroup.appendChild pawRequest
      
          return true
    
    return

SwaggerImporter.identifier = "com.luckymarmot.PawExtensions.SwaggerImporter"
SwaggerImporter.title = "Swagger Importer"

registerImporter SwaggerImporter
