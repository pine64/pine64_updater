/// <reference types="node" />

import { WriteStream } from 'fs'

declare type OpenMode = 'w' | 'w+'
declare type OpenResult = { fd: number, path: string }

declare type OpenCallback = (err: NodeJS.ErrnoException | null, result: OpenResult | undefined) => void
declare type PathCallback = (err: NodeJS.ErrnoException | null, path: string | undefined) => void

declare type WriteFileOptions = { encoding?: BufferEncoding | null, mode?: Mode; flag?: string; } | string | null
declare type WriteStreamOptions = { flags?: string, encoding?: BufferEncoding, fd?: number, mode?: number, autoClose?: boolean, emitClose?: boolean, start?: number, highWaterMark?: number } | string | null

declare interface FSTemp {
  /**
   * Asynchronous open(2) - create a temporary file and open it.
   * @param mode A file mode. If a string is passed, it is parsed as an octal integer. If not supplied, defaults to `0o666`.
   */
  open (flags: OpenMode, mode: number | string | undefined | null, callback: OpenCallback): void

  /**
   * Asynchronous open(2) - create a temporary file and open it, its mode will be `0o666`.
   */
  open (flags: OpenMode, callback: OpenCallback): void

  /**
   * Synchronous open(2) - create a temporary file and open it, returning a file descriptor..
   * @param mode A file mode. If a string is passed, it is parsed as an octal integer. If not supplied, defaults to `0o666`.
   */
  openSync (flags: OpenMode, mode?: number | string | null): OpenResult

  /**
   * Asynchronous mkdir(2) - create a temporary directory.
   * @param mode A file mode. If a string is passed, it is parsed as an octal integer. If not supplied, defaults to `0o666`.
   */
  mkdir (mode: string | number | null | undefined, callback: PathCallback): void

  /**
   * Asynchronous mkdir(2) - create a temporary directory with a mode of `0o777`.
   */
  mkdir (callback: PathCallback): void

  /**
   * Synchronous mkdir(2) - create a temporary directory.
   * @param mode A file mode. If a string is passed, it is parsed as an octal integer. If not supplied, defaults to `0o666`.
   * @returns The path to the newly created directory.
   */
  mkdirSync (mode?: string | number | null): string

  /**
   * Asynchronously writes data to a temporary file.
   * @param data The data to write. If something other than a Buffer or Uint8Array is provided, the value is coerced to a string.
   * @param options Either the encoding for the file, or an object optionally specifying the encoding, file mode, and flag.
   * If `encoding` is not supplied, the default of `'utf8'` is used.
   * If `mode` is not supplied, the default of `0o666` is used.
   * If `mode` is a string, it is parsed as an octal integer.
   * If `flag` is not supplied, the default of `'w'` is used.
   */
  writeFile (data: string | NodeJS.ArrayBufferView, options: WriteFileOptions, callback: PathCallback): void

  /**
   * Asynchronously writes data to a temporary file.
   * @param data The data to write. If something other than a Buffer or Uint8Array is provided, the value is coerced to a string.
   */
  writeFile (data: string | NodeJS.ArrayBufferView, callback: PathCallback): void

  /**
   * Synchronously writes data to a temporary file.
   * @param data The data to write. If something other than a Buffer or Uint8Array is provided, the value is coerced to a string.
   * @param options Either the encoding for the file, or an object optionally specifying the encoding, file mode, and flag.
   * If `encoding` is not supplied, the default of `'utf8'` is used.
   * If `mode` is not supplied, the default of `0o666` is used.
   * If `mode` is a string, it is parsed as an octal integer.
   * If `flag` is not supplied, the default of `'w'` is used.
   * @returns The path to the newly created file.
   */
  writeFileSync (data: string | NodeJS.ArrayBufferView, options?: WriteFileOptions): string

  /**
   * Returns a new `WriteStream` object.
   */
  createWriteStream (options?: WriteStreamOptions): WriteStream
}

declare const temp: FSTemp & { template: (template: string) => FSTemp }
export = temp
