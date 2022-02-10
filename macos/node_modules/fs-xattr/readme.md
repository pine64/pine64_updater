# fs-xattr

Node.js module for manipulating extended attributes.

There are already some libraries for this, why use `fs-xattr`?

- Very useful errors
- No limits on value size
- Clean and easy api
- Proper asynchronous implementation

## Installation

```sh
npm install --save fs-xattr
```

## Usage

```javascript
const xattr = require('fs-xattr')

await xattr.set('index.js', 'com.linusu.test', 'Hello, World!')

console.log(await xattr.get('index.js', 'com.linusu.test'))
//=> Hello, World!
```

## API

### `get(path, attr)`

- `path` (`string`, required)
- `attr` (`string`, required)
- returns `Promise<Buffer>` - a `Promise` that will resolve with the value of the attribute.

Get extended attribute `attr` from file at `path`.

### `getSync(path, attr)`

- `path` (`string`, required)
- `attr` (`string`, required)
- returns `Buffer`

Synchronous version of `get`.

### `set(path, attr, value)`

- `path` (`string`, required)
- `attr` (`string`, required)
- `value` (`Buffer` or `string`, required)
- returns `Promise<void>` - a `Promise` that will resolve when the value has been set.

Set extended attribute `attr` to `value` on file at `path`.

### `setSync(path, attr, value)`

- `path` (`string`, required)
- `attr` (`string`, required)
- `value` (`Buffer` or `string`, required)

Synchronous version of `set`.

### `remove(path, attr)`

- `path` (`string`, required)
- `attr` (`string`, required)
- returns `Promise<void>` - a `Promise` that will resolve when the value has been removed.

Remove extended attribute `attr` on file at `path`.

### `removeSync(path, attr)`

- `path` (`string`, required)
- `attr` (`string`, required)

Synchronous version of `remove`.

### `list(path)`

- `path` (`string`, required)
- returns `Promise<Array<string>>` - a `Promise` that will resolve with an array of strings, e.g. `['com.linusu.test', 'com.apple.FinderInfo']`.

List all attributes on file at `path`.

### `listSync(path)`

- `path` (`string`, required)
- returns `Array<string>`

Synchronous version of `list`.
