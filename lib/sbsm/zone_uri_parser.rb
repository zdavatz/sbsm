require 'rockit/rockit'
module SBSM
  # Parser for Uri
  # created by Rockit version 0.3.8 on Wed Jul 19 18:24:42 CEST 2006
  # Rockit is copyright (c) 2001 Robert Feldt, feldt@ce.chalmers.se
  # and licensed under GPL
  # but this parser is under LGPL
  tokens = [
    t1 = EofToken.new("EOF",/^(¤~~¤¤~^^~3493746103)/),
    t2 = Token.new("SLASH",/^(\/)/),
    t3 = Token.new("OTHER",/^([^\/]+)/),
    t4 = Token.new("LANG",/^([a-z]{2})/)
  ]
  productions = [
    p1 = Production.new("Uri'".intern,[:Uri],SyntaxTreeBuilder.new("Uri'",["uri"],[])),
    p2 = Production.new(:Uri,[t2, t4, t2, t3, t2, t3, t2, :Variables],SyntaxTreeBuilder.new("Uri",["_", "language", "_", "zone", "_", "event", "_", "variables"],[])),
    p3 = Production.new(:Uri,[t2, t4, t2, t3, t2, t3, t2],SyntaxTreeBuilder.new("Uri",["_", "language", "_", "zone", "_", "event"],[])),
    p4 = Production.new(:Uri,[t2, t4, t2, t3, t2, t3],SyntaxTreeBuilder.new("Uri",["_", "language", "_", "zone", "_", "event"],[nil])),
    p5 = Production.new(:Uri,[t2, t4, t2, t3, t2],SyntaxTreeBuilder.new("Uri",["_", "language", "_", "zone"],[])),
    p6 = Production.new(:Uri,[t2, t4, t2, t3],SyntaxTreeBuilder.new("Uri",["_", "language", "_", "zone"],[nil])),
    p7 = Production.new(:Uri,[t2, t4, t2],SyntaxTreeBuilder.new("Uri",["_", "language"],[])),
    p8 = Production.new(:Uri,[t2, t4],SyntaxTreeBuilder.new("Uri",["_", "language"],[nil])),
    p9 = Production.new(:Uri,[t2],SyntaxTreeBuilder.new("Uri",["_"],[])),
    p10 = Production.new(:Variables,[:Plus403922760, t2],LiftingSyntaxTreeBuilder.new(["pair"],[])),
    p11 = Production.new(:Variables,[:Plus403922760],LiftingSyntaxTreeBuilder.new(["pair"],[nil])),
    p12 = Production.new(:Plus403922760,[:Plus403922760, :Pair],ArrayNodeBuilder.new([1],0,nil,nil,[],true)),
    p13 = Production.new(:Plus403922760,[:Pair],ArrayNodeBuilder.new([0],nil,nil,nil,[],true)),
    p14 = Production.new(:Pair,[t3, t2, t3, t2],SyntaxTreeBuilder.new("Pair",["key", "_", "value"],[])),
    p15 = Production.new(:Pair,[t3, t2, t3],SyntaxTreeBuilder.new("Pair",["key", "_", "value"],[nil])),
    p16 = Production.new(:Pair,[t3, t2, t2],SyntaxTreeBuilder.new("Pair",["key"],[])),
    p17 = Production.new(:Pair,[t3],SyntaxTreeBuilder.new("Pair",["key"],[]))
  ]
  relations = [
  
  ]
  priorities = ProductionPriorities.new(relations)
  action_table = [[9, 2], [2, 1], [13, 8, 32, 1], [17, 2, 28, 1], [21, 4, 24, 1], [25, 2, 20, 1], [29, 4, 16, 1], [33, 2, 12, 1], [49, 4, 8, 1], [53, 2, 49, 4, 40, 1], [4, 1], [48, 7], [61, 2, 64, 7], [36, 1], [44, 7], [65, 2, 69, 4], [60, 7], [73, 2, 56, 7], [52, 7]]
  goto_hash = {0 => {1 => 1}, 8 => {2 => 10, 3 => 9, 4 => 11}, 9 => {4 => 14}}
  @@parse_table403739556 = ParseTable.new(productions,tokens,priorities,action_table,goto_hash,2,[
    :REDUCE,
    :SHIFT,
    :ACCEPT
  ])
  def SBSM._zone_uri_parser
    GeneralizedLrParser.new(@@parse_table403739556)
  end
end
