UNALTERED CODE:

1. The ready function initializes a "text label" object in Godot, which displays text on screen to the user. The "text label" node in our case isn't displaying static text, but dynamically generated text from our transcription script (more on that later).

2. The process function is what happens every tick during the program. We simply update our text.

3. The update_text function concatenates partial_text transcriptions to form a completed_text transcription. We can detect correct answers from the user from both the completed_text string and the partial_text string. The difference between partial and completed text is a function of time based on the underlying transcription script. Time intervals between user voice input dictates when a text is completed versus partial.

4. Most importantly, our function on_speech_to_text_transcribed_msg is a function that is ran when we emit the "on_speech_to_text_transcribed_msg" signal in in the underlying script. Godot uses signals to communicate between nodes/separate scripts. When the transcription script wants to output newly transcribed text, it emits the aforementioned signal while passing that output string through the emit() function. To capture that output, we can (from any node, in this case our RichTextLabel node) use the on_speech_to_text_transcribed_msg function to listen for such emissions.

When we get a new transmission, we simply store the emitted string in either partial text or completed text accordingly.

ALTERED CODE:

The altered code expands on the tutorial code by detecting correct answers seeing if our pre-determined answer variable is in our partial_text or completed_text strings from the transcription.

If it is, we set our boolean success variable to true and emit a "guess" signal which is listened for/captured by the main game logic loop.