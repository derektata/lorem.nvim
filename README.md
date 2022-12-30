# lorem.nvim

Easily generate dummy text in Neovim

## currently under maintenance 🧰

### Todo List
- [X] - Generate words from another file
- [X] - Create ':LoremIpsum' command w/ args
- [ ] - Integrate with completion engine (nvim-cmp)

### Installation
Packer:
```lua
use { "derektata/lorem.nvim" }
```

### Configuration
The plugin is designed to be as plug-and-play as possible, and therefore no setup is needed as it is shipped with sensible defaults. It is hovewer possible to customize the behavior of the plugin in setup like this:

```lua
require('lorem').setup({
  sentenceLength = "mixedShort",
  comma = 0.1
})
```

#### The comma property
This property describes the likelihood of having a comma added to a sentence when there has passed at least 3 words since the last comma. A value of 0 would completely disable commas, and a value of 1 would make it so that there would be a comma every third word

#### The sentenceLength property
This property determines the intervals for how long the sentences of latin words should be before ending them with a period. The following values are available:

|  **Value**  | **Lower Bound** 	| **Upper Bound** 	|
|:----------:	|:---------------:	|:---------------:	|
| mixed      	| 3               	| 100             	|
| mixedLong  	| 30              	| 100             	|
| mixedShort 	| 3               	| 30              	|
| long       	| 40              	| 60              	|
| medium     	| 20              	| 40              	|
| short      	| 3               	| 20              	|

### Usage
#### in the editor:
```text
# default: 100
:LoremIpsum <number_of_words>

# i.e.
:LoremIpsum 750
```

#### headless mode:
```bash
# print lorem ipsum words to the terminal 
# (default: 100)
nvim --headless \
  +'lua print(require("lorem").gen_words())' \
  +q

# print 500 words to the terminal
nvim --headless \
  +'lua print(require("lorem").gen_words(500))' \
  +q
```
