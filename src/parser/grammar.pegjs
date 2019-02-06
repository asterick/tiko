/*
 Grammar for parsing tico programs. (a lua 5.1 dialect)
 */ 

{
	const RESERVED = [
		"and", "break", "do", "else", "elseif", "end", 
		"false", "for", "function", "goto", "local", "nil", 
		"not", "or", "repeat", "return", "then", "true", 
		"until", "while", "if", "in",
		"global", "inline", "virtual", "using", "as"
	];

	const ASSIGNMENT_TYPES = {
		"+=": "Add",
		"-=": "Subtract",
		"*=": "Multiply",
		"/=": "Divide",
		"%=": "Modulo"
	};

	const BINARY_OPERATOR_TYPES = {
		"or": "LogicalOr",
		"and": "LogicalAnd",
		"<": "LessThanCompare",
		">": "GreaterThanCompare",
		"<=": "LessThanEqualCompare",
		">=": "GreaterThanEqualCompare",
		"~=": "NotEqualCompare",
		"!=": "NotEqualCompare",
		"==": "EqualCompare",
		"..": "Concatinate",
		"+": "Add",
		"-": "Subtract",
		"*": "Multiply",
		"/": "Divide",
		"%": "Modulo",
		"^": "Power"
	};

	const UNARY_OPERATOR_TYPES = {
		"not": "LogicalNot",
		"#": "Length",
		"-": "Negate"
	};

	function associate(key, alters) {
		return alters.reduce(function(acc, k) {
			k[key] = acc;
			return k;
		});
	}

	const imports = [];
}

program
	= body:block _
		{ return { type: "Program", imports, body }; }

block
	= statements:statement*

/* Statements */
statement
	= _ ";"
		{ return { location, type: "NullStatement" }; }
	/ using_statement
	/ assignment_statement
	/ function_call
	/ label_statement
	/ break_statement
	/ goto_statement
	/ do_statement
	/ while_statement
	/ repeat_statement
	/ if_statement
	/ for_statement
	/ for_in_statement
	/ function_statement
	/ local_statement
	/ return_statement

return_statement
	= _ "return" wordbreak value:(!assignment_statement e:expression_list { return e; })?
		{ return { location, type:"ReturnStatement", value }; }

label_statement
	= _ "::" label:name _ "::"
		{ return { location, type:"LabelStatement", label }; }

assignment_statement
	= variables:variable_list _ "=" expressions:expression_list
		{ return { location, type:"AssignmentStatement", variables, expressions }; }

	/ left:variable _ o:("+=" / "-=" / "*=" / "%=" / "/=") right:expression
		{
			return { 
				location, 
				type:  "AssignmentStatement",
				variables: [left], 
				expressions: [
					{ type: "BinaryOperator", op: ASSIGNMENT_TYPES[o], left, right, location }
				]
			}
		}

break_statement
	= _ "break" wordbreak
		{ return { location, type:"BreakStatement" }; }

goto_statement
	= _ "goto" wordbreak label:name
		{ return { location, type:"GotoStatement", label }; }

do_statement
	= _ "do" wordbreak body:block _ "end" wordbreak
		{ return { location, type:"BlockStatement", body }; }

while_statement
	= _ "while" wordbreak condition:expression body:do_statement
		{ return { location, type:"WhileStatement", condition, body }; }

repeat_statement
	= _ "repeat" wordbreak body:block _ "until" wordbreak condition:expression
		{ return { location, type:"RepeatStatement", condition, body }; }

if_statement
	= if_clause:if_block elseif_clauses:elseif_block* else_clause:else_block? _ "end" wordbreak
		{ return { location, type: "IfStatement", if_clause, elseif_clauses, else_clause } }

for_statement
	= _ "for" wordbreak name:name _ "=" start:expression _ "," end:expression increment:(_ "," i:expression { return i; })? body:do_statement
		{ return { location, type: "ForStatement", name, start, end, increment, body }; }

for_in_statement
	= _ "for" wordbreak names:name_list _ "in" wordbreak values:expression_list body:do_statement
		{ return { location, type: "ForInStatement", names, values, body }; }

function_statement
	= options:call_options _ "function" wordbreak wordbreak name:function_name body:function_body
		{ return { location, type: "FunctionDeclaration", name, body,  ... options }; }

local_statement
	= _ "local" wordbreak variables:name_list expressions:(_ "=" e:expression_list { return e; })?
		{ return { location, type: "LocalDeclaration", variables, expressions }; }

