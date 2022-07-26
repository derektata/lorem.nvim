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
