# Compile with: racc gherkin.y -o parser.rb

class GherkinRuby::Parser

# Declare tokens produced by the lexer
token NEWLINE
token DESCRIBE GROUPRULE RULE
token TAG
token GIVEN WHEN THEN AND OR BUT
token TEXT

rule

  Root:
    Describe
      Rules { result = val[0]; result.rules = val[1].flatten }
  | Describe
      GroupRules { result = val[0]; result.group_rules << val[1].flatten }
  ;

  Newline:
    NEWLINE
  | Newline NEWLINE
  ;

  Describe:
    DescribeHeader { result = val[0] }
  ;

  DescribeHeader:
    DescribeName           { result = val[0] }
  | DescribeName Newline   { result = val[0] }
  | DescribeName Newline
      Description         { result = val[0]; result.description = val[2] }
  ;

  DescribeName:
    DESCRIBE TEXT          { result = AST::Describe.new(val[1]); result.pos(filename, lineno) }
  | Newline DESCRIBE TEXT  { result = AST::Describe.new(val[2]); result.pos(filename, lineno) }
  ;

  Description:
    TEXT Newline             { result = val[0] }
  | Description TEXT Newline { result = val[0...-1].flatten }
  ;

  GroupRules:
    GroupRule               { result = [val[0]] }
  | GroupRules GroupRule    { result = val[0].members << val[1].flatten }
  ;

  GroupRule:
    GroupRuleHeader
      Steps
        Rules { result = val[0]; result.steps << val[1].flatten; result.members << val[2].flatten }
  ;

  GroupRuleHeader:
    GROUPRULE Newline    { result = AST::GroupRule.new; result.pos(filename, lineno) }
  ;

  Steps:
    Step                  { result = [val[0]] }
  | Step Newline          { result = [val[0]] }
  | Step Newline Steps    { val[2].unshift(val[0]); result = val[2].flatten }
  ;

  Step:
    Keyword TEXT          { result = AST::Step.new(val[1], val[0]); result.pos(filename, lineno) }
  ;

  Keyword:
    GIVEN | WHEN | THEN | AND | OR | BUT
  ;

  Rules:
    Rule              { result = [val[0]] }
  | Rules Rule    { result = val[0] << val[1] }
  ;

  Rule:
    RULE TEXT Newline
      Steps { result = AST::Rule.new(val[1], val[3]); result.pos(filename, lineno - 1) }
  ;

end

---- header
  require_relative "lexer"
  require_relative "../ast"

---- inner

  def parse(input)
    @yydebug = true if ENV['DEBUG_RACC']
    scan_str(input)
  end
