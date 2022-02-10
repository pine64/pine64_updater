/**
 * Get extended attribute `attr` from file at `path`.
 *
 * @returns a `Promise` that will resolve with the value of the attribute.
 */
export function get (path: string, attr: string): Promise<Buffer>

/**
 * Synchronous version of `get`.
 */
export function getSync (path: string, attr: string): Buffer

/**
 * Set extended attribute `attr` to `value` on file at `path`.
 *
 * @returns a `Promise` that will resolve when the value has been set.
 */
export function set (path: string, attr: string, value: Buffer | string): Promise<void>

/**
 * Synchronous version of `set`.
 */
export function setSync (path: string, attr: string, value: Buffer | string): void

/**
 * Remove extended attribute `attr` on file at `path`.
 *
 * @returns a `Promise` that will resolve when the value has been removed.
 */
export function remove (path: string, attr: string): Promise<void>

/**
 * Synchronous version of `remove`.
 */
export function removeSync (path: string, attr: string): void

/**
 * List all attributes on file at `path`.
 *
 * @returns a `Promise` that will resolve with an array of strings, e.g. `['com.linusu.test', 'com.apple.FinderInfo']`.
 */
export function list (path: string): Promise<string[]>

/**
 * Synchronous version of `list`.
 */
export function listSync (path: string): string[]
