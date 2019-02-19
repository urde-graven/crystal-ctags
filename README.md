# Crystal Ctags

Tool for generation `ctags` for **Crystal**

Fork of https://github.com/SuperPaintman/crystal-ctags with enough compatibility with Exuberant Ctags to make [Gutentags](https://github.com/ludovicchabant/vim-gutentags) and [CtrlP tjump](https://github.com/ivalkeen/vim-ctrlp-tjump) work. Needs https://github.com/urde-graven/crystal for compilation because upstream [Crystal](https://github.com/crystal-lang/crystal) has severe bugs in its OptionParser - this code is intentionally incompatible with it.

![Screenshot Gutentags][screenshot-gutentags-image]

![Screenshot][screenshot-image]


## Installation

From sources:

```sh
$ cd ~/Projects
$ git clone https://github.com/SuperPaintman/crystal-ctags
$ cd ./crystal-ctags
$ make
$ sudo make install
$ # or
$ sudo make reinstall
```


--------------------------------------------------------------------------------

## Usage

```sh
$ crystalctags -h
```


--------------------------------------------------------------------------------

## Test

```sh
$ crystal spec
# or
$ make test
```


--------------------------------------------------------------------------------

## Use with
### VIM: Gutentags

For example:
```vim
let g:gutentags_modules = ['ctags']
let g:gutentags_file_list_command = 'absolute///ag -l -i --nocolor --hidden -g "" .'
let g:gutentags_ctags_executable_crystal = "crystal-ctags"
let g:gutentags_project_info = []
call add(g:gutentags_project_info, {'type': 'crystal', 'file': 'main.cr'})
call add(g:gutentags_project_info, {'type': 'crystal', 'file': 'shard.yml'})
```

### VIM: TagBar

```vim
let g:tagbar_type_crystal = {
    \'ctagstype': 'crystal',
    \'ctagsbin': 'crystalctags',
    \'ctagsargs': '-f -',
    \'kinds': [
        \'c:classes',
        \'m:modules',
        \'d:defs',
        \'x:macros',
        \'l:libs',
        \'s:sruct or unions',
        \'f:fun'
    \],
    \'sro': '.',
    \'kind2scope': {
        \'c': 'namespace',
        \'m': 'namespace',
        \'l': 'namespace',
        \'s': 'namespace'
    \},
\}
```


--------------------------------------------------------------------------------

## Contributing

1. Fork it (<https://github.com/SuperPaintman/crystalctags/fork>)
2. Create your feature branch (`git checkout -b feature/<feature_name>`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin feature/<feature_name>`)
5. Create a new Pull Request


--------------------------------------------------------------------------------

## Contributors

- [SuperPaintman](https://github.com/SuperPaintman) SuperPaintman - creator, maintainer


--------------------------------------------------------------------------------

## API
[Docs][docs-url]


--------------------------------------------------------------------------------

## Changelog
[Changelog][changelog-url]


--------------------------------------------------------------------------------

## License

[MIT][license-url]


[license-url]: LICENSE
[changelog-url]: CHANGELOG.md
[docs-url]: https://superpaintman.github.io/crystalctags/
[screenshot-image]: README/screenshot.png
[screenshot-gutentags-image]: README/screenshot-gutentags.png
[travis-image]: https://img.shields.io/travis/SuperPaintman/crystalctags/master.svg?label=linux
[travis-url]: https://travis-ci.org/SuperPaintman/crystalctags
[shards-image]: https://img.shields.io/github/tag/superpaintman/crystalctags.svg?label=shards
[shards-url]: https://github.com/superpaintman/crystalctags

