var assert = require('assert')
var randomPath = require('./')

/* Invalid templates */
assert.throws(function () {
  randomPath('/tmp', 'bad template')
})

assert.throws(function () {
  randomPath('/tmp', 'one: %s, two: %s')
})

assert.throws(function () {
  randomPath('/tmp', [1, 2])
})

assert.throws(function () {
  randomPath.validateTemplate('bad template')
})

assert.throws(function () {
  randomPath.validateTemplate('one: %s, two: %s')
})

assert.throws(function () {
  randomPath.validateTemplate([1, 2])
})

/* Valid templates */
randomPath.validateTemplate('%s')
randomPath.validateTemplate('%s.txt')
randomPath.validateTemplate('test-%s')
randomPath.validateTemplate('test-%s.exe')
randomPath.validateTemplate('random => %s')

/* Valid path */
var a = randomPath('/tmp', 'test-%s.txt')
var b = randomPath('/tmp', 'test-%s.txt')
var c = randomPath('/tmp', 'test-%s.txt')

assert.notStrictEqual(a, b)
assert.notStrictEqual(a, c)
assert.notStrictEqual(b, c)

assert.ok(/tmp[\\/]test-[0-9A-Z]{7}\.txt$/.test(a))
assert.ok(/tmp[\\/]test-[0-9A-Z]{7}\.txt$/.test(b))
assert.ok(/tmp[\\/]test-[0-9A-Z]{7}\.txt$/.test(c))
