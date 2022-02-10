var murmur = require('./')
var assert = require('assert')
var isEqual = require('arraybuffer-equal')
var hexToArrayBuffer = require('hex-to-array-buffer')

var testCases = [
  ['00000000', ''],
  ['13d26bba', 'test'],
  ['f72c4e83', 'linus'],
  ['cd13f373', 'murmur'],
  ['8e85bb8a', 'veni, vidi, vici'],
  ['27dd6aa0', 'Caesar non supra grammaticos!'],
  ['290e9a82', 'Node.js® is a JavaScript runtime built on Chrome\'s V8 JavaScript engine.'],
  ['ec88f7f7', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec consectetur mollis orci a consectetur. Maecenas in ornare ligula, vel venenatis mauris.']
]

testCases.forEach(function (testCase) {
  assert(isEqual(murmur(testCase[1]), hexToArrayBuffer(testCase[0])))
})
