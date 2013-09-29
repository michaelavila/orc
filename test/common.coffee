global.sinon = require 'sinon'
global.chai = require 'chai'
global.should = require('chai').should()
global.expect = require('chai').expect
global.AssertionError = require('chai').AssertionError

global.swallow = (thrower) ->
  try
    thrower()
  catch error
    console.log error

sinonChai = require 'sinon-chai'
chai.use sinonChai

require('sinon-mocha').enhance global.sinon
