python

typeParser = {
    "struct my_str *": [['len', "{}->len"], ['val', "{}->val"]]
}

def typeParserGet(type):
    global typeParser

    return typeParser.get(type, [])

end

