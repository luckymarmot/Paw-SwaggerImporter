import BaseImporter, {
    Parser
} from 'paw-base-importer'
import yaml from 'yaml-js'

@registerImporter // eslint-disable-line
export default class SwaggerImporter extends BaseImporter {
    static identifier = 'com.luckymarmot.PawExtensions.SwaggerImporter';
    static title = 'Swagger Importer';

    static fileExtensions = [];
    static inputs = [];

    canImport(context, items) {
        let sum = 0
        for (let item of items) {
            sum += this._canImportItem(context, item)
        }
        return items.length > 0 ? sum / items.length : 0
    }

    _canImportItem(context, item) {
        let swag
        try {
            swag = JSON.parse(item.content)
        }
        catch (jsonParseError) {
            try {
                swag = yaml.load(item.content)
            }
            catch (yamlParseError) {
                return 0
            }
        }
        if (swag) {
            // converting objects to bool to number, fun stuff
            let score =
                (!!swag.swagger + swag.swagger === '2.0' + !!swag.info) / 3
            return score
        }
        return 0
    }

    /*
      @params:
        - context
        - items
        - options
    */
    createRequestContext(context, item) {
        const parser = new Parser.Swagger()
        let reqContext = parser.parse(item.content)
        return reqContext
    }
}
