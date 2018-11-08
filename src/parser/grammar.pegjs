/*
 Grammar for parsing tico programs. (a lua 5.1 dialect)
 */ 

{
	const RESERVED = [
		"and", "break", "do", "else", "elseif", "end", 
		"false", "for", "virtual", "function", "goto", 
		"local", "nil", "not", "or", "repeat", "return", 
		"then", "true", "until", "while", "if", "in",
		"using", "as"
	];

	const assignmentTypes = {
		"+=": "AddOperator",
		"-=": "SubtractOperator",
		"*=": "MultiplyOperator",
		"/=": "DivideOperator",
		"%=": "ModuloOperator"
	};

	const binaryOperatorTypes = {
		"or": "LogicalOrOperator",
		"and": "LogicalAndOperator",
		"<": "LessThanCompareOperator",
		">": "GreaterThanCompareOperator",
		"<=": "LessThanEqualCompareOperator",
		">=": "GreaterThanEqualCompareOperator",
		"~=": "NotEqualCompareOperator",
		"!=": "NotEqualCompareOperator",
		"==": "EqualCompareOperator",
		"..": "ConcatinateOperator",
		"+": "AddOperator",
		"-": "SubtractOperator",
		"*": "MultiplyOperator",
		"/": "DivideOperator",
		"%": "ModuloOperator",
		"^": "PowerOperator"
	};

	const unaryOperatorTypes = {
		"not": "LogicalNotOperator",
		"#": "LengthOperator",
		"-": "NegateOperator",
	};

	function associate(key, alters) {
		return alters.reduce(function(acc, k) {
			k[key] = acc;
			return k;
		});
	}
}

chunk
	= block:block _
		{ return block; }

block
	= statements:statement*

/* Statements */
statement
	= _ ";"
		{ return { location, type: "NullStatement" }; }
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
	/ using_statement

return_statement
	= _ "return" wordbreak value:(!assignment_statement e:expression_list { return e; })?
		{ return { location, type:"ReturnStatement", value }; }

label_statement
	= _ "::" label:name _ "::"
		{ return { location, type:"LabelStatement", label }; }

