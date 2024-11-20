const fs = require('fs');
const { transpile } = require('postman2openapi');

const postmanCollection = JSON.parse(
  fs.readFileSync('./Notion_API.postman_collection.json', 'utf8')
);

const openapi = transpile(postmanCollection);

fs.writeFileSync(
  './Notion_API.OpenAPI.v3.1.0.yaml',
  JSON.stringify(openapi, null, 2)
);