Animal Scramble

Animal identification guessing game with speech recognition user interface through microphone input.

Three modes:
	1. Animal picture guessing
	2. Animal sound guessing
	3. Mixed mode guessing

Currently ran through the Godot 4.3 Mono Editor.

IMPLEMENTATION TIMELINE:

		Milestone 1:

   ∙ This iteration of the project was focused on setting up the screen navigation between the game's main menu and the round view, where prompts are delivered to the user.

   ∙ The documentation for the project was created to summarize useful github commands for the project, API keys for our plugins, and the source of assets used to create the project.

   ∙ Lastly, the project had the Godot Whisper plugin added to begin working on speech transcription.

		Milestone 2:

   ∙ In milestone 2, our project moved away from Godot Whisper plugin and instead used a C# script to transribe speech with the VOSK model with a focus on lightweight transcription for mobile processor compatibility.

   ∙ The basic game loop was designed and animal image prompts were delivered to the user and correct guesses were identified.

   ∙ From a visual design perspective, we implemented animations into the project such as a moving background. We added animal pictures to test visual prompts.

		Milestone 3:

   ∙ Focused on game loop design as app complexity was growing.

   ∙ Changes were made to the menu navigation such as the addition of a round countdown timer, basic audio effects were added for correct prompts, a timer during the round gives the player a finite amount of time to correctly guess the animal.

   ∙ During the round, a text-based guess system displays a hint to the user and if they guess correct or fail to guess correctly, the full prompt answer is displayed.

   ∙ A mode selection menu was created to separate visual prompt rounds from audio prompt rounds and finally the mixed round with both mediums. Animations were added to this menu when a mode is selected.

   ∙ A redesign of the app visual and audio themes. Animated the menu title.

		Milestone 4:

   ∙ Implemented the audio prompt mode and mixed mode.

   ∙ Added audio prompts, and many more visual prompts.

   ∙ Added a music mute button and a restart button.

   ∙ Made rounds have finite amount of prompts (10).

   ∙ Made a final score screen at the end of a round.

   ∙ Made the game loop back to the game selection menu after completing a round.
