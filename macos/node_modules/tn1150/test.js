/* eslint-env mocha */

var unorm = require('unorm')
var assert = require('assert')
var tn1150 = require('./')

describe('TN1150', function () {
  it('.compare', function () {
    assert(tn1150.compare('test', 'test') === 0)
    assert(tn1150.compare('test', 'Test') === 0)
    assert(tn1150.compare('Test', 'test') === 0)
    assert(tn1150.compare('test2', 'test1') > 0)
    assert(tn1150.compare('test1', 'test2') < 0)
    assert(tn1150.compare('Hellö', 'Hello') > 0)
    assert(tn1150.compare('Hello', 'Hellö') < 0)
    assert(tn1150.compare('abc', 'abcd') < 0)
    assert(tn1150.compare('abcd', 'abc') > 0)
    assert(tn1150.compare('BBB', 'aaa') > 0)
    assert(tn1150.compare('BBB', 'ccc') < 0)
    assert(tn1150.compare('Ϧaa', 'ϧaa') === 0)
    assert(tn1150.compare('ϧaa', 'Ϧaa') === 0)
  })

  it('.normalize', function () {
    assert.equal(tn1150.normalize, unorm.nfd)
  })
})