using_statement
	= _ "using" wordbreak module:name name:(_ "as" wordbreak name:name { return name })?
		{ 
			imports.push(module.name);

			return { location, type: "UsingDeclaration", module, name }
		}
	/ _ "using" wordbreak module:string name:(_ "as" wordbreak name:name { return name })?
		{
			imports.push(module.value);

			return { location, type: "UsingDeclaration", module, name }
		}

/* Blocks */
if_block
	= _ "if" wordbreak condition:expression _ "then" wordbreak body:block 
		{ return { location, type: "IfClause", condition, body } }

elseif_block
	= _ "elseif" wordbreak condition:expression _ "then" wordbreak body:block 
		{ return { location, type: "ElseIfClause", condition, body } }

else_block
	= _ "else" wordbreak body:block 
		{ return { location, type: "ElseClause", body } }

/* Lists */
variable_list
	= a:variable b:(_ "," c:variable { return c; })*
		{ return [a].concat(b); }

name_list
	= a:name b:(_ "," c:name { return c; })*
		{ return [a].concat(b); }

expression_list
	= a:expression b:(_ "," c:expression { return c; })*
		{ return [a].concat(b); }

parameter_list
	= parameters:name_list rest:(_ "," _ rest:"...")?
		{ return { location, type:"ParameterList", rest: Boolean(rest), parameters }; }
	/ _ "..."
		{ return { location, type:"ParameterList", rest: true, parameters: [] }; }

field_list
	= a:field b:(field_seperator c:field { return c; })* field_seperator?
		{ return [a].concat(b); }

field_seperator
	= _ ("," / ";")

/* Expressions */
expression
	= or_expression

or_expression
	= a:and_expression o:(_ t:"or" wordbreak b:and_expression { return { location, type: "BinaryOperator", op: BINARY_OPERATOR_TYPES[t], right: b } })+
		{ return associate("left", [a].concat(o)); }
	/ and_expression

and_expression
	= a:compare_expression o:(_ t:"and" wordbreak b:compare_expression { return { location, type: "BinaryOperator", op: BINARY_OPERATOR_TYPES[t], right: b } })+
		{ return associate("left", [a].concat(o)); }
	/ compare_expression

compare_expression
	= a:concat_expression o:(_ t:("<=" / ">=" / "<" / ">" / "~=" / "!=" / "==") b:concat_expression { return { location, type: "BinaryOperator", op: BINARY_OPERATOR_TYPES[t], right: b } })+
		{ return associate("left", [a].concat(o)); }
	/ concat_expression

concat_expression
	= left:add_expression _ t:".." right:concat_expression
		{ return { location, type: BINARY_OPERATOR_TYPES[t], left, right }; }
	/ add_expression

add_expression
	= a:multiply_expression o:(_ t:("+" / "-") b:multiply_expression { return { location, type: "BinaryOperator", op: BINARY_OPERATOR_TYPES[t], right: b } })+
		{ return associate("left", [a].concat(o)); }
	/ multiply_expression

multiply_expression
	= a:unary_expression o:(_ t:("*" / "/" / "%") b:unary_expression { return { location, type: "BinaryOperator", op: BINARY_OPERATOR_TYPES[t], right: b } })+
		{ return associate("left", [a].concat(o)); }
	/ unary_expression

unary_expression
	= _ t:("#" / "-" / $("not" wordbreak)) expression:unary_expression
		{ return { location, type: "UnaryOperator", op: UNARY_OPERATOR_TYPES[t], expression }; }
	/ power_expression

power_expression
	= left:top_expression _ t:"^" right:power_expression
		{ return { location, type: "BinaryOperator", op: BINARY_OPERATOR_TYPES[t], left, right }; }
	/ top_expression

top_expression
	= _ "nil" wordbreak
		{ return { location, type: "NilConstant" }; }
	/ _ "false" wordbreak
		{ return { location, value: false, type: "BooleanConstant" }; }
	/ _ "true" wordbreak
		{ return { location, value: true, type: "BooleanConstant" }; }
	/ _ "..."
		{ return { location, type: "RestArgument" }; }
	/ value:number
		{ return { location, type: "NumberConstant", value }; }
	/ value:string
		{ return { location, type: "StringConstant", value }; }
	/ value:function_definition
		{ return { location, type: "LambdaFunction", value }; }
	/ table_constructor
	/ prefix_expression

index_expression
	= _ "." name:name
		{ return { location, type: "PropertyIndex", name } }
	/ _ "[" value:expression _ "]"
		{ return { location, type: "ExpressionIndex", value } }

group_expression
	= _ "(" expression:expression _ ")"
		{ return expression; }

base_expression
	= name
	/ group_expression

