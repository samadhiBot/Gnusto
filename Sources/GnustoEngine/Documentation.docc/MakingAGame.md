# Making a Game


```zsh
export GAME=FrobozzMagicDemoKit

mkdir $GAME
cd $GAME
swift package init --name $GAME
swift package add-dependency https://github.com/samadhiBot/Gnusto.git

open Package.swift # to open the new package in Xcode
# code . # to open the new package in VS Code
```
