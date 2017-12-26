assert = require 'assert'
should = require 'should'

f = -> 42

it 'should work', ->
  f.should.be.Number().and.equal(42)
  f.should.not.throw()
