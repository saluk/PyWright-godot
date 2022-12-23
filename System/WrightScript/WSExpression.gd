extends Node

func variables():
	return Commands.main.stack.variables

func NUM(n:String):
	if "." in n:
		return float(n)
	return int(n)
	
func EVAL(code:String):
	var code_spaces = Array(code.split(" ", true, 2))
	if len(code_spaces) == 1:
		return variables().get_truth(code_spaces[0])
	if len(code_spaces) == 2:
		code_spaces = [code_spaces[0], "=", code_spaces[1]]
	var current_value = variables().get_string(code_spaces[0])
	var operation = code_spaces[1]
	var check_value = code_spaces[2]
	if not operation in ["<", ">", "=", "!=", "<=", ">="]:
		check_value = operation + " " + check_value
		operation = "="
	match operation:
		"=":
			return current_value == check_value
		"!=":
			return current_value != check_value
		"<":
			return NUM(current_value) < NUM(check_value)
		">":
			return NUM(current_value) > NUM(check_value)
		"<=":
			return NUM(current_value) <= NUM(check_value)
		">=":
			return NUM(current_value) >= NUM(check_value)

func GV(v:String):
	if v[0].is_valid_integer():
		return NUM(v)
	if v.begins_with("'") and v.ends_with("'"):
		return v.substr(1, v.length()-2)
	var val = Commands.main.stack.variables.get_string(v)
	if val and val[0].is_valid_integer():
		return NUM(val)
	return val
	
func bool_to_string(b:bool):
	return {
		true: "true",
		false: "false"
	}[b]

func string_to_bool(s:String):
	if s in ["on", "1", "true"]:
		return true
	return false
	
var hello

func ADD(statements:Array):
	return GV(statements[0]) + GV(statements[1])
func MUL(statements:Array):
	return GV(statements[0]) * GV(statements[1])
func MINUS(statements:Array):
	return GV(statements[0]) - GV(statements[1])
func DIV(statements:Array):
	return GV(statements[0]) / GV(statements[1])
func EQ(statements:Array):
	var l = GV(statements[0])
	var r = GV(statements[1])
	if(typeof(l) != typeof(r)):
		return "false"
	return bool_to_string(GV(statements[0]) == GV(statements[1]))
func GTEQ(statements:Array):
	return bool_to_string(GV(statements[0]) >= GV(statements[1]))
func GT(statements:Array):
	return bool_to_string(GV(statements[0]) > GV(statements[1]))
func LT(statements:Array):
	return bool_to_string(GV(statements[0]) < GV(statements[1]))
func LTEQ(statements:Array):
	return bool_to_string(GV(statements[0]) <= GV(statements[1]))
func AND(statements:Array):
	if string_to_bool(statements[0]) and string_to_bool(statements[1]):
		return "true"
	return "false"
func OR(statements:Array):
	for statement in statements:
		if EVAL(statement):
			return true
	return false
func OR2(statements:Array):
	for statement in statements:
		if string_to_bool(statement):
			return "true"
	return "false"
	
func EXPR(line:String, level=0):
	var levels = ""
	for i in range(level):
		levels += " "
#	print(levels+"EXPR:",line)
	var statements = []
	var cur = ""
	var paren = []
	var quote = []
	for word in line.split(" "):
		var matched = false
		if paren.size()==0 and quote.size()==0:
			matched = true
			match word.strip_edges():
				"+":
					statements.append("ADD")
				"*":
					statements.append("MUL")
				"-":
					statements.append("MINUS")
				"/":
					statements.append("DIV")
				"==":
					statements.append("EQ")
				"<=":
					statements.append("LTEQ")
				">=":
					statements.append("GTEQ")
				"<":
					statements.append("LT")
				">":
					statements.append("GT")
				"AND":
					statements.append("AND")
				"OR":
					statements.append("OR2")
				_:
					matched = false
		if not matched and word.strip_edges():
