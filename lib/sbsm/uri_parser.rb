require 'rockit/rockit'
module SBSM
  # Parser for Uri
  # created by Rockit version 0.3.8 on Thu Sep 23 15:05:53 CEST 2004
  # Rockit is copyright (c) 2001 Robert Feldt, feldt@ce.chalmers.se
  # and licensed under GPL
  # but this parser is under LGPL
  tokens = [
    t1 = EofToken.new("EOF",/^(¤~~¤¤~^^~7926234081)/),
    t2 = Token.new("SLASH",/^(\/)/),
    t3 = Token.new("OTHER",/^([^\/]+)/),
    t4 = Token.new("LANG",/^([a-z]{2})/)
  ]
  productions = [
    p1 = Production.new("Uri'".intern,[:Uri],SyntaxTreeBuilder.new("Uri'",["uri"],[])),
    p2 = Production.new(:Uri,[t2, t4, t2, t3, t2, t3, t2, :Variables],SyntaxTreeBuilder.new("Uri",["_", "language", "_", "flavor", "_", "event", "_", "variables"],[])),
    p3 = Production.new(:Uri,[t2, t4, t2, t3, t2, t3, t2],SyntaxTreeBuilder.new("Uri",["_", "language", "_", "flavor", "_", "event"],[])),
    p4 = Production.new(:Uri,[t2, t4, t2, t3, t2, t3],SyntaxTreeBuilder.new("Uri",["_", "language", "_", "flavor", "_", "event"],[nil])),
    p5 = Production.new(:Uri,[t2, t4, t2, t3, t2],SyntaxTreeBuilder.new("Uri",["_", "language", "_", "flavor"],[])),
    p6 = Production.new(:Uri,[t2, t4, t2, t3],SyntaxTreeBuilder.new("Uri",["_", "language", "_", "flavor"],[nil])),
    p7 = Production.new(:Uri,[t2, t4, t2],SyntaxTreeBuilder.new("Uri",["_", "language"],[])),
    p8 = Production.new(:Uri,[t2, t4],SyntaxTreeBuilder.new("Uri",["_", "language"],[nil])),
    p9 = Production.new(:Uri,[t2],SyntaxTreeBuilder.new("Uri",["_"],[])),
    p10 = Production.new(:Variables,[:Plus402940192],LiftingSyntaxTreeBuilder.new(["pair"],[])),
    p11 = Production.new(:Plus402940192,[:Plus402940192, :Pair],ArrayNodeBuilder.new([1],0,nil,nil,[],true)),
    p12 = Production.new(:Plus402940192,[:Pair],ArrayNodeBuilder.new([0],nil,nil,nil,[],true)),
    p13 = Production.new(:Pair,[t3, t2, t3, t2],SyntaxTreeBuilder.new("Pair",["key", "_", "value"],[])),
    p14 = Production.new(:Pair,[t3, t2, t3],SyntaxTreeBuilder.new("Pair",["key", "_", "value"],[nil]))
  ]
  relations = [
  
  ]
  priorities = ProductionPriorities.new(relations)
  action_table = [[9, 2], [2, 1], [13, 8, 32, 1], [17, 2, 28, 1], [21, 4, 24, 1], [25, 2, 20, 1], [29, 4, 16, 1], [33, 2, 12, 1], [37, 4, 8, 1], [53, 2], [4, 1], [44, 7], [37, 4, 36, 1], [61, 4], [40, 7], [65, 2, 52, 7], [48, 7]]
  goto_hash = {0 => {1 => 1}, 12 => {4 => 14}, 8 => {2 => 10, 3 => 12, 4 => 11}}
  @@parse_table403281672 = ParseTable.new(productions,tokens,priorities,action_table,goto_hash,2,[
    :REDUCE,
    :SHIFT,
    :ACCEPT
  ])
  def SBSM._uri_parser
    GeneralizedLrParser.new(@@parse_table403281672)
  end
end
