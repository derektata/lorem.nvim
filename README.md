# lorem.nvim

Easily generate dummy text in Neovim

## currently under maintenance 🧰

### Todo List

- [x] - Generate words from another file
- [x] - Create ':LoremIpsum' command w/ args
- [ ] - Integrate with completion engine (nvim-cmp)

### Installation

#### Packer:

```lua
use {
  'derektata/lorem.nvim',
  config = function()
    require('lorem').opts {
      sentenceLength = "medium",
      comma_chance = 0.2,
      max_commas_per_sentence = 2,
    }
  end
}
```

#### Lazy:

```lua
return {
  'derektata/lorem.nvim',
  config = function()
      require('lorem').opts {
          sentenceLength = "medium",
          comma_chance = 0.2,
          max_commas_per_sentence = 2,
      }
  end
}
```

### Configuration

The plugin is designed to be as plug-and-play as possible, and therefore no setup is needed as it is shipped with sensible defaults. It is hovewer possible to customize the behavior of the plugin in setup like this:

```lua
require('lorem').opts {
    sentenceLength = "mixed",  -- using a default configuration
    comma_chance = 0.3,  -- 30% chance to insert a comma
    max_commas_per_sentence = 2  -- maximum 2 commas per sentence
}

-- or

require('lorem').opts {
    sentenceLength = { -- custom configuration
      words_per_sentence = 8,
      sentences_per_paragraph = 6
    },
    comma_chance = 0.3,  -- 30% chance to insert a comma
    max_commas_per_sentence = 2  -- maximum 2 commas per sentence
}
```

#### The comma_chance property

This property controls the likelihood of inserting a comma after a word within a sentence. This property allows for the generation of more natural-looking text by adding occasional commas, mimicking the natural pauses in human writing.

#### The sentenceLength property

This property determines the intervals for how long the sentences of latin words should be before ending them with a period. The following values are available:

#### The max_commas_per_sentence property

This property sets the maximum number of commas that can be inserted in a single sentence. This property ensures that sentences do not become overly complex or cluttered with too many commas, maintaining readability and natural flow.

| **Value**  | **Words Per Sentence** | **Sentences Per Paragraph** |
| :--------: | :--------------------: | :-------------------------: |
|   short    |           5            |              3              |
|   medium   |           10           |              5              |
|    long    |           14           |              7              |
| mixedShort |           8            |              4              |
|   mixed    |           12           |              6              |
| mixedLong  |           16           |              8              |

### Usage

#### in the editor:

```text
# defaults: 100 words, 1 paragraph
:LoremIpsum <mode> <amount>

                          ┌────────────┐        
                          │            │        
                          │    Menu    │        
                          │depending on│        
            ┌────────────┐│  previous  │        
            │   words    ││ selection  │        
            │ paragraphs ││            │        
            └────────────┘└────────────┘        
────────────────────────────────────────────────
:LoremIpsum     <TAB>         <TAB>             

# i.e.
:LoremIpsum words 1000
:LoremIpsum paragraphs 2
```

#### headless mode:

```bash
# print lorem ipsum words to the terminal
# (default: 100)
nvim --headless -c 'lua print(require("lorem").words())' +qall | tail -n +1

# print 500 words to the terminal
nvim --headless -c 'lua print(require("lorem").words(500))' +qall | tail -n +1

# using the lua file
nvim -l ./lorem.lua -w 10

# using the shell script
chmod +x lorem.sh
./lorem.sh -w 10
```