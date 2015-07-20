
/* description: Nginx Configuration Files Grammar */

/* author: Alexey Yaroshevich */

{{
    var fs = require('fs');
    var globsync = require('glob').sync;
}}

%lex
dig                         [0-9]
anum                        [a-zA-Z0-9]+
esc                         "\\"
int                         "-"?(?:[0-9]|[1-9][0-9]+)
netmask                     ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\/{int})
domain                      ("localhost"|[\.a-zA-Z0-9][\-a-zA-Z0-9]*\.[\.\-a-zA-Z0-9]*[a-zA-Z0-9]?|[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)(?:\:{int})?
path                        [\/A-Za-z_\-0-9\.\*]+

%%
\s+                         /* skip whitespace */
\#[^\n]*                    /* skip comment */
";"                         return ';';
"{"                         return '{';
"}"                         return '}';

")"                         return ')';

'='                         return '=';

// keywords
if(?:\s*\()                 return 'if';
"include"                   return 'include';
"error_page"                return 'error_page';
"rewrite"                   return 'rewrite';
"default"                   return "default";
set(?=\s*$\s*)              return 'set';
http(?=\s*\{)               return 'http';
server(?=\s*\{)             return 'server';
upstream(?=\s+)             return 'upstream';
types(?=\s*\{)              return 'types';
map(?=\s+)                  return 'map';
geo(?=\s+)                  return 'geo';
"location"                  return 'location';
"server_name"               return 'server_name';
"least_conn"                return 'least_conn';
"ip_hash"                   return 'ip_hash';
js(?=\s*\{)                 return 'js';

(access|error)_log          return 'log';

// literals
"null"                      return 'NULL';
any|all                     return 'ANY';
on|true                     return 'TRUE';
off|false                   return 'FALSE';

// types
[0-9]+[kmg](?=\b)           return 'SIZE';
{netmask}                   return 'NETMASK';
{domain}(?=\s+|;)           return 'DOMAINLIKE';
[0-9]+(?=\b)                return 'NUMBER';
\"(?:[^\"]|\\\")*\"         return 'STRING'; //"
(\^\~|\~\*|\~)(?=\s)        return 'OPERATOR';
[A-Za-z\-]+\/[A-Za-z\-\+\.0-9]+ return 'MIMETYPE';
[A-Za-z_]+\=[A-Za-z_0-9]+   return 'LOG_PARAM';
(wss?\:|https?\:)\/\/({domain}|[a-z0-9\-]+)(\/[\/A-Za-z_\-0-9\.\%\?\=\+]+)? return 'URL';
(wss?\:|https?\:)\/\/([a-z0-9_\$\{\}\.\-]+)(\/[\/A-Za-z_\-0-9\.\%\?\=\+]+)? return 'URLP';
unix\:{path}                return 'SOCKET';
\$[A-Za-z_0-9]+             return 'VARIABLE';
\@[A-Za-z_\-0-9]+           return 'NAMED_LOCATION';
[A-Za-z_0-9]+(?=\b[^\.\-])  return 'TAG';
{path}                      return 'PATH';
\~(?:[^\s;]+)               return 'DOMAINREGEX';
(?:[^\s;]+)(?:(?=\s*\)\s*\{)|[^\)](?=\s+\{)|(?=\s*\/)) return 'REGEX';

<<EOF>>                     return 'EOF';

/lex

%%

ngxInitial
    : ngxSchema EOF
        {return $$;}
    ;

ngxLoadBalancingMethod
    : 'least_conn' ';'                              -> [$1]
    | 'ip_hash' ';'                                 -> [$1]
    ;

ngxUpstreamSchema
    : ngxLoadBalancingMethod ngxSchema              {$$ = $2, $2.unshift($1);}
    | ngxSchema
    ;

ngxSchema
    : ngxSchemaDirective ngxSchema                      {$$ = $2, $2.unshift($1);}
    | ngxSchemaDirective                             -> [$1]
    ;

ngxSchemaDirective
    : ngxCommand ';'
    | ngxBlock
    ;

// todo split these to blocks for each context
ngxBlock
    : TAG '{' '}'                                    -> [$1, null]
    | 'http' '{' ngxSchema '}'                       -> [$1, $3]
    | 'upstream' ngxUpstreamName '{' ngxUpstreamSchema '}'   -> [$1, $2, $4]
    | 'server' '{' ngxSchema '}'                     -> [$1, $3]
    | 'location' ngxLocationParams '{' ngxSchema '}' -> [$1, $2, $4]
    | 'types' '{' ngxMimeTypesMap '}'                -> [$1, $3]
    | 'geo' ngxVariable '{' ngxMap '}'               -> [$1, $2, $4]
    | 'map' ngxVariable ngxVariable '{' ngxMap '}'   -> [$1, $2, $3, $5]
    | TAG '{' ngxSchema '}'                          -> [$1, $3]
    | ngxIfBlock
    ;

ngxCommand
    : ngxSetCommand
    | ngxInclude
    | ngxLog
    | ngxServerName
    | ngxErrorPage
    | ngxRewrite
    | TAG ngxValues                                  -> [$1, $2]
    ;

ngxSetCommand
    : 'set' ngxVariable ngxValue                     -> [$1, $2, $3]
    ;

ngxInclude
    : 'include' ngxPath {

        var data = '', files = [];
        if (fs.existsSync($2)) {
            data = fs.readFileSync($2, {encoding: 'utf8'});
        } else {
            files = globsync($2, {silent: true, nonull: false});
            if (files.length) {
                files.forEach(function (v, k) {
                    data += fs.readFileSync(v, {encoding: 'utf8'});
                });
            } else {
                lexer.parseError('File '+$2+' is not exist.', this);
            }
        }

        lexer._input = data + lexer._input;
        //console.log(lexer._input);process.exit();
//        console.log(lexer.pushState(), lexer, this);process.exit();
        //console.log(fs.readFileSync($2, {encoding: 'utf8'})); process.exit();
        $$ = ['#', $1 + ' ' + $2];
    }
    ;

ngxIfBlock
    : 'if' ngxExpr ')' '{' ngxSchema '}'             -> [$1, $2, $5]
    ;

ngxExpr
    : ngxValue                                       -> [$1]
    | ngxValue '=' ngxValue                          -> [$1, $2, $3]
    | ngxValue OPERATOR REGEX                        -> [$1, $2, $3]
    ;

ngxLog
    : 'log' ngxPath                                  -> [$1, $2]
    | 'log' ngxPath ngxValues                        -> [$1, $2, $3]
    | 'log' ngxPath ngxValues ngxLogParams           -> [$1, $2, $3, $4]
    ;

ngxLogParams
    : ngxLogParams ngxLogParam                          {$$ = $1, $1.push($2);}
    | ngxLogParam                                    -> [$1]
    ;

ngxLogParam
    : LOG_PARAM
    ;

ngxLocationParams
    : OPERATOR REGEX                                 -> [$1, $2]
    | '=' ngxPath                                    -> [$1, $2]
    | ngxPath                                        -> [null, $1]
    ;

ngxUpstreamName
    : PATH
    | TAG
    | URL
    | URLP
    | SOCKET
    | NAMED_LOCATION
    ;

ngxServerName
    : 'server_name' ngxDomains
    ;

ngxDomain
    : DOMAINLIKE
    | DOMAINREGEX
    | 'default'
    ;

ngxDomains
    : ngxDomain                                      -> [$1]
    | ngxDomains ngxDomain                              {$$ = $1; $1.push($2);}
    ;

ngxVariable
    : VARIABLE   {$$ = yytext;}
    ;

ngxMap
    : ngxMap ngxMapRow ';'                              {$$ = $1; $1.push($2);}
    | ngxMapRow ';'                                  -> [$1]
    ;

ngxMapRow
    : 'default' ngxValue                             -> [$1, $2]
    | ngxInclude
    | ngxValue ngxValue                              -> [$1, $2]
    ;

ngxMimeTypesMap
    : ngxMimeTypesMap ngxMimeTypesRow                   {$$ = $1; $1.push($2);}
    | ngxMimeTypesRow                                -> [$1]
    ;

ngxMimeTypesRow
    : ngxMimeType ngxFileExtensions ';'              -> [$1, $2]
    | ngxMimeType ngxFileExtensions                  -> [$1, $2]
    ;

ngxFileExtensions
    : ngxFileExtension ngxFileExtensions                {$$ = $2; $2.unshift($1);}
    | ngxFileExtension                               -> [$1]
    ;

ngxMimeType
    : MIMETYPE
    ;

ngxErrorPage
    : 'error_page' ngxNumbers '=' ngxPath            -> [$1, $2, $3, $4]
    | 'error_page' ngxNumbers ngxPath                -> [$1, $2, null, $3]
    ;

ngxRewrite
    : 'rewrite' REGEX ngxValues                      -> [$1, $2, $3]
    ;

ngxFileExtension
    : TAG
    ;

ngxPath
    : PATH
    | URL
    | URLP
    | SOCKET
    | NAMED_LOCATION
    ;

ngxNumbers
    : ngxNumbers ngxNumber                              {$$ = $1; $1.push($2);} 
    | ngxNumber                                      -> [$1]
    ;

ngxNumber
    : NUMBER     -> Number(yytext)
    ;


ngxLiterals
    : TRUE       {$$ = true;}
    | FALSE      {$$ = false;}
    | NULL       {$$ = null;}
    | ANY        {$$ = 'any';}
    ;

ngxValue
    : ngxLiterals
    | STRING
    | TAG
    | SIZE
    | ngxNumber
    | ngxPath
    | ngxVariable
    | ngxMimeType
    | NETMASK
    | DOMAINLIKE
    ;

ngxValues
    : ngxValues 'default'                         {$$ = $1; $1.push($2);}
    | ngxValues ngxValue                          {$$ = $1; $1.push($2);}
    | ngxValue                                 -> [$1]
    ;