call_expression
	= a:arguments
		{ return { location, type: "FunctionCall", arguments:a } }
	/ _ ":" name:name a:arguments
		{ return { location, type: "PropertyCall", name, arguments:a } }

modifier_expression
	= index_expression
	/ call_expression

prefix_expression
	= base:base_expression e:modifier_expression*
		{ return associate("expression", [base].concat(e)); }

variable
	= base:base_expression e:(e:modifier_expression &modifier_expression { return e; })* i:index_expression
		{ return associate("expression", [base].concat(e).concat(i)); }
	/ name

function_call
	= base:base_expression e:(e:modifier_expression &modifier_expression { return e; })* c:call_expression
		{ return associate("expression", [base].concat(e).concat(c)); }


/* Atomic types */
field
	= _ "[" key:expression _ "]" _ "=" value:expression
		{ return { location, type: "ExpressionField", key, value }; }
	/ name:name _ "=" value:expression
		{ return { location, type: "IdentifierField", name, value }; }
	/ value:expression
		{ return { location, type: "ValueField", value }; }

call_option
	= _ "virtual" wordbreak
		{ return { virtual: true } }
	/ _ "inline" wordbreak
		{ return { inline: true } }
	/ _ "global" wordbreak
		{ return { global: true } }
	/ _ "local" wordbreak
		{ return { local: true } }

call_options
	= options:call_option*
		{ return options.reduce((acc, opt) => Object.assign(acc, opt), {}) }

function_definition
	= options:call_options _ "function" wordbreak body:function_body
		{ return { location, type: "LambdaFunctionDeclaration", body, ... options }; }

function_name
	= a:name b:(_ "." b:name { return b; })* c:(_ ":" c:name { return c; })?
		{ 
			var names = [a].concat(b);
			return { 
				location, type: "FunctionName", 
				names: c ? names.concat(c) : names, 
				self: Boolean(c)
			}; 
		}

function_body
	= _ "(" parameters:parameter_list? _ ")" body:block _ "end" wordbreak
		{ return { location, type: "FunctionBody", parameters, body }; }

arguments
	= _ "(" l:expression_list? _ ")"
		{ return l; }
	/ string
	/ table_constructor

table_constructor
	= _ "{" fields:field_list? _ "}"
		{ return { location, type: "TableConstructor", fields }; }

/* These are helpers */
_
	= ([ \n\r\f\v\t] / comment)*

wordbreak
	= ![a-z0-9_]i

name
	= _ name:$([a-z_]i [a-z0-9_]i*) !{ return RESERVED.indexOf(name) >= 0 }
		{ return { location, type: "Identifier", name }; }

number
	= _ "0x"i a:$[0-9a-f]i* "." b:$[0-9a-f]i* &{ return a.length || b.length }
		{ return parseInt(a+b, 16) / (1 << (4 * b.length)) }
	/ _ "0x"i a:$[0-9a-f]i+
		{ return parseInt(a, 16) }
	/ _ "0b"i a:$[01]i* "." b:$[01]i* &{ return a.length || b.length }
		{ return parseInt(a+b, 2) / (1 << b.length) }
	/ _ "0b"i a:$[01]i+
		{ return parseInt(a, 2) }
	/ _ v:$(a:[0-9]* "." b:[0-9] &{ return a.length || b.length } ("e"i [+\-]? [0-9]+)?)
		{ return parseFloat(v); }
	/ _ v:$(a:[0-9]+ ("e"i [+\-]? [0-9]+)?)
		{ return parseFloat(v); }

string
	= value:string_literal
		{ return { location, type: "StringConstant", value }; }

string_literal
	= _ v:multiline
		{ return v; }
	/ _ '"' v:(!'"' c:escaped_char { return c })* '"'
		{ return v.join(""); }
	/ _ "'" v:(!"'" c:escaped_char { return c })* "'"
		{ return v.join(""); }

escaped_char
	= "\\x"i h:$([0-9a-f]i [0-9a-f]i)
		{ return String.fromCharCode(parseInt(h, 16)) }
	/ "\\" d:([0-9] [0-9]? [0-9]?)
		{ return String.fromCharCode(parseInt(d, 10)) }
	/ c:$("\\" [abfnrtv"'\\])
		{ return JSON.parse(`"${c}"`) }
	/ [^\\\n\r]

comment
	= "--" multiline
	/ "--" (![\n\r] .)*

multiline
	= 	"[" tag:$("="*) "["
		s:$(("]" ct:$("="*) "]" &{ return ct != tag; }) / (!("]" "="* "]") .))*
		"]" "="* "]"
		{ return s }
