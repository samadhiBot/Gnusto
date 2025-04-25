# Cloak of Darkness - a simple demonstration of Interactive Fiction

Written by Roger Firth on 17 Sepember 1999.

## The "Cloak of Darkness" specification

https://web.archive.org/web/20190916101552/http://www.firthworks.com/roger/cloak/

The various implementations have been made as similar as possible. That is, things like object names and room descriptions should be identical, and the general flow of the game should be pretty comparable. Having said that, the games are implemented using the native capabilities of the various systems, using features that a beginner might be expected to master; there shouldn't be any need to resort to assembler routines, library hacks, or other advanced techniques. The target is to write naturally and simply, while sticking as closely as possible to the goal of making the games directly equivalent.

"Cloak of Darkness" is not going to win prizes for its prose, imagination or subtlety. Or scope: it can be played to a successful conclusion in five or six moves, so it's not going to keep you guessing for long. (On the other hand, it may qualify as the most widely-available game in the history of the genre.) There are just three rooms and three objects.

- The **Foyer** of the Opera House is where the game begins. This empty room has doors to the south and west, also an unusable exit to the north. There is nobody else around.
- The **Bar** lies south of the **Foyer**, and is initially unlit. Trying to do anything other than return northwards results in a warning message about disturbing things in the dark.
- On the wall of the **Cloakroom**, to the west of the **Foyer**, is fixed a small brass **hook**.
- Taking an inventory of possessions reveals that the player is wearing a black velvet **cloak** which, upon examination, is found to be light-absorbent. The player can drop the **cloak** on the floor of the **Cloakroom** or, better, put it on the **hook**.
- Returning to the **Bar** without the **cloak** reveals that the room is now lit. A **message** is scratched in the sawdust on the floor.
- The **message** reads either "You have won" or "You have lost", depending on how much it was disturbed by the player while the room was dark.
- The act of reading the **message** ends the game.

And that's all there is to it...

## Original Inform Version

Found at https://github.com/johanberntsson/PunyInform/blob/master/cloak.inf

```inform
!% -~S
!% $OMIT_UNUSED_ROUTINES=1
!% $ZCODE_LESS_DICT_DATA=1

! The very first lines of the main source code file for a game can
! contain compiler options, like the lines above. -~S disables
! strict error checking. This is otherwise used in z5 and z8 games by
! default. While useful for debugging, it adds ~10 KB to the story file
! size and it makes the game slower.
! $OMIT_UNUSED_ROUTINES=1 makes the compiler remove all routines which
! aren't used. This can save some space.

! ============================================================================ !
!   Cloak of Darkness - a simple demonstration of Interactive Fiction
!	   This version for INFORM written by Roger Firth on 17Sep99
! ============================================================================ !

! When compiling to z8, use the standard library instead
#Iftrue (#version_number == 8);
Constant USEINFORM;
Constant MANUAL_PRONOUNS;
#Endif;

Constant Story	  "Cloak of Darkness";
Constant Headline   "^A basic IF demonstration.^";
Constant MAX_SCORE  2;

Release 3;
Serial "221116";

Constant STATUSLINE_SCORE; Statusline score;
Constant INITIAL_LOCATION_VALUE = foyer;

[ DeathMessage; print "You have lost"; ];


#Ifndef USEINFORM;

Include "globals.h";
Include "puny.h";

#Endif;

#Ifdef USEINFORM;

Include "Parser";
Include "VerbLib";

#Endif;

! ============================================================================ !

Object  foyer "Foyer of the Opera House"
  with  description
		   "You are standing in a spacious hall, splendidly decorated in red
			and gold, with glittering chandeliers overhead. The entrance from
			the street is to the north, and there are doorways south and west.",
		s_to  bar,
		w_to  cloakroom,
		n_to
		   "You've only just arrived, and besides, the weather outside
			seems to be getting worse.",
  has   light;

Object  cloakroom "Cloakroom"
  with  description
		   "The walls of this small room were clearly once lined with hooks,
			though now only one remains. The exit is a door to the east.",
		e_to  foyer,
  has   light;

Object  hook "small brass hook" cloakroom
  with  name 'small' 'brass' 'hook' 'peg',
		description [;
			print "It's just a small brass hook, ";
			if (self == parent(cloak)) "with a cloak hanging on it.";
			"screwed to the wall.";
		],
  has   scenery supporter;

Object  bar "Foyer bar"
  with  description
		   "The bar, much rougher than you'd have guessed after the opulence
			of the foyer to the north, is completely empty. There seems to
			be some sort of message scrawled in the sawdust on the floor.",
		n_to  foyer,
		before [ _test;
			Look, Inv, Going:
				rfalse;
			Go:
#ifdef USEINFORM;
				_test = self hasnt light && noun ~= n_obj;
#IfNot;
				_test = self hasnt light && selected_direction ~= n_to;
#EndIf;
				if (_test) {
					message.number = message.number + 2;
					"Blundering around in the dark isn't a good idea!";
				}
			default:
				if (self hasnt light) {
					message.number = message.number + 1;
					"In the dark? You could easily disturb something!";
				}
		],
  has   ~light;

Object  cloak "velvet cloak"
  with
		parse_name [ _words;
			while(NextWord() == 'handsome' or 'dark' or 'black' or 'velvet' or 'satin' or 'cloak') _words++;
			return _words;
		],
!		name 'handsome' 'dark' 'black' 'velvet' 'satin' 'cloak',
		description
		   "A handsome cloak, of velvet trimmed with satin, and slightly
			spattered with raindrops. Its blackness is so deep that it
			almost seems to suck light from the room.",
		before [;
			Drop, PutOn:
				if (location ~= cloakroom)
				   "This isn't the best place to leave a smart cloak
					lying around.";
		],
		after [;
			Take: give bar ~light;
			Drop, PutOn:
				if (location == cloakroom) {
					give bar light;
					if (action == ##PutOn && self has general) {
						give self ~general;
						score++;
						}
					}
		],
  has   clothing general;

Object  message "scrawled message" bar
  with  name 'message' 'sawdust' 'floor',
		description [;
			if (self.number < 2) {
				score++;
				deadflag = 2;
				print "The message, neatly marked in the sawdust, reads...";
				}
			else {
				deadflag = 3;
				print "The message has been carelessly trampled, making it
				  difficult to read. You can just distinguish the words...";
				}
		],
		number  0,
  has   scenery;

[ Initialise;
#Ifdef USEINFORM; ! The location is set with INITIAL_LOCATION_VALUE in PunyInform
	location = foyer;
#Endif;
	move cloak to player;
	give cloak worn;
   "^^Hurrying through the rainswept November night, you're glad to see the
	bright lights of the Opera House. It's surprising that there aren't more
	people about but, hey, what do you expect in a cheap demo game...?^^";
];


! ============================================================================ !


#Ifdef USEINFORM;
Include "Grammar";
#Endif;

Verb 'hang'	 * held 'on' noun	-> PutOn;

! ============================================================================ !
```
