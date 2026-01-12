# get

## SYNOPSIS

mulle-sourcetree **get** <address> [key|all]

## DESCRIPTION

Prints the node values for a node with the given key. By default key is 'address'. If you use the special key 'all', then you will get an evaluatable output.

## KEYS

- **all** : special output (see below)
- **address** : the address of the node
- **branch** : the (git) branch of the node
- **fetchoptions** : options passed to mulle-fetch
- **marks** : marks of the node
- **nodetype** : type of the node
- **tag** : the (git) tag of the node
- **uuid** : the uuid of the node
- **url** : the url of the node
- **userinfo** : the userinfo of the node
- **evaledurl** : evaluated URL
- **evalednodetype** : evaluated nodetype
- **evaledbranch** : evaluated branch
- **evaledtag** : evaluated tag
- **evaledfetchoptions** : evaluated fetchoptions

## EXAMPLES

Get the address (default):
```bash
mulle-sourcetree get src/mylib
```

Get specific properties:
```bash
mulle-sourcetree get src/mylib branch
mulle-sourcetree get src/mylib url
mulle-sourcetree get src/mylib marks
```

Get all properties as evaluatable output:
```bash
mulle-sourcetree get src/mylib all
```

Example output for 'all':
```
_address='src/mylib'
_branch='${MYLIB_BRANCH}'
_fetchoptions=''
_marks='no-all-load,no-import'
_nodetype='${MYLIB_NODETYPE:-tar}'
_raw_userinfo='base64:YWxpYXNlcz1SZWxlYXNlOmN1cmwsRGVidWc6Y3VybC1kCg=='
_tag='${MYLIB_TAG:-8.5.0}'
_url='${MYLIB_URL:-https://github.com/user/mylib.git}'
_userinfo='aliases=Release:curl,Debug:curl-d'
_uuid='78cfb19c-00ec-4df6-9c13-00a6aa134000'
_evaledurl='https://github.com/user/mylib.git'
_evalednodetype='tar'
_evaledbranch=''
_evaledtag='8.5.0'
_evaledfetchoptions=''
```

Get evaluated values:
```bash
mulle-sourcetree get src/mylib evaledurl
mulle-sourcetree get src/mylib evaledtag
```

## FILTERING OPTIONS

The get command supports filtering by nodetype and marks:

```bash
mulle-sourcetree get src/mylib --nodetype git branch
mulle-sourcetree get src/mylib --marks build url
```

## NOTES

- If no key is specified, returns the address
- Evaluated values show the actual values after variable expansion
- The 'all' output can be sourced in shell scripts
- Node must exist or command will fail
- Supports fuzzy matching for node addresses

## SEE ALSO

- [mulle-sourcetree set](set.md) - Change node properties
- [mulle-sourcetree list](list.md) - List nodes in the sourcetree