assignment_statement
	= variables:variable_list _ "=" expressions:expression_list
		{ return { location, type:"AssignmentStatement", variables, expressions }; }

	/ v:variable _ o:("+=" / "-=" / "*=" / "%=" / "/=") e:expression
		{
			return { 
				location, 
				type:  "AssignmentStatement",
				variables: [v], 
				expressions: [
					{ 
						type: assignmentTypes[o],
						left: v,
						right: e,
						location
					}
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
	= _ "for" wordbreak n:name_list _ "in" wordbreak e:expression_list b:do_statement
		{ return { location, type: "ForInStatement", names: n, values: e, body: b }; }

function_statement
	= native:call_space wordbreak name:function_name body:function_body
		{ return { location, type: "FunctionDeclaration", native, name: name, body: body }; }
	/ _ "local" wordbreak native:call_space name:name body:function_body
		{ return { location, type: "LocalFunctionDeclaration", native, name: name, body: body }; }

local_statement
	= _ "local" wordbreak names:name_list exp:(_ "=" e:expression_list { return e; })?
		{ return { location, type: "LocalDeclaration", variables: names, expressions: exp }; }

using_statement
	= _ "using" wordbreak module:(name / string) name:(_ "as" wordbreak name:name { return name })?
		{ return { location, type: "UsingDeclaration", module, name } }

/* Blocks */
if_block
	= _ "if" wordbreak condition:expression _ "then" wordbreak b:block 
		{ return { location, type: "IfClause", condition: condition, body: b } }

elseif_block
	= _ "elseif" wordbreak condition:expression _ "then" wordbreak b:block 
		{ return { location, type: "ElseIfClause", condition: condition, body: b } }

else_block
	= _ "else" wordbreak b:block 
		{ return { location, type: "ElseClause", body: b } }

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
	= params:name_list rest:(_ "," _ rest:"...")?
		{ return { location, type:"ParameterList", rest: Boolean(rest), parameters: params }; }
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
	= a:and_expression o:(_ t:"or" wordbreak b:and_expression { return { location, type: binaryOperatorTypes[t], right: b } })+
		{ return associate("left", [a].concat(o)); }
	/ and_expression

and_expression
	= a:compare_expression o:(_ t:"and" wordbreak b:compare_expression { return { location, type: binaryOperatorTypes[t], right: b } })+
		{ return associate("left", [a].concat(o)); }
	/ compare_expression

compare_expression
	= a:concat_expression o:(_ t:("<=" / ">=" / "<" / ">" / "~=" / "!=" / "==") b:concat_expression { return { location, type: binaryOperatorTypes[t], right: b } })+
		{ return associate("left", [a].concat(o)); }
	/ concat_expression

concat_expression
	= a:add_expression _ t:".." b:concat_expression
		{ return { location, type: binaryOperatorTypes[t], left:a, right: b }; }
	/ add_expression

add_expression
	= a:multiply_expression o:(_ t:("+" / "-") b:multiply_expression { return { location, type: binaryOperatorTypes[t], right: b } })+
		{ return associate("left", [a].concat(o)); }
	/ multiply_expression

multiply_expression
	= a:unary_expression o:(_ t:("*" / "/" / "%") b:unary_expression { return { location, type: binaryOperatorTypes[t], right: b } })+
		{ return associate("left", [a].concat(o)); }
	/ unary_expression

unary_expression
	= _ t:("#" / "-" / $("not" wordbreak)) a:unary_expression
		{ return { location, type: unaryOperatorTypes[t], expression:a }; }
	/ power_expression

power_expression
	= a:top_expression _ t:"^" b:power_expression
		{ return { location, type: binaryOperatorTypes[t], left:a, right: b }; }
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
	/ v:number
		{ return { location, type: "NumberConstant", value: v }; }
	/ v:string
		{ return { location, type: "StringConstant", value: v }; }
	/ v:function_definition
		{ return { location, type: "LambdaFunction", value: v }; }
	/ table_constructor
	/ prefix_expression

index_expression
	= _ "." n:name
		{ return { location, type: "PropertyIndex", name:n } }
	/ _ "[" e:expression _ "]"
		{ return { location, type: "ExpressionIndex", value:e } }

group_expression
	= _ "(" exp:expression _ ")"
		{ return exp; }

base_expression
	= n:name
	/ group_expression

call_expression
	= a:arguments
		{ return { location, type: "FunctionCall", arguments:a } }
	/ _ ":" n:name a:arguments
		{ return { location, type: "PropertyCall", name:n, arguments:a } }

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
	= _ "[" k:expression _ "]" _ "=" v:expression
		{ return { location, type: "ExpressionField", key: k, value: v }; }
	/ n:name _ "=" v:expression
		{ return { location, type: "IdentifierField", name: n, value: v }; }
	/ v:expression
		{ return { location, type: "ValueField", value: v }; }

call_space
	= _ "function" wordbreak { return true }
	/ _ "virtual" wordbreak { return false }

function_definition
	= native:call_space body:function_body
		{ return { location, type: "LambdaFunctionDeclaration", native, body }; }

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
	= _ "(" params:parameter_list? _ ")" body:block _ "end" wordbreak
		{ return { location, type: "FunctionBody", parameters: params, body: body }; }

arguments
	= _ "(" l:expression_list? _ ")"
		{ return l; }
	/ string
		{ return { location, type: "StringConstant", value: v }; }
	/ table_constructor

table_constructor
	= _ "{" f:field_list? _ "}"
		{ return { location, type: "TableConstructor", fields: f }; }

/* These are helpers */
_
	= ([ \n\r\f\v\t] / comment)*

wordbreak
	= ![a-z0-9_]i

name
	= _ v:$([a-z_]i [a-z0-9_]i*) !{ return RESERVED.indexOf(v) >= 0 }
		{ return { location, type: "Identifier", name: v }; }

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
