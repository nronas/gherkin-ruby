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
    Describe     { result = val[0]; }
  |
    Describe
      Rules { result = val[0]; result.rules = val[1] }
  | DescribeTags Describe { result = val[1]; result.tags = val[0] }
  | DescribeTags Describe
      Rules { result = val[1]; result.rules = val[2]; result.tags = val[0] }
  ;

  Newline:
    NEWLINE
  | Newline NEWLINE
  ;

  DescribeTags:
    Tags { result = val[0] }
  | Newline Tags { result = val[1] }

  Describe:
    DescribeHeader { result = val[0] }
  | DescribeHeader
      GroupRule  { result = val[0]; result.group_rule = val[1] }
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

  GroupRule:
    GroupRuleHeader
      Steps               { result = val[0]; result.steps = val[1] }
  ;

  GroupRuleHeader:
    GROUPRULE Newline    { result = AST::GroupRule.new; result.pos(filename, lineno) }
  ;

  Steps:
    Step                  { result = [val[0]] }
  | Step Newline          { result = [val[0]] }
  | Step Newline Steps    { val[2].unshift(val[0]); result = val[2] }
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
  | Tags Newline
    RULE TEXT Newline
      Steps { result = AST::Rule.new(val[3], val[5], val[0]); result.pos(filename, lineno - 2) }
  ;

  Tags:
    TAG         { result = [AST::Tag.new(val[0])] }
  | Tags TAG    { result = val[0] << AST::Tag.new(val[1]) }
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
