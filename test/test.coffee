assert = require 'assert'
should = require 'should'

{ArgumentParser} = require '..'

it 'should throw on overlapping registered keywords', ->
  
  f().should.be.Number().and.equal(42)
  f.should.not.throw()
