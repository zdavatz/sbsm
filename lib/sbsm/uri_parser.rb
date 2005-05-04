require 'rockit/rockit'
module SBSM
  # Parser for Uri
  # created by Rockit version 0.3.8 on Wed May 04 12:02:16 CEST 2005
  # Rockit is copyright (c) 2001 Robert Feldt, feldt@ce.chalmers.se
  # and licensed under GPL
  # but this parser is under LGPL
  tokens = [
    t1 = EofToken.new("EOF",/^(¤~~¤¤~^^~6529900943)/),
    t2 = Token.new("SLASH",/^(\/)/),
    t3 = Token.new("OTHER",/^([^\/]+)/),
    t4 = Token.new("LANG",/^([a-z]{2})/)
  ]
  productions = [
    p1 = Production.new("Uri'".intern,[:Uri],SyntaxTreeBuilder.new("Uri'",["uri"],[])),
    p2 = Production.new(:Uri,[t2, t4, t2, t3, t2, :Variables],SyntaxTreeBuilder.new("Uri",["_", "language", "_", "event", "_", "variables"],[])),
    p3 = Production.new(:Uri,[t2, t4, t2, t3, t2],SyntaxTreeBuilder.new("Uri",["_", "language", "_", "event"],[])),
    p4 = Production.new(:Uri,[t2, t4, t2, t3],SyntaxTreeBuilder.new("Uri",["_", "language", "_", "event"],[nil])),
    p5 = Production.new(:Uri,[t2, t4, t2],SyntaxTreeBuilder.new("Uri",["_", "language"],[])),
    p6 = Production.new(:Uri,[t2, t4],SyntaxTreeBuilder.new("Uri",["_", "language"],[nil])),
    p7 = Production.new(:Uri,[t2],SyntaxTreeBuilder.new("Uri",["_"],[])),
    p8 = Production.new(:Variables,[:Plus403277820, t2],LiftingSyntaxTreeBuilder.new(["pair"],[])),
    p9 = Production.new(:Variables,[:Plus403277820],LiftingSyntaxTreeBuilder.new(["pair"],[nil])),
    p10 = Production.new(:Plus403277820,[:Plus403277820, :Pair],ArrayNodeBuilder.new([1],0,nil,nil,[],true)),
    p11 = Production.new(:Plus403277820,[:Pair],ArrayNodeBuilder.new([0],nil,nil,nil,[],true)),
    p12 = Production.new(:Pair,[t3, t2, t3, t2],SyntaxTreeBuilder.new("Pair",["key", "_", "value"],[])),
    p13 = Production.new(:Pair,[t3, t2, t3],SyntaxTreeBuilder.new("Pair",["key", "_", "value"],[nil])),
    p14 = Production.new(:Pair,[t3, t2, t2],SyntaxTreeBuilder.new("Pair",["key"],[])),
    p15 = Production.new(:Pair,[t3],SyntaxTreeBuilder.new("Pair",["key"],[]))
  ]
  relations = [
  
  ]
  priorities = ProductionPriorities.new(relations)
  action_table = [[9, 2], [2, 1], [13, 8, 24, 1], [17, 2, 20, 1], [21, 4, 16, 1], [25, 2, 12, 1], [29, 4, 8, 1], [45, 2, 56, 7], [29, 4, 53, 2, 32, 1], [4, 1], [40, 7], [57, 4, 61, 2], [36, 7], [28, 1], [65, 2, 48, 7], [52, 7], [44, 7]]
  goto_hash = {0 => {1 => 1}, 6 => {2 => 9, 3 => 8, 4 => 10}, 8 => {4 => 12}}
  @@parse_table403270908 = ParseTable.new(productions,tokens,priorities,action_table,goto_hash,2,[
    :REDUCE,
    :SHIFT,
    :ACCEPT
  ])
  def SBSM._uri_parser
    GeneralizedLrParser.new(@@parse_table403270908)
  end
end