#			print(levels+"UNMATCHED:", word.strip_edges())
			if paren.size()!=0:
				paren.append(word)
				if word.ends_with(")"):
					print("END PAREN:",paren)
					var statement = PoolStringArray(paren).join(" ")
					print(statement)
					statement = statement.substr(1, statement.length()-2)
					print(statement)
					statements.append(EXPR(statement, level+1))
					paren = []
			elif quote.size()!=0:
				quote.append(word)
				if word.ends_with("'"):
					var quote_j = PoolStringArray(quote).join(" ")
					statements.append(quote_j)
					quote = []
			elif word.begins_with("(") and word.ends_with(")"):
				statements.append(word.substr(1, word.length()-2))
			elif word.begins_with("("):
				paren.append(word)
			elif word.begins_with("'") and word.ends_with("'"):
				statements.append(word)
			elif word.begins_with("'"):
				quote.append(word)
			else:
				statements.append(word)
#		else:
#			print(levels+"MATCHED:", word)
#	print(levels+"STATEMENTS:", statements)
	return statements
	
class OpsSorter:
	static func sorter(a, b):
		var oop = ["MUL", "DIV", "ADD", "MINUS", "EQ", "LT", "GT", "LTEQ", "GTEQ", "OR2", "AND"]
		return oop.find(a[1]) < oop.find(b[1])

func EVAL_EXPR(expr):
	if not expr is Array:
		return String(expr)
	if expr.size() == 1:
		return EVAL_EXPR(expr[0])
#	print("EVAL_EXPR:", expr)
	var oop = ["MUL", "DIV", "ADD", "MINUS", "EQ", "LT", "GT", "LTEQ", "GTEQ", "OR2", "AND"]
	var ops = []

	# Insert equals anywhere there is no operation between two values
	var new_expr = []
	var mode = "val"
	for val in expr:
		if mode == "val":
			new_expr.append(val)
			mode = "op"
		elif mode == "op":
			if val in oop or val == '=':
				new_expr.append(val)
			else:
				new_expr.append("EQ")
				new_expr.append(val)
			mode = "val"
	expr = new_expr

	for i in range(expr.size()):
		if expr[i] in oop:
			ops.append([i, expr[i]])
	# Not sure what this is doing, but it's a kind of error handling
	if not ops:
		return String(expr[0])
	ops.sort_custom(OpsSorter, "sorter")
	var op = ops[0]
	var left = expr[op[0]-1]
	var right = expr[op[0]+1]
	var left_val = EVAL_EXPR(left)
	var right_val = EVAL_EXPR(right)
#	print("OP:", op, ", ", left_val, ", ", right_val)
	var result = call(op[1], [left_val, right_val])
	expr.remove(op[0]-1)
	expr.remove(op[0]-1)
	expr[op[0]-1] = result
#	print("NEWEXPR:", expr)
	return EVAL_EXPR(expr)
	
func EVAL_STR(s:String):
	return EVAL_EXPR(EXPR(s))

# This is probably busted for anything except very simple cases
func EVAL_SIMPLE(s:String):
	for simple in s.split(" AND "):
		var or_segments = simple.split(" OR ")
		if not OR(or_segments):
			return false
	return true

# Convert an is expression to an is_ex expression
# Main differences: 
#    $variable -> variable
#    word -> 'word'
#    = -> ==
# Not accurate: for any set of operands, the first operand
# will always try to lookup the variable.
# Use EVAL instead
func SIMPLE_TO_EXPR(s:String):
	var expr = []
	for word in s.split(" "):
		if word.begins_with("$"):
			expr.append(word.substr(1))
		elif word == '=':
			expr.append('==')
		elif word in ["<=", ">=", "==", "!=", ">", "<"]:
			expr.append(word)
		elif word.length()>0 and word[0].is_valid_integer():
			expr.append(word)
		else:
			expr.append("'"+word+"'")
	return PoolStringArray(expr).join(" ")
