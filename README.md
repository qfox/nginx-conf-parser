nginx configuration file parser
===============================

yet another parser written on JS using jison

Usage
-----

```sh
cd your-project-path
npm install -l nginx-conf-parser
```

and then just use it:

```js
var nginxParser = require('nginx-conf-parser').parser;
var result = nginxParser.parse('server { server_name .example.host; }');
console.log(result); // yo. no async, sorry ;-(
```
