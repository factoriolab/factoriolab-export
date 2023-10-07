# FactorioLab Export (Deprecated)

**NOTE: This project has been deprecated, in favor of npm scripts inside the factoriolab repository itself. This tool is no longer maintained and will not generate data sets that work with the latest versions of FactorioLab.**

This is the repository for [FactorioLab Export](https://mods.factorio.com/mod/factoriolab-export), a [Factorio](https://www.factorio.com/) mod that logs game data to JSON files and an icon sprite sheet that can be used by [FactorioLab](https://factoriolab.github.io).

After following the steps in [getting started](#getting-started), you can use this mod to [create a new data set](#creating-a-new-data-set), [update an existing data set](#updating-an-existing-data-set), or [localize a data set](#localizing-a-data-set).

This mod works best when run in Instrument Mode. [Learn more](#why-instrument-mode)

## Getting started

1. Install this mod alongside any mods that should be included in the data set
1. Set up Steam to run this mod in [Instrument Mode](https://lua-api.factorio.com/latest/Instrument.html)
   - In the library, right click Factorio and in Launch Options enter: `--instrument-mod factoriolab-export`
   - Alternately, run Factorio from the command line with these options
   - [Why instrument mode?](#why-instrument-mode)
1. Fork and clone the [FactorioLab](https://github.com/factoriolab/factoriolab) repository, and follow the instructions for [running locally](https://github.com/factoriolab/factoriolab#running-locally)

## Creating a new data set

1. Ensure the Factorio language is set to Default
1. Start a new game
1. A message should be logged indicating the output has been written to `%APPDATA%\Factorio\script-output\factoriolab-export`
   - A normal export includes `data.json`, `hash.json`, and `icons.png`
1. Create a new folder in the [FactorioLab](https://github.com/factoriolab/factoriolab) repository under `src\data`
   - These folders use a three-letter abbreviation for brevity when used in the URL, or a combination of three-letter abbreviations if multiple mod sets are included (e.g. `bobang` for Bob's and Angel's)
1. Add an entry for this mod set in `factoriolab\src\data\index.ts`
   - This should include the folder name as the `id`, a friendly name as the `name`, and `game: Game.Factorio`
   - Also add the `id` of the mod to the end of the `hash` array in the same file
1. Double check the `defaults` object in `data.json` to ensure reasonable defaults are used for this data set
1. Run the application and load the data set, then refresh the page
1. If the calculator fails to find a solution within five seconds, update the `disabledRecipes` in `defaults`
   - A suggested default for this will also be logged to the browser console

## Updating an existing data set

1. Ensure the Factorio language is set to Default
1. Start a new game
1. A message should be logged indicating the output has been written to `%APPDATA%\Factorio\script-output\factoriolab-export`
   - A normal export includes `data.json`, `hash.json`, and `icons.png`
1. Copy **only** `data.json` and `icons.png` to the appropriate folder in the [FactorioLab](https://github.com/factoriolab/factoriolab) repository under `src\data`
   - **Do not** copy `hash.json`, overwriting the old file would break existing saved links
1. Double check the `defaults` object in `data.json`, or copy the `defaults` from the original data set if it is still valid
1. Run the application and load the data set, then refresh the page
   - An object will be logged to the browser console indicating the new `hash` for this data set
   - Copy that object and overwrite the existing `hash.json` for this data set, this should only append ids
1. If the calculator fails to find a solution within five seconds, update the `disabledRecipes`
   - A suggested default for this will also be logged to the browser console

## Localizing a data set

1. Ensure the Factorio language is set to the language you want to use for localization
1. Start a new game
1. A message should be logged indicating the output has been written to `%APPDATA%\Factorio\script-output\factoriolab-export`
   - A locale export includes `i18n\lang.json`, where `lang` is the language code
1. Copy this folder and its contents to the appropriate folder in the [FactorioLab](https://github.com/factoriolab/factoriolab) repository under `src\data`
1. Run the application and load the data set, then choose the language you localized to verify the localized data works as expected

## Why instrument mode?

Running in instrument mode is technically optional but strongly recommended and required if submitting a PR to FactorioLab.

FactorioLab Export uses instrument mode to check icon data for cases where icons will be rendered at unexpected sizes in the game, to ensure that the generated sprite sheet sizes the icons appropriately. In certain cases icons can bleed out of the expected size or can be scaled in unexpected ways that can only be detected in the data stage. FactorioLab Export runs these checks in the `instrument-after-data.lua` file to ensure that it has the most up to date icon information from all loaded mods.

Unfortunately, the Factorio Lua runtime exposes no method to determine what size a sprite will be rendered to when using `LuaRendering.draw_sprite`. By checking the icons in the data stage, FactorioLab Export can predict the size and use the `scale` parameter to ensure all the icons are the desired size.

## Warnings and errors

FactorioLab Export checks for a few edge cases that do not currently work well with the FactorioLab calculator.

1. > [FLE] Detected multiple fuel categories for entity `id`, exporting first category only
   - FactorioLab currently can't handle factories that allow mutiple fuel categories, see issue [#744](https://github.com/factoriolab/factoriolab/issues/744)
   - FactorioLab Export will only include the first fuel category
1. > [FLE] Skipping boiler recipe for entity `id`, failed to find water or steam fluid
   - FactorioLab generates boiler recipes using the `water` and `steam` items. If those items are not found due to changes from a mod, it cannot create boiler recipes
1. > [FLE] Skipping recipe `id`, failed to find producers
   - FactorioLab Export couldn't find any factories that allow this recipe
   - This most commonly occurs when the mod attempts to generate a recipe to generate the burnt result of a fuel, but the fuel is only allowed in entities like trains that cannot be used as producers in FactorioLab
1. > [FLE] Failed to find fluid or item prototype for recipe product/ingredient `id`
   - This indicates a problem where a product or ingredient could not be found in the list of `game.item_prototypes` or `game.fluid_prototypes`
1. > [FLE] Failed to find appropriate tech to represent infinite research, looking for `id`
   - FactorioLab Export includes recipes for infinite technologies, and attempts to create a category for these based on the `space-science-pack` technology
   - If that technology does not exist in the mods loaded, need to declare an explicit tech to use - please open an issue
